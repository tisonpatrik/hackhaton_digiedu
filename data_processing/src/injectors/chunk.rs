use uuid::Uuid;
use crate::processors::tabular::TABULAR_RECORD_SEPARATOR;

#[derive(Debug, Clone)]
#[allow(dead_code)]
pub struct TextChunk {
    pub id: Uuid,
    pub text: String,
    pub total_tokens: usize,
    pub     chunk_order_index: usize,
}

#[allow(dead_code)]
pub fn create_chunks_from_document(
    text: &str,
    separator: &str,
    token_size: usize,
    overlap_token_size: usize,
) -> Result<Vec<TextChunk>, String> {
    let bpe = tiktoken_rs::cl100k_base()
        .map_err(|e| format!("Failed to initialize tokenizer: {}", e))?;
    
    let is_tabular = separator == TABULAR_RECORD_SEPARATOR;
    
    if is_tabular {
        create_chunks_from_tabular_data(text, separator, token_size, &bpe)
    } else {
        create_chunks_from_plain_text(text, separator, token_size, overlap_token_size, &bpe)
    }
}

fn create_chunks_from_tabular_data(
    text: &str,
    separator: &str,
    token_size: usize,
    bpe: &tiktoken_rs::CoreBPE,
) -> Result<Vec<TextChunk>, String> {
    let mut results = Vec::new();
    let records: Vec<&str> = text.split(separator).collect();
    
    let mut current_chunk = String::new();
    let mut current_tokens = 0;
    
    for record in records {
        let trimmed_record = record.trim();
        if trimmed_record.is_empty() {
            continue;
        }
        
        let record_with_separator = format!("{}{}", trimmed_record, separator);
        let record_tokens = bpe.encode_with_special_tokens(&record_with_separator);
        let record_token_count = record_tokens.len();
        
        if current_tokens + record_token_count > token_size && !current_chunk.is_empty() {
            let chunk_tokens = bpe.encode_with_special_tokens(&current_chunk);
            results.push(TextChunk {
                id: Uuid::new_v4(),
                text: current_chunk.trim().to_string(),
                total_tokens: chunk_tokens.len(),
                chunk_order_index: results.len(),
            });
            current_chunk.clear();
            current_tokens = 0;
        }
        
        if !current_chunk.is_empty() {
            current_chunk.push_str(&record_with_separator);
        } else {
            current_chunk = record_with_separator;
        }
        current_tokens += record_token_count;
    }
    
    if !current_chunk.is_empty() {
        let chunk_tokens = bpe.encode_with_special_tokens(&current_chunk);
        results.push(TextChunk {
            id: Uuid::new_v4(),
            text: current_chunk.trim().to_string(),
            total_tokens: chunk_tokens.len(),
            chunk_order_index: results.len(),
        });
    }
    
    Ok(results)
}

fn create_chunks_from_plain_text(
    text: &str,
    separator: &str,
    token_size: usize,
    overlap_token_size: usize,
    bpe: &tiktoken_rs::CoreBPE,
) -> Result<Vec<TextChunk>, String> {
    let mut results = Vec::new();
    
    let parts: Vec<&str> = text.split(separator).collect();
    
    for part in parts {
        let trimmed_part = part.trim();
        if trimmed_part.is_empty() {
            continue;
        }
        
        let chunk_tokens = bpe.encode_with_special_tokens(trimmed_part);
        
        if chunk_tokens.len() > token_size {
            for start in (0..chunk_tokens.len()).step_by(token_size.saturating_sub(overlap_token_size)) {
                let end = (start + token_size).min(chunk_tokens.len());
                let chunk_tokens_slice = &chunk_tokens[start..end];
                
                let chunk_text = bpe.decode(chunk_tokens_slice.to_vec())
                    .map_err(|e| format!("Failed to decode tokens: {}", e))?;
                
                let token_count = end - start;
                results.push(TextChunk {
                    id: Uuid::new_v4(),
                    text: chunk_text.trim().to_string(),
                    total_tokens: token_count,
                    chunk_order_index: results.len(),
                });
            }
        } else {
            let chunk_text = bpe.decode(chunk_tokens.clone())
                .map_err(|e| format!("Failed to decode tokens: {}", e))?;
            
            results.push(TextChunk {
                id: Uuid::new_v4(),
                text: chunk_text.trim().to_string(),
                total_tokens: chunk_tokens.len(),
                chunk_order_index: results.len(),
            });
        }
    }
    
    Ok(results)
}

