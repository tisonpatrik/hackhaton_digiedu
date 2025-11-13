mod handlers;
mod models;

use actix_web::{get, post, web, App, HttpResponse, HttpServer, Responder};
use utoipa::OpenApi;
use utoipa_swagger_ui::SwaggerUi;

use models::{
    UploadFileError, UploadFileRequest, UploadFileResponse,
    TranscribeRequest, TranscribeResponse, TranscribeError,
};

#[get("/")]
async fn hello() -> impl Responder {
    HttpResponse::Ok().body("Hello world!")
}

#[post("/echo")]
async fn echo(req_body: String) -> impl Responder {
    HttpResponse::Ok().body(req_body)
}

async fn manual_hello() -> impl Responder {
    HttpResponse::Ok().body("Hey there!")
}

#[derive(OpenApi)]
#[openapi(
    paths(
        crate::handlers::upload_file,
        crate::handlers::transcribe_audio
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
    
    HttpServer::new(|| {
        App::new()
            .wrap(actix_web::middleware::Logger::default())
            .service(
                SwaggerUi::new("/docs/{_:.*}")
                    .url("/api-doc/openapi.json", ApiDoc::openapi())
            )
            .service(hello)
            .service(echo)
            .service(handlers::upload_file)
            .service(handlers::transcribe_audio)
            .route("/hey", web::get().to(manual_hello))
    })
    .bind((host.as_str(), port))?
    .run()
    .await
}