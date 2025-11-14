use sqlx::PgPool;
use futures_util::future::join_all;
use std::sync::Arc;
use tokio::sync::Semaphore;

use crate::injectors::db;
use crate::injectors::create_chunks_from_document;
use crate::gen_ai::{extract_qa_structured, create_embedding};
use crate::prompts::{extract_qa_system, extract_qa_user};
use crate::processors::tabular::TABULAR_RECORD_SEPARATOR;
use crate::labels::associate_labels_with_chunk;

pub async fn inject_document(
    pool: &PgPool,
    document_name: &str,
    text: &str,
) -> Result<(), String> {
    db::insert_or_update_document(pool, document_name, text).await?;
    
    // Create chunks first
    const TOKEN_SIZE: usize = 1500;
    const OVERLAP_TOKEN_SIZE: usize = 200;
    
    // Detect if text contains tabular record separator, use appropriate separator
    let separator = if text.contains(TABULAR_RECORD_SEPARATOR) {
        log::info!("Detected tabular data format, using record separator for chunking");
        TABULAR_RECORD_SEPARATOR
    } else {
        // Default separator for plain text
        "."
    };
    
    let chunks = create_chunks_from_document(text, separator, TOKEN_SIZE, OVERLAP_TOKEN_SIZE)?;
    let chunks_count = chunks.len();
    log::info!("Created {} chunks from document '{}'", chunks_count, document_name);
    
    let system_msg = extract_qa_system();
    let semaphore = Arc::new(Semaphore::new(5));
    
    let tasks: Vec<_> = chunks.iter().enumerate().map(|(index, chunk)| {
        let pool = pool.clone();
        let document_name = document_name.to_string();
        let chunk_text = chunk.text.clone();
        let user_msg = extract_qa_user(&chunk_text);
        let total_tokens = chunk.total_tokens;
        let permit = semaphore.clone();
        
        async move {
            let _permit = permit.acquire().await.unwrap();
            log::info!("Processing chunk {}/{} ({} tokens)", index + 1, chunks_count, total_tokens);
            
            let normalized = match extract_qa_structured(system_msg, &user_msg).await {
                Ok(normalized) => normalized,
                Err(e) => {
                    log::warn!("Failed to extract QA from chunk {}: {}", index + 1, e);
                    return;
                }
            };
            
            let content = match serde_json::to_string(&normalized) {
                Ok(c) => c,
                Err(e) => {
                    log::warn!("Failed to serialize normalized response for chunk {}: {}", index + 1, e);
                    return;
                }
            };
            
            let embedding = match create_embedding(&content).await {
                Ok(emb) => emb,
                Err(e) => {
                    log::warn!("Failed to create embedding for chunk {}: {}", index + 1, e);
                    return;
                }
            };
            
            let chunk_key = format!("{}:{}", document_name, index);
            
            if let Err(e) = db::insert_chunk(&pool, &document_name, index, &content, &embedding).await {
                log::warn!("Failed to insert chunk {} into database: {}", index + 1, e);
                return;
            }
            
            // Associate labels with chunk
            if !normalized.topic_labels.is_empty() {
                log::info!("Associating {} labels with chunk {}", normalized.topic_labels.len(), index + 1);
                match associate_labels_with_chunk(&pool, &chunk_key, &normalized.topic_labels, None).await {
                    Ok(labels) => {
                        log::info!("Successfully associated {} labels with chunk {}", labels.len(), index + 1);
                    }
                    Err(e) => {
                        log::warn!("Failed to associate labels with chunk {}: {}", index + 1, e);
                    }
                }
            }
        }
    }).collect();
    
    join_all(tasks).await;
    
    log::info!("Successfully processed {} chunks", chunks.len());
    
    Ok(())
}

