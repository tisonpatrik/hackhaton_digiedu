use std::path::Path;
use std::fs;

use calamine::{Reader, Data};

use crate::file_types::is_tabular_extension;

const MAX_FILE_SIZE: u64 = 50 * 1024 * 1024;

fn format_row_with_headers(id: &str, headers: &[String], values: &[String]) -> String {
    let mut pairs = Vec::new();
    for (i, header) in headers.iter().enumerate() {
        if i < values.len() && !values[i].is_empty() {
            pairs.push(format!("{}={}", header, values[i]));
        }
    }
    
    if pairs.is_empty() {
        format!("{}:\n", id)
    } else {
        format!("{}: {}\n", id, pairs.join(", "))
    }
}

fn cell_to_string(cell: &Data) -> String {
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
}

fn parse_excel_file(file_path: &Path) -> Result<String, String> {
    let mut workbook = calamine::open_workbook_auto(file_path)
        .map_err(|e| format!("Failed to open Excel/ODS file: {}", e))?;
    
    let mut result = String::new();
    
    if let Some(Ok(range)) = workbook.worksheet_range_at(0) {
        let rows: Vec<_> = range.rows().collect();
        
        if rows.is_empty() {
            return Err("Empty worksheet".to_string());
        }
        
        let header_row = rows[0];
        let headers: Vec<String> = header_row
            .iter()
            .map(cell_to_string)
            .collect();
        
        for row in rows.iter().skip(1) {
            let values: Vec<String> = row
                .iter()
                .map(cell_to_string)
                .collect();
            
            if values.is_empty() {
                continue;
            }
            
            let id = values[0].clone();
            result.push_str(&format_row_with_headers(&id, &headers, &values));
        }
    } else {
        return Err("No worksheet found in Excel/ODS file".to_string());
    }
    
    Ok(result)
}

fn parse_csv_tsv(content: &str, delimiter: char) -> Result<String, String> {
    let lines: Vec<&str> = content.lines().collect();
    
    if lines.is_empty() {
        return Err("Empty file".to_string());
    }
    
    let header_line = lines[0];
    let headers: Vec<String> = header_line
        .split(delimiter)
        .map(|s| s.trim().to_string())
        .collect();
    
    if headers.is_empty() {
        return Err("No headers found".to_string());
    }
    
    let mut result = String::new();
    
    for line in lines.iter().skip(1) {
        let values: Vec<String> = line
            .split(delimiter)
            .map(|s| s.trim().to_string())
            .collect();
        
        if values.is_empty() {
            continue;
        }
        
        let id = values[0].clone();
        result.push_str(&format_row_with_headers(&id, &headers, &values));
    }
    
    Ok(result)
}

fn parse_json(content: &str) -> Result<String, String> {
    let json: serde_json::Value = serde_json::from_str(content)
        .map_err(|e| format!("Invalid JSON format: {}", e))?;
    
    let mut result = String::new();
    
    match json {
        serde_json::Value::Array(items) => {
            for item in items {
                if let serde_json::Value::Object(obj) = item {
                    let id = obj
                        .get("id")
                        .or_else(|| obj.keys().next().and_then(|k| obj.get(k)))
                        .and_then(|v| v.as_str())
                        .unwrap_or("unknown")
                        .to_string();
                    
                    let mut pairs = Vec::new();
                    for (key, value) in obj.iter() {
                        let value_str = match value {
                            serde_json::Value::String(s) => s.clone(),
                            serde_json::Value::Number(n) => n.to_string(),
                            serde_json::Value::Bool(b) => b.to_string(),
                            serde_json::Value::Null => "null".to_string(),
                            _ => format!("{:?}", value),
                        };
                        pairs.push(format!("{}={}", key, value_str));
                    }
                    
                    if !pairs.is_empty() {
                        result.push_str(&format!("{}: {}\n", id, pairs.join(", ")));
                    }
                }
            }
        }
        serde_json::Value::Object(obj) => {
            let id = obj
                .get("id")
                .or_else(|| obj.keys().next().and_then(|k| obj.get(k)))
                .and_then(|v| v.as_str())
                .unwrap_or("root")
                .to_string();
            
            let mut pairs = Vec::new();
            for (key, value) in obj.iter() {
                let value_str = match value {
                    serde_json::Value::String(s) => s.clone(),
                    serde_json::Value::Number(n) => n.to_string(),
                    serde_json::Value::Bool(b) => b.to_string(),
                    serde_json::Value::Null => "null".to_string(),
                    _ => format!("{:?}", value),
                };
                pairs.push(format!("{}={}", key, value_str));
            }
            
            if !pairs.is_empty() {
                result.push_str(&format!("{}: {}\n", id, pairs.join(", ")));
            }
        }
        _ => {
            return Err("JSON must be an object or array of objects".to_string());
        }
    }
    
    Ok(result)
}

fn parse_yaml(content: &str) -> Result<String, String> {
    let yaml: serde_json::Value = serde_yaml::from_str(content)
        .map_err(|e| format!("Invalid YAML format: {}", e))?;
    
    let json_str = serde_json::to_string(&yaml)
        .map_err(|e| format!("Failed to convert YAML to JSON: {}", e))?;
    
    parse_json(&json_str)
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
    
    let content = match extension.as_str() {
        "csv" => {
            let raw_content = fs::read_to_string(file_path)
                .map_err(|e| format!("Failed to read CSV file: {}", e))?;
            parse_csv_tsv(&raw_content, ',')?
        }
        "tsv" => {
            let raw_content = fs::read_to_string(file_path)
                .map_err(|e| format!("Failed to read TSV file: {}", e))?;
            parse_csv_tsv(&raw_content, '\t')?
        }
        "json" => {
            let json_content = fs::read_to_string(file_path)
                .map_err(|e| format!("Failed to read JSON file: {}", e))?;
            parse_json(&json_content)?
        }
        "yml" | "yaml" => {
            let yaml_content = fs::read_to_string(file_path)
                .map_err(|e| format!("Failed to read YAML file: {}", e))?;
            parse_yaml(&yaml_content)?
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

