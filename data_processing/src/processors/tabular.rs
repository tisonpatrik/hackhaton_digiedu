use std::path::Path;
use std::fs;

use crate::file_types::is_tabular_extension;

const MAX_FILE_SIZE: u64 = 50 * 1024 * 1024;

pub async fn parse_tabular_file(file_path: &Path) -> Result<String, String> {
    if !file_path.exists() {
        return Err(format!("File not found: {}", file_path.display()));
    }
    
    if !file_path.is_file() {
        return Err(format!("Path is not a file: {}", file_path.display()));
    }
    
    let metadata = fs::metadata(file_path)
        .map_err(|e| format!("Failed to read file metadata: {}", e))?;
    
    if metadata.len() > MAX_FILE_SIZE {
        return Err(format!(
            "File too large: {} bytes (max {} bytes)",
            metadata.len(),
            MAX_FILE_SIZE
        ));
    }
    
    let extension = file_path
        .extension()
        .and_then(|ext| ext.to_str())
        .map(|ext| ext.to_lowercase())
        .unwrap_or_default();
    
    if !is_tabular_extension(&extension) {
        return Err(format!("Invalid tabular file format: {}", extension));
    }
    
    // Read and convert to plain text
    let content = match extension.as_str() {
        "csv" | "tsv" => {
            fs::read_to_string(file_path)
                .map_err(|e| format!("Failed to read CSV/TSV file: {}", e))?
        }
        "json" => {
            let json_content = fs::read_to_string(file_path)
                .map_err(|e| format!("Failed to read JSON file: {}", e))?;
            serde_json::from_str::<serde_json::Value>(&json_content)
                .map_err(|e| format!("Invalid JSON format: {}", e))?;
            json_content
        }
        "yml" | "yaml" => {
            fs::read_to_string(file_path)
                .map_err(|e| format!("Failed to read YAML file: {}", e))?
        }
        "xlsx" | "xls" | "ods" => {
            return Err("Excel/ODS file parsing not implemented".to_string());
        }
        _ => {
            return Err(format!("Unsupported tabular file format: {}", extension));
        }
    };
    
    Ok(content)
}

