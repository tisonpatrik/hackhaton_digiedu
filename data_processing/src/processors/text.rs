use std::path::Path;
use std::fs;

use crate::file_types::is_text_extension;

const MAX_FILE_SIZE: u64 = 10 * 1024 * 1024;

pub async fn parse_text_file(file_path: &Path) -> Result<String, String> {
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
    
    if !is_text_extension(&extension) {
        return Err(format!("Invalid text file format: {}", extension));
    }
    
    let content = match extension.as_str() {
        "doc" | "docx" => {
            return Err("Word document parsing not implemented".to_string());
        }
        "txt" | "md" | "log" => {
            fs::read_to_string(file_path)
                .map_err(|e| format!("Failed to read text file: {}", e))?
        }
        _ => {
            return Err(format!("Unsupported text file format: {}", extension));
        }
    };
    
    Ok(content)
}

