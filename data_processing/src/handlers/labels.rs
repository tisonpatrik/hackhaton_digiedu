use actix_web::{get, post, web, HttpResponse, Responder};
use sqlx::PgPool;

use crate::models::{
    LabelsListResponse, 
    LabelResponse, 
    SearchByLabelsRequest, 
    SearchByLabelsResponse,
    ChunkWithLabelsResponse,
    FileUploadError
};
use crate::labels::{get_all_labels, search_chunks_by_labels};

#[utoipa::path(
    get,
    path = "/labels",
    responses(
        (status = 200, description = "List of all labels", body = LabelsListResponse),
        (status = 500, description = "Failed to fetch labels", body = FileUploadError)
    ),
    tag = "Labels"
)]
#[get("/labels")]
pub async fn get_labels(pool: web::Data<PgPool>) -> impl Responder {
    match get_all_labels(pool.get_ref()).await {
        Ok(labels) => {
            let response_labels: Vec<LabelResponse> = labels
                .into_iter()
                .map(|label| LabelResponse {
                    id: label.id,
                    name: label.name,
                    normalized_name: label.normalized_name,
                    category: label.category,
                    usage_count: label.usage_count,
                })
                .collect();
            
            HttpResponse::Ok().json(LabelsListResponse {
                labels: response_labels,
            })
        }
        Err(error_msg) => {
            log::error!("Failed to fetch labels: {}", error_msg);
            HttpResponse::InternalServerError().json(FileUploadError {
                error: error_msg,
            })
        }
    }
}

#[utoipa::path(
    post,
    path = "/search/by-labels",
    request_body = SearchByLabelsRequest,
    responses(
        (status = 200, description = "Chunks matching the labels", body = SearchByLabelsResponse),
        (status = 500, description = "Failed to search", body = FileUploadError)
    ),
    tag = "Labels"
)]
#[post("/search/by-labels")]
pub async fn search_by_labels(
    pool: web::Data<PgPool>,
    request: web::Json<SearchByLabelsRequest>,
) -> impl Responder {
    match search_chunks_by_labels(pool.get_ref(), &request.label_ids).await {
        Ok(chunks) => {
            let response_chunks: Vec<ChunkWithLabelsResponse> = chunks
                .into_iter()
                .map(|chunk| ChunkWithLabelsResponse {
                    document_name: chunk.document_name,
                    content: chunk.content,
                    labels: chunk.labels
                        .into_iter()
                        .map(|label| LabelResponse {
                            id: label.id,
                            name: label.name,
                            normalized_name: label.normalized_name,
                            category: label.category,
                            usage_count: label.usage_count,
                        })
                        .collect(),
                })
                .collect();
            
            HttpResponse::Ok().json(SearchByLabelsResponse {
                chunks: response_chunks,
            })
        }
        Err(error_msg) => {
            log::error!("Failed to search by labels: {}", error_msg);
            HttpResponse::InternalServerError().json(FileUploadError {
                error: error_msg,
            })
        }
    }
}
