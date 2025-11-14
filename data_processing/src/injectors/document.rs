use sqlx::PgPool;

use crate::injectors::db;
use crate::injectors::create_chunks_from_document;
use crate::gen_ai::chat_completion;
use crate::prompts::{reformat_to_conversation_system, reformat_to_conversation_user};
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
    
    // Process each chunk through chat completion for cleaning/reformatting
    let mut cleaned_chunks = Vec::new();
    for (index, chunk) in chunks.iter().enumerate() {
        log::info!("Processing chunk {}/{} ({} tokens)", index + 1, chunks.len(), chunk.total_tokens);
        
        let system_msg = reformat_to_conversation_system();
        let user_msg = reformat_to_conversation_user(&chunk.text);
        
        match chat_completion(system_msg, &user_msg).await {
            Ok(cleaned_text) => {
                cleaned_chunks.push(cleaned_text.clone());
                
                // Print preview of cleaned chunk
                let preview = if cleaned_text.len() > 300 {
                    &cleaned_text[..300]
                } else {
                    &cleaned_text
                };
                println!("\n=== Chunk {} Cleaned (first {} chars) ===", index + 1, preview.len());
                println!("{}", preview);
                if cleaned_text.len() > 300 {
                    println!("... (truncated, total length: {} chars)\n", cleaned_text.len());
                } else {
                    println!("\n");
                }
            }
            Err(e) => {
                log::warn!("Failed to clean chunk {}: {}", index + 1, e);
                // Keep original chunk text if cleaning fails
                cleaned_chunks.push(chunk.text.clone());
            }
        }
    }
    
    log::info!("Successfully processed {} chunks through AI cleaning", cleaned_chunks.len());
    
    Ok(())
}

