use actix_web::{post, web, HttpResponse, Responder};
use std::path::Path;

use crate::models::{
    UploadFileError, UploadFileRequest, UploadFileResponse,
};
use crate::processors::audio::transcribe_audio_file;

#[utoipa::path(
    post,
    path = "/upload-file",
    request_body = UploadFileRequest,
    responses(
        (status = 200, description = "File processed", body = UploadFileResponse),
        (status = 404, description = "File not found", body = UploadFileError),
        (status = 500, description = "Processing failed", body = UploadFileError)
    ),
    tag = "Files"
)]
#[post("/upload-file")]
pub async fn upload_file(req: web::Json<UploadFileRequest>) -> impl Responder {
    let file_path = Path::new(&req.path);
    
    // Check if file exists
    if !file_path.exists() {
        return HttpResponse::NotFound().json(UploadFileError {
            error: "File not found".to_string(),
        });
    }
    
    // Detect if it's an audio file
    let is_audio = file_path
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
        // Transcribe audio file
        match transcribe_audio_file(file_path).await {
            Ok(transcript_path) => {
                HttpResponse::Ok().json(UploadFileResponse {
                    status: "ok".to_string(),
                    file_type: "audio".to_string(),
                    transcript_path: Some(transcript_path),
                })
            }
            Err(error_msg) => {
                HttpResponse::InternalServerError().json(UploadFileError {
                    error: error_msg,
                })
            }
        }
    } else {
        // Non-audio file, just confirm it exists
        HttpResponse::Ok().json(UploadFileResponse {
            status: "ok".to_string(),
            file_type: "other".to_string(),
            transcript_path: None,
        })
    }
}

