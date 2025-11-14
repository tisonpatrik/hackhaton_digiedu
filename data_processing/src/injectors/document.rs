use sqlx::PgPool;
use async_openai::types::chat::{
    ChatCompletionRequestMessage, ChatCompletionRequestSystemMessage,
    ChatCompletionRequestUserMessage,
};

use crate::injectors::db;
use crate::injectors::create_chunks_from_document;
use crate::gen_ai::chat_completion;
use crate::prompts::{reformat_to_conversation_system, reformat_to_conversation_user};

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
    
    // Reformat content to conversation/questionnaire format using AI
    let messages: Vec<ChatCompletionRequestMessage> = vec![
        ChatCompletionRequestSystemMessage::from(reformat_to_conversation_system())
            .into(),
        ChatCompletionRequestUserMessage::from(reformat_to_conversation_user(text)).into(),
    ];
    
    match chat_completion(messages).await {
        Ok(formatted_text) => {
            log::info!("Document '{}' successfully reformatted to conversation format", document_name);
            log::info!("Formatted text length: {} characters", formatted_text.len());
            
            // Print first 500 characters to terminal
            let preview = if formatted_text.len() > 500 {
                &formatted_text[..500]
            } else {
                &formatted_text
            };
            println!("\n=== Reformatted Document Preview (first {} chars) ===", preview.len());
            println!("{}", preview);
            if formatted_text.len() > 500 {
                println!("... (truncated, total length: {} chars)\n", formatted_text.len());
            } else {
                println!("\n");
            }
        }
        Err(e) => {
            log::warn!("Failed to reformat document '{}': {}", document_name, e);
            // Pokračujeme i při chybě, protože hlavní úkol (uložení dokumentu) je hotový
        }
    }
    
    const TOKEN_SIZE: usize = 1000;
    const OVERLAP_TOKEN_SIZE: usize = 200;
    const SEPARATOR: &str = ".";
    
    let chunks = create_chunks_from_document(text, SEPARATOR, TOKEN_SIZE, OVERLAP_TOKEN_SIZE)?;
    log::info!("Created {} chunks from document '{}'", chunks.len(), document_name);
    
    Ok(())
}

