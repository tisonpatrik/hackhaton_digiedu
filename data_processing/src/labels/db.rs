use sqlx::PgPool;
use serde::{Deserialize, Serialize};
use crate::labels::normalization::{normalize_label, find_similar_label};

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct LabelInfo {
    pub id: i32,
    pub name: String,
    pub normalized_name: String,
    pub category: Option<String>,
    pub usage_count: i32,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ChunkWithLabels {
    pub document_name: String,
    pub content: String,
    pub labels: Vec<LabelInfo>,
}

/// Get or create a label, handling deduplication
/// If a similar label exists, returns the existing label
pub async fn get_or_create_label(
    pool: &PgPool,
    label_name: &str,
    category: Option<&str>,
) -> Result<LabelInfo, String> {
    let normalized = normalize_label(label_name);
    
    // First, try exact match on normalized name
    let existing: Option<(i32, String, String, Option<String>, i32)> = sqlx::query_as(
        "SELECT id, name, normalized_name, category, usage_count FROM labels WHERE normalized_name = $1"
    )
    .bind(&normalized)
    .fetch_optional(pool)
    .await
    .map_err(|e| format!("Failed to check for existing label: {}", e))?;
    
    if let Some((id, name, norm, cat, count)) = existing {
        return Ok(LabelInfo {
            id,
            name,
            normalized_name: norm,
            category: cat,
            usage_count: count,
        });
    }
    
    // Check for similar labels
    let all_labels: Vec<(String, String)> = sqlx::query_as(
        "SELECT name, normalized_name FROM labels"
    )
    .fetch_all(pool)
    .await
    .map_err(|e| format!("Failed to fetch existing labels: {}", e))?;
    
    if let Some((similar_name, similar_normalized, similarity)) = find_similar_label(label_name, &all_labels) {
        log::info!(
            "Found similar label '{}' (similarity: {:.2}) for new label '{}', using existing",
            similar_name, similarity, label_name
        );
        
        // Return the existing similar label
        let existing: (i32, String, String, Option<String>, i32) = sqlx::query_as(
            "SELECT id, name, normalized_name, category, usage_count FROM labels WHERE normalized_name = $1"
        )
        .bind(&similar_normalized)
        .fetch_one(pool)
        .await
        .map_err(|e| format!("Failed to fetch similar label: {}", e))?;
        
        return Ok(LabelInfo {
            id: existing.0,
            name: existing.1,
            normalized_name: existing.2,
            category: existing.3,
            usage_count: existing.4,
        });
    }
    
    // Create new label
    let result: (i32, String, String, Option<String>, i32) = sqlx::query_as(
        "INSERT INTO labels (name, normalized_name, category) VALUES ($1, $2, $3) 
         RETURNING id, name, normalized_name, category, usage_count"
    )
    .bind(label_name)
    .bind(&normalized)
    .bind(category)
    .fetch_one(pool)
    .await
    .map_err(|e| format!("Failed to create label: {}", e))?;
    
    log::info!("Created new label: {} (normalized: {})", label_name, normalized);
    
    Ok(LabelInfo {
        id: result.0,
        name: result.1,
        normalized_name: result.2,
        category: result.3,
        usage_count: result.4,
    })
}

/// Associate multiple labels with a chunk
pub async fn associate_labels_with_chunk(
    pool: &PgPool,
    chunk_document_name: &str,
    label_names: &[String],
    category: Option<&str>,
) -> Result<Vec<LabelInfo>, String> {
    let mut label_infos = Vec::new();
    
    for label_name in label_names {
        // Get or create label
        let label_info = get_or_create_label(pool, label_name, category).await?;
        
        // Associate with chunk (ignore if already exists)
        sqlx::query(
            "INSERT INTO chunk_labels (chunk_document_name, label_id) VALUES ($1, $2)
             ON CONFLICT (chunk_document_name, label_id) DO NOTHING"
        )
        .bind(chunk_document_name)
        .bind(label_info.id)
        .execute(pool)
        .await
        .map_err(|e| format!("Failed to associate label with chunk: {}", e))?;
        
        // Increment usage count
        sqlx::query(
            "UPDATE labels SET usage_count = usage_count + 1, updated_at = CURRENT_TIMESTAMP 
             WHERE id = $1"
        )
        .bind(label_info.id)
        .execute(pool)
        .await
        .map_err(|e| format!("Failed to update label usage count: {}", e))?;
        
        label_infos.push(label_info);
    }
    
    Ok(label_infos)
}

/// Get all labels with their usage counts
pub async fn get_all_labels(pool: &PgPool) -> Result<Vec<LabelInfo>, String> {
    let labels: Vec<(i32, String, String, Option<String>, i32)> = sqlx::query_as(
        "SELECT id, name, normalized_name, category, usage_count FROM labels ORDER BY usage_count DESC, name ASC"
    )
    .fetch_all(pool)
    .await
    .map_err(|e| format!("Failed to fetch labels: {}", e))?;
    
    Ok(labels
        .into_iter()
        .map(|(id, name, normalized_name, category, usage_count)| LabelInfo {
            id,
            name,
            normalized_name,
            category,
            usage_count,
        })
        .collect())
}

/// Get labels for a specific chunk
pub async fn get_labels_for_chunk(
    pool: &PgPool,
    chunk_document_name: &str,
) -> Result<Vec<LabelInfo>, String> {
    let labels: Vec<(i32, String, String, Option<String>, i32)> = sqlx::query_as(
        "SELECT l.id, l.name, l.normalized_name, l.category, l.usage_count 
         FROM labels l
         INNER JOIN chunk_labels cl ON l.id = cl.label_id
         WHERE cl.chunk_document_name = $1
         ORDER BY l.name ASC"
    )
    .bind(chunk_document_name)
    .fetch_all(pool)
    .await
    .map_err(|e| format!("Failed to fetch labels for chunk: {}", e))?;
    
    Ok(labels
        .into_iter()
        .map(|(id, name, normalized_name, category, usage_count)| LabelInfo {
            id,
            name,
            normalized_name,
            category,
            usage_count,
        })
        .collect())
}

/// Search for chunks by label names or IDs
pub async fn search_chunks_by_labels(
    pool: &PgPool,
    label_ids: &[i32],
) -> Result<Vec<ChunkWithLabels>, String> {
    if label_ids.is_empty() {
        return Ok(Vec::new());
    }
    
    // Get chunks that have at least one of the specified labels
    let chunks: Vec<(String, String)> = sqlx::query_as(
        "SELECT DISTINCT c.document_name, c.content 
         FROM chunk c
         INNER JOIN chunk_labels cl ON c.document_name = cl.chunk_document_name
         WHERE cl.label_id = ANY($1)"
    )
    .bind(label_ids)
    .fetch_all(pool)
    .await
    .map_err(|e| format!("Failed to search chunks by labels: {}", e))?;
    
    let mut results = Vec::new();
    
    for (document_name, content) in chunks {
        let labels = get_labels_for_chunk(pool, &document_name).await?;
        results.push(ChunkWithLabels {
            document_name,
            content,
            labels,
        });
    }
    
    Ok(results)
}
