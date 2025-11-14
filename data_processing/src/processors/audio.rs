use std::path::{Path, PathBuf};
use std::fs;
use std::io::Write;
use std::process::Command;

/// Preprocess audio file for optimal Whisper transcription
/// - Converts to 16kHz mono Opus/OGG (highly compressed)
/// - Reduces file size by ~80-90% while maintaining speech quality
/// - Removes silences and normalizes audio
/// - Prevents hallucinations in long audio
fn preprocess_audio(input_path: &Path) -> Result<PathBuf, String> {
    let output_path = input_path.with_extension("processed.ogg");
    
    log::info!("Preprocessing audio: {:?} -> {:?}", input_path, output_path);
    
    // Use ffmpeg to convert audio to optimal format for Whisper:
    // - 16kHz sample rate (Whisper's native rate)
    // - Mono audio (reduces hallucinations)
    // - Opus codec in OGG container (highly compressed, Whisper-compatible)
    // - Remove silences (prevents hallucination triggers)
    // - Normalize audio levels
    let output = Command::new("ffmpeg")
        .args(&[
            "-i", input_path.to_str().unwrap(),
            "-ar", "16000",              // 16kHz sample rate
            "-ac", "1",                   // Mono
            "-c:a", "libopus",           // Opus codec (much smaller than WAV!)
            "-b:a", "24k",               // Low bitrate (speech optimized)
            // Remove ALL silences (not just first), then normalize
            "-af", "silenceremove=stop_periods=-1:stop_duration=1:stop_threshold=-50dB,loudnorm",
            "-y",                         // Overwrite output
            output_path.to_str().unwrap()
        ])
        .output()
        .map_err(|e| format!("Failed to run ffmpeg: {}", e))?;
    
    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        return Err(format!("ffmpeg failed: {}", stderr));
    }
    
    // Check if output file was created
    if !output_path.exists() {
        return Err("Processed audio file was not created".to_string());
    }
    
    let orig_size = fs::metadata(input_path)
        .map(|m| m.len())
        .unwrap_or(0);
    let new_size = fs::metadata(&output_path)
        .map(|m| m.len())
        .unwrap_or(0);
    
    log::info!("Audio preprocessed: {} bytes -> {} bytes ({:.1}% of original)", 
        orig_size, new_size, (new_size as f64 / orig_size as f64 * 100.0));
    
    Ok(output_path)
}

pub async fn transcribe_audio_file(audio_path: &Path) -> Result<String, String> {
    // Create directories
    let audio_dir = Path::new("./audio_files");
    let transcripts_dir = Path::new("./transcripts");
    
    fs::create_dir_all(audio_dir)
        .map_err(|e| format!("Failed to create audio directory: {}", e))?;
    
    fs::create_dir_all(transcripts_dir)
        .map_err(|e| format!("Failed to create transcripts directory: {}", e))?;
    
    // Get filename
    let filename = audio_path
        .file_name()
        .and_then(|n| n.to_str())
        .ok_or("Invalid filename")?;
    
    // Determine destination path
    let dest_audio_path = audio_dir.join(filename);
    
    // Only copy if the file is not already in the audio_files directory
    if audio_path != dest_audio_path {
        fs::copy(audio_path, &dest_audio_path)
            .map_err(|e| format!("Failed to copy audio file: {}", e))?;
    }
    
    // Get whisper URL
    let whisper_url = std::env::var("WHISPER_URL")
        .unwrap_or_else(|_| "http://localhost:8000".to_string());
    
    // Create client with longer timeout for transcription
    let client = reqwest::Client::builder()
        .timeout(std::time::Duration::from_secs(600)) // 10 minutes
        .build()
        .map_err(|e| format!("Failed to create HTTP client: {}", e))?;
    
    log::info!("Preprocessing audio file: {:?}", dest_audio_path);
    
    // Preprocess audio: convert to 16kHz mono Opus/OGG (optimal for Whisper)
    let processed_path = preprocess_audio(&dest_audio_path)
        .map_err(|e| format!("Failed to preprocess audio: {}", e))?;
    
    // Read processed audio file
    let audio_bytes = fs::read(&processed_path)
        .map_err(|e| format!("Failed to read processed audio file: {}", e))?;
    
    log::info!("Preprocessed audio: {} bytes (original: {:?})", audio_bytes.len(), dest_audio_path);
    
    // Use Opus/OGG format for Whisper (highly compressed, Whisper-compatible)
    let mime_type = "audio/ogg";
    let processed_filename = format!("{}_processed.ogg", 
        dest_audio_path.file_stem()
            .and_then(|s| s.to_str())
            .unwrap_or("audio")
    );

    log::info!("Using mime type: {} for processed file", mime_type);

    // Create multipart form with processed audio
    let file_part = reqwest::multipart::Part::bytes(audio_bytes)
        .file_name(processed_filename)
        .mime_str(mime_type)
        .map_err(|e| format!("Failed to set mime type: {}", e))?;
    
    // Add a guiding prompt to prevent repetition in Czech interviews
    let prompt = "Interview in Czech language. Questions about education program. Natural conversation without repetition.";
    
    let form = reqwest::multipart::Form::new()
        .part("file", file_part)
        .text("model", "medium")  // Medium model: better for Czech, prevents repetition loops
        .text("temperature", "0")  // Deterministic output
        .text("vad_filter", "true")  // Voice Activity Detection - skip silence/noise
        .text("prompt", prompt)  // Guide the model away from repetition
        .text("language", "cs");  // Explicitly set Czech language for better accuracy
    
    log::info!("Sending transcription request to: {}/v1/audio/transcriptions", whisper_url);
    
    // Send request to faster-whisper
    let response = client
        .post(format!("{}/v1/audio/transcriptions", whisper_url))
        .multipart(form)
        .send()
        .await
        .map_err(|e| format!("Failed to connect to faster-whisper: {}", e))?;
    
    if !response.status().is_success() {
        let status = response.status();
        let error_body = response.text().await.unwrap_or_else(|_| "Unknown error".to_string());
        return Err(format!("Transcription failed with status {}: {}", status, error_body));
    }
    
    // Parse response
    let response_json: serde_json::Value = response
        .json()
        .await
        .map_err(|e| format!("Failed to parse transcription response: {}", e))?;
    
    let transcript_text = response_json["text"]
        .as_str()
        .unwrap_or("")
        .to_string();
    
    // Save transcript
    let transcript_filename = format!(
        "{}.txt",
        audio_path
            .file_stem()
            .and_then(|s| s.to_str())
            .unwrap_or("transcript")
    );
    let transcript_path = transcripts_dir.join(&transcript_filename);
    
    let mut file = fs::File::create(&transcript_path)
        .map_err(|e| format!("Failed to create transcript file: {}", e))?;
    
    file.write_all(transcript_text.as_bytes())
        .map_err(|e| format!("Failed to write transcript: {}", e))?;
    
    Ok(transcript_path.to_string_lossy().to_string())
}

