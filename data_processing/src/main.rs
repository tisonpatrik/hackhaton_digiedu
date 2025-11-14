mod handlers;
mod models;
mod processors;

use actix_web::{App, HttpServer};
use utoipa::OpenApi;
use utoipa_swagger_ui::SwaggerUi;

use models::{
    UploadFileError, UploadFileRequest, UploadFileResponse,
    TranscribeRequest, TranscribeResponse, TranscribeError,
};

#[derive(OpenApi)]
#[openapi(
    paths(
        crate::handlers::health::health,
        crate::handlers::upload_file::upload_file,
        crate::handlers::transcribe::transcribe_audio
    ),
    components(schemas(
        UploadFileRequest,
        UploadFileResponse,
        UploadFileError,
        TranscribeRequest,
        TranscribeResponse,
        TranscribeError
    )),
    tags(
        (name = "Health", description = "Health check"),
        (name = "Files", description = "File operations"),
        (name = "Audio", description = "Audio transcription operations")
    )
)]
struct ApiDoc;

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    dotenv::dotenv().ok();
    env_logger::init_from_env(env_logger::Env::new().default_filter_or("info"));
    
    let host = std::env::var("HOST").unwrap_or_else(|_| "127.0.0.1".to_string());
    let port = std::env::var("PORT")
        .unwrap_or_else(|_| "8080".to_string())
        .parse::<u16>()
        .unwrap_or(8080);
    
    log::info!("Starting server on {}:{}", host, port);
    
    let openapi = ApiDoc::openapi();
    
    HttpServer::new(move || {
        App::new()
            .wrap(actix_web::middleware::Logger::default())
            .service(
                SwaggerUi::new("/docs/{_:.*}")
                    .url("/api-doc/openapi.json", openapi.clone())
            )
            .service(handlers::health::health)
            .service(handlers::upload_file::upload_file)
            .service(handlers::transcribe::transcribe_audio)
    })
    .bind((host.as_str(), port))?
    .run()
    .await
}