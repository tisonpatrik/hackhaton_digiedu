mod handlers;
mod models;
mod processors;
mod injectors;
mod file_types;
mod gen_ai;
mod prompts;

use actix_web::{App, HttpServer, web};
use sqlx::postgres::PgPoolOptions;
use utoipa::OpenApi;
use utoipa_swagger_ui::SwaggerUi;

use models::{
    UploadFileError, UploadFileRequest, UploadFileResponse,
    TranscribeRequest, TranscribeResponse, TranscribeError,
    FileUploadResponse, FileUploadError,
};

#[derive(OpenApi)]
#[openapi(
    paths(
        crate::handlers::health::health,
        crate::handlers::upload_file::upload_file,
        crate::handlers::transcribe::transcribe_audio,
        crate::handlers::upload_multipart::upload_multipart_file
    ),
    components(schemas(
        UploadFileRequest,
        UploadFileResponse,
        UploadFileError,
        TranscribeRequest,
        TranscribeResponse,
        TranscribeError,
        FileUploadResponse,
        FileUploadError
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
    
    let database_url = std::env::var("DATABASE_URL")
        .unwrap_or_else(|_| "postgres://postgres:postgres@localhost:5432/live_dashboard_dev".to_string());
    
    let pool = PgPoolOptions::new()
        .max_connections(5)
        .connect(&database_url)
        .await
        .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, format!("Failed to connect to database: {}", e)))?;
    
    log::info!("Connected to database");
    
    let openapi = ApiDoc::openapi();
    
    HttpServer::new(move || {
        App::new()
            .app_data(web::Data::new(pool.clone()))
            .wrap(actix_web::middleware::Logger::default())
            .wrap(
                actix_cors::Cors::default()
                    .allow_any_origin()
                    .allow_any_method()
                    .allow_any_header()
                    .max_age(3600)
            )
            .app_data(web::PayloadConfig::new(500 * 1024 * 1024)) // 500MB max payload
            .service(
                SwaggerUi::new("/docs/{_:.*}")
                    .url("/api-doc/openapi.json", openapi.clone())
            )
            .service(handlers::health::health)
            .service(handlers::upload_file::upload_file)
            .service(handlers::transcribe::transcribe_audio)
            .service(handlers::upload_multipart::upload_multipart_file)
    })
    .keep_alive(std::time::Duration::from_secs(600)) // 10 min keep-alive
    .client_request_timeout(std::time::Duration::from_secs(600)) // 10 min timeout
    .bind((host.as_str(), port))?
    .run()
    .await
}
