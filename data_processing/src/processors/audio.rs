use std::path::Path;
use std::fs;
use std::io::Write;

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
    
    // Copy audio file
    let dest_audio_path = audio_dir.join(filename);
    fs::copy(audio_path, &dest_audio_path)
        .map_err(|e| format!("Failed to copy audio file: {}", e))?;
    
    // Get whisper URL
    let whisper_url = std::env::var("WHISPER_URL")
        .unwrap_or_else(|_| "http://localhost:8000".to_string());
    
    let client = reqwest::Client::new();
    
    // Read audio file
    let audio_bytes = fs::read(&dest_audio_path)
        .map_err(|e| format!("Failed to read audio file: {}", e))?;
    
    // Create multipart form
    let form = reqwest::multipart::Form::new()
        .part(
            "file",
            reqwest::multipart::Part::bytes(audio_bytes)
                .file_name(filename.to_string())
                .mime_str("audio/ogg")
                .unwrap_or_else(|_| reqwest::multipart::Part::bytes(vec![]))
        )
        .text("model", "base");
    
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

