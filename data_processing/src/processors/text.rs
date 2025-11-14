use std::path::Path;
use std::fs;
use std::io::Write;

const MAX_FILE_SIZE: u64 = 10 * 1024 * 1024; // 10MB

pub async fn parse_text_file(file_path: &Path) -> Result<String, String> {
    // Check if file exists
    if !file_path.exists() {
        return Err(format!("File not found: {}", file_path.display()));
    }
    
    // Verify it's a file, not a directory
    if !file_path.is_file() {
        return Err(format!("Path is not a file: {}", file_path.display()));
    }
    
    // Check file size
    let metadata = fs::metadata(file_path)
        .map_err(|e| format!("Failed to read file metadata: {}", e))?;
    
    if metadata.len() > MAX_FILE_SIZE {
        return Err(format!(
            "File too large: {} bytes (max {} bytes)",
            metadata.len(),
            MAX_FILE_SIZE
        ));
    }
    
    // Get file extension to determine handling
    let extension = file_path
        .extension()
        .and_then(|ext| ext.to_str())
        .map(|ext| ext.to_lowercase())
        .unwrap_or_default();
    
    let content = match extension.as_str() {
        "doc" | "docx" => {
            return Err("Word document parsing not implemented".to_string());
        }
        "txt" | "md" | "log" => {
            // Read as UTF-8 text
            fs::read_to_string(file_path)
                .map_err(|e| format!("Failed to read text file: {}", e))?
        }
        _ => {
            return Err(format!("Unsupported text file format: {}", extension));
        }
    };
    
    // Create processed files directory
    let processed_dir = Path::new("./processed_text");
    fs::create_dir_all(processed_dir)
        .map_err(|e| format!("Failed to create processed text directory: {}", e))?;
    
    // Save processed content to file
    let output_filename = format!(
        "{}.txt",
        file_path
            .file_stem()
            .and_then(|s| s.to_str())
            .unwrap_or("processed")
    );
    let output_path = processed_dir.join(&output_filename);
    
    let mut file = fs::File::create(&output_path)
        .map_err(|e| format!("Failed to create output file: {}", e))?;
    
    file.write_all(content.as_bytes())
        .map_err(|e| format!("Failed to write output file: {}", e))?;
    
    Ok(output_path.to_string_lossy().to_string())
}

