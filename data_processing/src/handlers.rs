use actix_web::{post, web, HttpResponse, Responder};
use std::path::Path;
use std::fs;
use std::io::Write;

use crate::models::{
    UploadFileError, UploadFileRequest, UploadFileResponse,
    TranscribeRequest, TranscribeResponse, TranscribeError,
};

#[utoipa::path(
    post,
    path = "/upload-file",
    request_body = UploadFileRequest,
    responses(
        (status = 200, description = "File exists", body = UploadFileResponse),
        (status = 404, description = "File not found", body = UploadFileError)
    ),
    tag = "Files"
)]
#[post("/upload-file")]
pub async fn upload_file(req: web::Json<UploadFileRequest>) -> impl Responder {
    let file_path = Path::new(&req.path);
    
    if file_path.exists() {
        HttpResponse::Ok().json(UploadFileResponse {
            status: "ok".to_string(),
        })
    } else {
        HttpResponse::NotFound().json(UploadFileError {
            error: "File not found".to_string(),
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use actix_web::{test, web, App};
    use std::fs::File;
    use std::io::Write;
    use tempfile::TempDir;

    #[actix_rt::test]
    async fn test_upload_file_exists() {
        let temp_dir = TempDir::new().unwrap();
        let test_file = temp_dir.path().join("test_file.txt");
        let mut file = File::create(&test_file).unwrap();
        file.write_all(b"test content").unwrap();
        drop(file);

        let app = test::init_service(
            App::new().service(web::scope("").service(upload_file))
        ).await;

        let req = test::TestRequest::post()
            .uri("/upload-file")
            .set_json(&UploadFileRequest {
                path: test_file.to_string_lossy().to_string(),
            })
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert!(resp.status().is_success());

        let body: UploadFileResponse = test::read_body_json(resp).await;
        assert_eq!(body.status, "ok");
    }

    #[actix_rt::test]
    async fn test_upload_file_not_exists() {
        let app = test::init_service(
            App::new().service(web::scope("").service(upload_file))
        ).await;

        let req = test::TestRequest::post()
            .uri("/upload-file")
            .set_json(&UploadFileRequest {
                path: "/nonexistent/file/path.txt".to_string(),
            })
            .to_request();

        let resp = test::call_service(&app, req).await;
        assert_eq!(resp.status().as_u16(), 404);

        let body: UploadFileError = test::read_body_json(resp).await;
        assert_eq!(body.error, "File not found");
    }
}

#[utoipa::path(
    post,
    path = "/transcribe",
    request_body = TranscribeRequest,
    responses(
        (status = 200, description = "Transcription successful", body = TranscribeResponse),
        (status = 404, description = "Audio file not found", body = TranscribeError),
        (status = 500, description = "Transcription failed", body = TranscribeError)
    ),
    tag = "Audio"
)]
#[post("/transcribe")]
pub async fn transcribe_audio(req: web::Json<TranscribeRequest>) -> impl Responder {
    let audio_path = Path::new(&req.audio_path);
    
    // Check if audio file exists
    if !audio_path.exists() {
        return HttpResponse::NotFound().json(TranscribeError {
            error: format!("Audio file not found: {}", req.audio_path),
        });
    }
    
    // Create audio_files and transcripts directories if they don't exist
    let audio_dir = Path::new("./audio_files");
    let transcripts_dir = Path::new("./transcripts");
    
    if let Err(e) = fs::create_dir_all(audio_dir) {
        return HttpResponse::InternalServerError().json(TranscribeError {
            error: format!("Failed to create audio directory: {}", e),
        });
    }
    
    if let Err(e) = fs::create_dir_all(transcripts_dir) {
        return HttpResponse::InternalServerError().json(TranscribeError {
            error: format!("Failed to create transcripts directory: {}", e),
        });
    }
    
    // Get filename from path
    let filename = audio_path.file_name()
        .and_then(|n| n.to_str())
        .unwrap_or("audio");
    
    // Copy audio file to shared volume
    let dest_audio_path = audio_dir.join(filename);
    if let Err(e) = fs::copy(audio_path, &dest_audio_path) {
        return HttpResponse::InternalServerError().json(TranscribeError {
            error: format!("Failed to copy audio file: {}", e),
        });
    }
    
    // Call faster-whisper API
    let whisper_url = std::env::var("WHISPER_URL")
        .unwrap_or_else(|_| "http://localhost:8000".to_string());
    
    let client = reqwest::Client::new();
    
    // Read the audio file
    let audio_bytes = match fs::read(&dest_audio_path) {
        Ok(bytes) => bytes,
        Err(e) => {
            return HttpResponse::InternalServerError().json(TranscribeError {
                error: format!("Failed to read audio file: {}", e),
            });
        }
    };
    
    // Create multipart form (OpenAI-compatible API format)
    let form = reqwest::multipart::Form::new()
        .part(
            "file",
            reqwest::multipart::Part::bytes(audio_bytes)
                .file_name(filename.to_string())
                .mime_str("audio/ogg")
                .unwrap_or_else(|_| reqwest::multipart::Part::bytes(vec![]))
        )
        .text("model", "base");
    
    // Send request to faster-whisper (OpenAI-compatible endpoint)
    let response = match client
        .post(format!("{}/v1/audio/transcriptions", whisper_url))
        .multipart(form)
        .send()
        .await
    {
        Ok(resp) => resp,
        Err(e) => {
            return HttpResponse::InternalServerError().json(TranscribeError {
                error: format!("Failed to connect to faster-whisper service: {}", e),
            });
        }
    };
    
    if !response.status().is_success() {
        let status = response.status();
        let error_body = response.text().await.unwrap_or_else(|_| "Unknown error".to_string());
        return HttpResponse::InternalServerError().json(TranscribeError {
            error: format!("Transcription failed with status {}: {}", status, error_body),
        });
    }
    
    // Parse JSON response to extract transcript text
    let response_json: serde_json::Value = match response.json().await {
        Ok(json) => json,
        Err(e) => {
            return HttpResponse::InternalServerError().json(TranscribeError {
                error: format!("Failed to parse transcription response: {}", e),
            });
        }
    };
    
    let transcript_text = response_json["text"]
        .as_str()
        .unwrap_or("")
        .to_string();
    
    // Save transcript to file
    let transcript_filename = format!("{}.txt", 
        audio_path.file_stem()
            .and_then(|s| s.to_str())
            .unwrap_or("transcript")
    );
    let transcript_path = transcripts_dir.join(&transcript_filename);
    
    let mut file = match fs::File::create(&transcript_path) {
        Ok(f) => f,
        Err(e) => {
            return HttpResponse::InternalServerError().json(TranscribeError {
                error: format!("Failed to create transcript file: {}", e),
            });
        }
    };
    
    if let Err(e) = file.write_all(transcript_text.as_bytes()) {
        return HttpResponse::InternalServerError().json(TranscribeError {
            error: format!("Failed to write transcript: {}", e),
        });
    }
    
    HttpResponse::Ok().json(TranscribeResponse {
        status: "ok".to_string(),
        transcript_path: transcript_path.to_string_lossy().to_string(),
    })
}

