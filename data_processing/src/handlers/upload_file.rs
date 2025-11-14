use actix_web::{post, web, HttpResponse, Responder};
use sqlx::PgPool;
use std::path::Path;

use crate::models::{
    UploadFileError, UploadFileRequest, UploadFileResponse,
};
use crate::processors::audio::transcribe_audio_file;
use crate::processors::text::parse_text_file;
use crate::processors::tabular::parse_tabular_file;
use crate::injectors::inject_document;
use crate::file_types::{is_audio_extension, is_text_extension, is_tabular_extension};

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
pub async fn upload_file(
    req: web::Json<UploadFileRequest>,
    pool: web::Data<PgPool>,
) -> impl Responder {
    let file_path = Path::new(&req.path);
    
    if !file_path.exists() {
        return HttpResponse::NotFound().json(UploadFileError {
            error: "File not found".to_string(),
        });
    }
    
    let extension = file_path
        .extension()
        .and_then(|ext| ext.to_str())
        .map(|ext| ext.to_lowercase())
        .unwrap_or_default();
    
    let is_audio = is_audio_extension(&extension);
    let is_text = is_text_extension(&extension);
    let is_tabular = is_tabular_extension(&extension);
    
    let plain_text = if is_audio {
        match transcribe_audio_file(file_path).await {
            Ok(text) => text,
            Err(error_msg) => {
                return HttpResponse::InternalServerError().json(UploadFileError {
                    error: error_msg,
                });
            }
        }
    } else if is_text {
        match parse_text_file(file_path).await {
            Ok(text) => text,
            Err(error_msg) => {
                return HttpResponse::InternalServerError().json(UploadFileError {
                    error: error_msg,
                });
            }
        }
    } else if is_tabular {
        match parse_tabular_file(file_path).await {
            Ok(text) => text,
            Err(error_msg) => {
                return HttpResponse::InternalServerError().json(UploadFileError {
                    error: error_msg,
                });
            }
        }
    } else {
        return HttpResponse::Ok().json(UploadFileResponse {
            status: "ok".to_string(),
            file_type: "other".to_string(),
            transcript_path: None,
        });
    };
    
    let document_name = file_path
        .file_name()
        .and_then(|n| n.to_str())
        .unwrap_or("unknown");
    
    match inject_document(pool.get_ref(), document_name, &plain_text).await {
        Ok(_) => {
            HttpResponse::Ok().json(UploadFileResponse {
                status: "ok".to_string(),
                file_type: if is_audio { "audio" } else if is_text { "text" } else { "tabular" }.to_string(),
                transcript_path: None,
            })
        }
        Err(error_msg) => {
            HttpResponse::InternalServerError().json(UploadFileError {
                error: error_msg,
            })
        }
    }
}

