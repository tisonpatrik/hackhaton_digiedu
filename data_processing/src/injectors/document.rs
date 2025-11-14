use sqlx::PgPool;

use crate::injectors::db;
use crate::injectors::create_chunks_from_document;
use crate::gen_ai::extract_qa_structured;
use crate::prompts::{extract_qa_system, extract_qa_user};
use crate::processors::tabular::TABULAR_RECORD_SEPARATOR;

pub async fn inject_document(
    pool: &PgPool,
    document_name: &str,
    text: &str,
) -> Result<(), String> {
    let bpe = tiktoken_rs::cl100k_base()
        .map_err(|e| format!("Failed to initialize tokenizer: {}", e))?;
    
    let tokens = bpe.encode_with_special_tokens(text);
    let token_count = tokens.len();
    
    log::info!("Document token count: {}", token_count);
    
    db::insert_or_update_document(pool, document_name, text).await?;
    
    // Create chunks first
    const TOKEN_SIZE: usize = 1000;
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
    log::info!("Created {} chunks from document '{}'", chunks.len(), document_name);
    
    let system_msg = extract_qa_system();
    
    for (index, chunk) in chunks.iter().enumerate() {
        log::info!("Processing chunk {}/{} ({} tokens)", index + 1, chunks.len(), chunk.total_tokens);
        
        let user_msg = extract_qa_user(&chunk.text);
        
        match extract_qa_structured(system_msg, &user_msg).await {
            Ok(normalized) => {
                println!("\n=== Chunk {} - Normalized Response ===", index + 1);
                println!("Timestamp: {:?}", normalized.timestamp);
                println!("QA pairs: {}", normalized.qa.len());
                for (qa_index, qa) in normalized.qa.iter().enumerate() {
                    println!("\n  QA {}:", qa_index + 1);
                    if let Some(ref qid) = qa.question_id {
                        println!("    Question ID: {}", qid);
                    }
                    println!("    Question: {}", qa.question_text);
                    println!("    Answer: {}", qa.answer);
                }
                println!("\n");
            }
            Err(e) => {
                log::warn!("Failed to extract QA from chunk {}: {}", index + 1, e);
            }
        }
    }
    
    log::info!("Successfully processed {} chunks", chunks.len());
    
    Ok(())
}

