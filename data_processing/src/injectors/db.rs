use sqlx::PgPool;

pub async fn insert_or_update_document(
    pool: &PgPool,
    document_name: &str,
    content: &str,
) -> Result<(), String> {
    sqlx::query(
        "INSERT INTO document (document_name, content) 
         VALUES ($1, $2) 
         ON CONFLICT (document_name) 
         DO UPDATE SET content = $2, created_at = CURRENT_TIMESTAMP"
    )
    .bind(document_name)
    .bind(content)
    .execute(pool)
    .await
    .map_err(|e| format!("Failed to insert document into database: {}", e))?;
    
    Ok(())
}

pub async fn insert_chunk(
    pool: &PgPool,
    document_name: &str,
    chunk_index: usize,
    content: &str,
    embedding: &[f32],
) -> Result<(), String> {
    let chunk_key = format!("{}:{}", document_name, chunk_index);
    
    let embedding_str = format!(
        "[{}]",
        embedding.iter()
            .map(|v| v.to_string())
            .collect::<Vec<_>>()
            .join(",")
    );
    
    sqlx::query(
        "INSERT INTO chunk (document_name, content, embedding) 
         VALUES ($1, $2, $3::vector)
         ON CONFLICT (document_name) 
         DO UPDATE SET content = $2, embedding = $3::vector, created_at = CURRENT_TIMESTAMP"
    )
    .bind(&chunk_key)
    .bind(content)
    .bind(&embedding_str)
    .execute(pool)
    .await
    .map_err(|e| format!("Failed to insert chunk into database: {}", e))?;
    
    Ok(())
}

