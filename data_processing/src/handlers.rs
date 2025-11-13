use actix_web::{post, web, HttpResponse, Responder};
use std::path::Path;

use crate::models::{UploadFileError, UploadFileRequest, UploadFileResponse};

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

