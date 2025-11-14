use actix_web::{post, web, HttpResponse, Responder};
use sqlx::PgPool;
use serde::{Deserialize, Serialize};

use crate::models::{FileUploadError, ChunkWithLabelsResponse, LabelResponse};
use crate::labels::{get_all_labels, search_chunks_by_labels};
use crate::gen_ai::extract_qa_structured;

#[derive(Serialize, Deserialize)]
pub struct QueryRequest {
    /// User's question/query
    pub question: String,
}

#[derive(Serialize, Deserialize)]
pub struct QueryResponse {
    /// The answer to the user's question
    pub answer: String,
    /// Labels that were selected as relevant
    pub selected_labels: Vec<LabelResponse>,
    /// Chunks that were searched (with their labels)
    pub searched_chunks: Vec<ChunkWithLabelsResponse>,
}

#[post("/query")]
pub async fn query_with_labels(
    pool: web::Data<PgPool>,
    request: web::Json<QueryRequest>,
) -> impl Responder {
    log::info!("Received query: {}", request.question);
    
    // Step 1: Get all available labels
    let all_labels = match get_all_labels(pool.get_ref()).await {
        Ok(labels) => labels,
        Err(e) => {
            log::error!("Failed to fetch labels: {}", e);
            return HttpResponse::InternalServerError().json(FileUploadError {
                error: format!("Failed to fetch labels: {}", e),
            });
        }
    };
    
    if all_labels.is_empty() {
        return HttpResponse::Ok().json(QueryResponse {
            answer: "No data has been uploaded yet. Please upload some files first.".to_string(),
            selected_labels: vec![],
            searched_chunks: vec![],
        });
    }
    
    log::info!("Found {} available labels", all_labels.len());
    
    // Step 2: Use AI to select relevant labels based on the question
    let selected_label_ids = match select_relevant_labels(&request.question, &all_labels).await {
        Ok(ids) => ids,
        Err(e) => {
            log::error!("Failed to select labels: {}", e);
            return HttpResponse::InternalServerError().json(FileUploadError {
                error: format!("Failed to select relevant labels: {}", e),
            });
        }
    };
    
    log::info!("Selected {} relevant labels for query", selected_label_ids.len());
    
    if selected_label_ids.is_empty() {
        return HttpResponse::Ok().json(QueryResponse {
            answer: "I couldn't find any relevant data for your question. Try rephrasing or uploading more content.".to_string(),
            selected_labels: vec![],
            searched_chunks: vec![],
        });
    }
    
    // Step 3: Search only chunks with selected labels
    let chunks = match search_chunks_by_labels(pool.get_ref(), &selected_label_ids).await {
        Ok(chunks) => chunks,
        Err(e) => {
            log::error!("Failed to search chunks: {}", e);
            return HttpResponse::InternalServerError().json(FileUploadError {
                error: format!("Failed to search chunks: {}", e),
            });
        }
    };
    
    log::info!("Found {} chunks with selected labels", chunks.len());
    
    if chunks.is_empty() {
        return HttpResponse::Ok().json(QueryResponse {
            answer: "No relevant content found for the selected topics.".to_string(),
            selected_labels: all_labels
                .iter()
                .filter(|l| selected_label_ids.contains(&l.id))
                .map(|l| LabelResponse {
                    id: l.id,
                    name: l.name.clone(),
                    normalized_name: l.normalized_name.clone(),
                    category: l.category.clone(),
                    usage_count: l.usage_count,
                })
                .collect(),
            searched_chunks: vec![],
        });
    }
    
    // Step 4: Generate answer using the filtered chunks
    let answer = match generate_answer(&request.question, &chunks).await {
        Ok(answer) => answer,
        Err(e) => {
            log::error!("Failed to generate answer: {}", e);
            return HttpResponse::InternalServerError().json(FileUploadError {
                error: format!("Failed to generate answer: {}", e),
            });
        }
    };
    
    // Convert chunks to response format
    let searched_chunks: Vec<ChunkWithLabelsResponse> = chunks
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
    
    HttpResponse::Ok().json(QueryResponse {
        answer,
        selected_labels: all_labels
            .iter()
            .filter(|l| selected_label_ids.contains(&l.id))
            .map(|l| LabelResponse {
                id: l.id,
                name: l.name.clone(),
                normalized_name: l.normalized_name.clone(),
                category: l.category.clone(),
                usage_count: l.usage_count,
            })
            .collect(),
        searched_chunks,
    })
}

/// Use AI to select relevant labels based on the user's question
async fn select_relevant_labels(
    question: &str,
    available_labels: &[crate::labels::LabelInfo],
) -> Result<Vec<i32>, String> {
    let labels_list: Vec<String> = available_labels
        .iter()
        .map(|l| format!("{} ({})", l.name, l.id))
        .collect();
    
    let system_prompt = r#"You are a label selection assistant. Given a user's question and a list of available labels, select the most relevant labels that would help answer the question.

Return ONLY a JSON array of label IDs (numbers), like: [1, 3, 5]

Rules:
- Select 1-5 most relevant labels
- If the question is broad, select more labels
- If the question is specific, select fewer labels
- Return an empty array [] if no labels are relevant"#;
    
    let user_prompt = format!(
        "Question: {}\n\nAvailable labels:\n{}\n\nSelect relevant label IDs:",
        question,
        labels_list.join("\n")
    );
    
    // Use Mistral to select labels
    let response = match extract_qa_structured(system_prompt, &user_prompt).await {
        Ok(resp) => resp,
        Err(e) => return Err(format!("AI selection failed: {}", e)),
    };
    
    // Try to parse the raw_input as JSON array of IDs
    // The AI might return it in the raw_input or we can extract from topic_labels
    let selected_ids: Vec<i32> = if !response.topic_labels.is_empty() {
        // If AI put selections in topic_labels, try to match them
        response.topic_labels
            .iter()
            .filter_map(|label_name| {
                available_labels
                    .iter()
                    .find(|l| l.name.to_lowercase() == label_name.to_lowercase() 
                           || l.normalized_name == label_name.to_lowercase())
                    .map(|l| l.id)
            })
            .collect()
    } else {
        // Try simple heuristic: select labels whose names appear in the question
        let question_lower = question.to_lowercase();
        available_labels
            .iter()
            .filter(|l| {
                question_lower.contains(&l.name.to_lowercase()) ||
                question_lower.contains(&l.normalized_name)
            })
            .take(3)
            .map(|l| l.id)
            .collect()
    };
    
    Ok(selected_ids)
}

/// Generate an answer using the filtered chunks
async fn generate_answer(
    question: &str,
    chunks: &[crate::labels::ChunkWithLabels],
) -> Result<String, String> {
    // Combine chunk contents for context
    let context: Vec<String> = chunks
        .iter()
        .map(|chunk| {
            // Parse the chunk content (it's JSON with Q&A)
            if let Ok(parsed) = serde_json::from_str::<crate::models::NormalizedResponse>(&chunk.content) {
                // Extract meaningful content from Q&A pairs
                parsed.qa
                    .iter()
                    .map(|qa| format!("Q: {}\nA: {}", qa.question_text, qa.answer))
                    .collect::<Vec<_>>()
                    .join("\n")
            } else {
                chunk.content.clone()
            }
        })
        .collect();
    
    let system_prompt = r#"You are a helpful educational assistant. Answer the user's question based ONLY on the provided context.

Rules:
- Be concise and direct
- If the context doesn't contain enough information, say so
- Don't make up information
- Cite specific details from the context when possible"#;
    
    let user_prompt = format!(
        "Context:\n{}\n\nQuestion: {}\n\nAnswer:",
        context.join("\n\n---\n\n"),
        question
    );
    
    let response = extract_qa_structured(system_prompt, &user_prompt).await?;
    
    // Extract answer from the AI response
    if !response.qa.is_empty() {
        Ok(response.qa[0].answer.clone())
    } else {
        Ok(response.raw_input.clone())
    }
}
