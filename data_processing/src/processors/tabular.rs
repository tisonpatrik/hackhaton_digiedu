use std::path::Path;
use std::fs;

use calamine::{Reader, Data};

use crate::file_types::is_tabular_extension;

const MAX_FILE_SIZE: u64 = 50 * 1024 * 1024;

fn parse_excel_file(file_path: &Path) -> Result<String, String> {
    let mut workbook = calamine::open_workbook_auto(file_path)
        .map_err(|e| format!("Failed to open Excel/ODS file: {}", e))?;
    
    let mut result = String::new();
    
    if let Some(Ok(range)) = workbook.worksheet_range_at(0) {
        for row in range.rows() {
            let row_text: Vec<String> = row
                .iter()
                .map(|cell| {
                    match cell {
                        Data::Empty => String::new(),
                        Data::String(s) => s.clone(),
                        Data::Float(f) => f.to_string(),
                        Data::Int(i) => i.to_string(),
                        Data::Bool(b) => b.to_string(),
                        Data::Error(e) => format!("ERROR: {:?}", e),
                        Data::DateTime(dt) => dt.to_string(),
                        Data::DateTimeIso(dt) => dt.to_string(),
                        Data::DurationIso(dt) => dt.clone(),
                    }
                })
                .collect();
            result.push_str(&row_text.join("\t"));
            result.push('\n');
        }
    } else {
        return Err("No worksheet found in Excel/ODS file".to_string());
    }
    
    Ok(result)
}

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
            parse_excel_file(file_path)?
        }
        _ => {
            return Err(format!("Unsupported tabular file format: {}", extension));
        }
    };
    
    Ok(content)
}

