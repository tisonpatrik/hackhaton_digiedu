use actix_web::{post, web, HttpResponse, Responder};
use actix_multipart::Multipart;
use futures_util::StreamExt;
use std::path::Path;
use std::fs;

use crate::models::{FileUploadResponse, FileUploadError};
use crate::processors::audio::transcribe_audio_file;

#[utoipa::path(
    post,
    path = "/upload",
    request_body(content = String, description = "Multipart file upload", content_type = "multipart/form-data"),
    responses(
        (status = 200, description = "File uploaded successfully", body = FileUploadResponse),
        (status = 500, description = "Upload failed", body = FileUploadError)
    ),
    tag = "Files"
)]
#[post("/upload")]
pub async fn upload_multipart_file(mut payload: Multipart) -> impl Responder {
    // Create directories
    let audio_dir = Path::new("./audio_files");
    let upload_dir = Path::new("./uploads");
    let transcripts_dir = Path::new("./transcripts");
    
    if let Err(e) = fs::create_dir_all(audio_dir) {
        return HttpResponse::InternalServerError().json(FileUploadError {
            error: format!("Failed to create audio directory: {}", e),
        });
    }
    
    if let Err(e) = fs::create_dir_all(upload_dir) {
        return HttpResponse::InternalServerError().json(FileUploadError {
            error: format!("Failed to create upload directory: {}", e),
        });
    }
    
    if let Err(e) = fs::create_dir_all(transcripts_dir) {
        return HttpResponse::InternalServerError().json(FileUploadError {
            error: format!("Failed to create transcripts directory: {}", e),
        });
    }
    
    let mut filename = String::new();
    let mut saved_path = std::path::PathBuf::new();
    
    // Process multipart stream
    while let Some(item) = payload.next().await {
        let mut field = match item {
            Ok(field) => field,
            Err(e) => {
                return HttpResponse::InternalServerError().json(FileUploadError {
                    error: format!("Failed to read field: {}", e),
                });
            }
        };
        
        // Get content disposition to extract filename
        let content_disposition = field.content_disposition();
        filename = content_disposition
            .as_ref()
            .and_then(|cd| cd.get_filename())
            .unwrap_or("uploaded_file")
            .to_string();
        
        // Determine if it's audio
        let is_audio = Path::new(&filename)
            .extension()
            .and_then(|ext| ext.to_str())
            .map(|ext| {
                matches!(
                    ext.to_lowercase().as_str(),
                    "mp3" | "wav" | "ogg" | "flac" | "m4a" | "aac" | "wma" | "opus"
                )
            })
            .unwrap_or(false);
        
        // Save to appropriate directory
        let target_dir = if is_audio { audio_dir } else { upload_dir };
        saved_path = target_dir.join(&filename);
        
        // Read and save file
        let mut file_data = Vec::new();
        while let Some(chunk) = field.next().await {
            let data = match chunk {
                Ok(data) => data,
                Err(e) => {
                    return HttpResponse::InternalServerError().json(FileUploadError {
                        error: format!("Failed to read chunk: {}", e),
                    });
                }
            };
            log::info!("Received chunk of {} bytes", data.len());
            file_data.extend_from_slice(&data);
        }
        
        log::info!("Total file size: {} bytes, saving to: {:?}", file_data.len(), saved_path);
        
        if let Err(e) = fs::write(&saved_path, &file_data) {
            return HttpResponse::InternalServerError().json(FileUploadError {
                error: format!("Failed to save file: {}", e),
            });
        }
    }
    
    if filename.is_empty() {
        return HttpResponse::BadRequest().json(FileUploadError {
            error: "No file uploaded".to_string(),
        });
    }
    
    // Check if it's an audio file and transcribe
    let is_audio = saved_path
        .extension()
        .and_then(|ext| ext.to_str())
        .map(|ext| {
            matches!(
                ext.to_lowercase().as_str(),
                "mp3" | "wav" | "ogg" | "flac" | "m4a" | "aac" | "wma" | "opus"
            )
        })
        .unwrap_or(false);
    
    if is_audio {
        // Transcribe the audio file
        match transcribe_audio_file(&saved_path).await {
            Ok(transcript_path) => {
                // Read transcript text
                let transcript_text = fs::read_to_string(&transcript_path)
                    .unwrap_or_else(|_| String::new());
                
                HttpResponse::Ok().json(FileUploadResponse {
                    status: "ok".to_string(),
                    file_type: "audio".to_string(),
                    filename,
                    file_path: saved_path.to_string_lossy().to_string(),
                    transcript_text: Some(transcript_text),
                    transcript_path: Some(transcript_path),
                })
            }
            Err(error_msg) => {
                HttpResponse::InternalServerError().json(FileUploadError {
                    error: format!("File saved but transcription failed: {}", error_msg),
                })
            }
        }
    } else {
        HttpResponse::Ok().json(FileUploadResponse {
            status: "ok".to_string(),
            file_type: "other".to_string(),
            filename,
            file_path: saved_path.to_string_lossy().to_string(),
            transcript_text: None,
            transcript_path: None,
        })
    }
}
