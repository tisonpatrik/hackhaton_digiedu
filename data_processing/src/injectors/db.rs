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

