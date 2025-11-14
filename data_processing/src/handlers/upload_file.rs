use actix_web::{post, web, HttpResponse, Responder};
use std::path::Path;

use crate::models::{
    UploadFileError, UploadFileRequest, UploadFileResponse,
};
use crate::processors::audio::transcribe_audio_file;
use crate::processors::text::parse_text_file;
use crate::processors::tabular::parse_tabular_file;

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
    
    // Detect file type by extension
    let file_type = file_path
        .extension()
        .and_then(|ext| ext.to_str())
        .map(|ext| ext.to_lowercase())
        .unwrap_or_default();
    
    let is_audio = matches!(
        file_type.as_str(),
        "mp3" | "wav" | "ogg" | "flac" | "m4a" | "aac" | "wma" | "opus"
    );
    
    let is_text = matches!(
        file_type.as_str(),
        "txt" | "md" | "log" | "doc" | "docx"
    );
    
    let is_tabular = matches!(
        file_type.as_str(),
        "csv" | "xlsx" | "xls" | "tsv" | "ods" | "json" | "yml" | "yaml"
    );
    
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
    } else if is_text {
        // Parse text file
        match parse_text_file(file_path).await {
            Ok(result_path) => {
                HttpResponse::Ok().json(UploadFileResponse {
                    status: "ok".to_string(),
                    file_type: "text".to_string(),
                    transcript_path: Some(result_path),
                })
            }
            Err(error_msg) => {
                HttpResponse::InternalServerError().json(UploadFileError {
                    error: error_msg,
                })
            }
        }
    } else if is_tabular {
        // Parse tabular file
        match parse_tabular_file(file_path).await {
            Ok(result_path) => {
                HttpResponse::Ok().json(UploadFileResponse {
                    status: "ok".to_string(),
                    file_type: "tabular".to_string(),
                    transcript_path: Some(result_path),
                })
            }
            Err(error_msg) => {
                HttpResponse::InternalServerError().json(UploadFileError {
                    error: error_msg,
                })
            }
        }
    } else {
        // Unknown file type, just confirm it exists
        HttpResponse::Ok().json(UploadFileResponse {
            status: "ok".to_string(),
            file_type: "other".to_string(),
            transcript_path: None,
        })
    }
}

