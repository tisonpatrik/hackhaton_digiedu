use std::path::Path;
use std::fs;
use std::io::{Read, Cursor};
use zip::ZipArchive;
use quick_xml::Reader;
use quick_xml::events::Event;

const MAX_FILE_SIZE: u64 = 50 * 1024 * 1024; // 50 MB

/// Extract text from PDF file
pub async fn parse_pdf_file(file_path: &Path) -> Result<String, String> {
    log::info!("Parsing PDF file: {:?}", file_path);
    
    let bytes = fs::read(file_path)
        .map_err(|e| format!("Failed to read PDF file: {}", e))?;
    
    // Use pdf-extract to get text
    let text = pdf_extract::extract_text_from_mem(&bytes)
        .map_err(|e| format!("Failed to extract text from PDF: {}", e))?;
    
    if text.trim().is_empty() {
        return Err("PDF contains no extractable text (might be scanned images)".to_string());
    }
    
    log::info!("PDF extraction successful: {} characters", text.len());
    Ok(text)
}

/// Extract text from DOCX file
pub async fn parse_docx_file(file_path: &Path) -> Result<String, String> {
    log::info!("Parsing DOCX file: {:?}", file_path);
    
    let file = fs::File::open(file_path)
        .map_err(|e| format!("Failed to open DOCX file: {}", e))?;
    
    let mut archive = ZipArchive::new(file)
        .map_err(|e| format!("Failed to read DOCX archive: {}", e))?;
    
    // Read document.xml which contains the main text
    let mut document_xml = archive
        .by_name("word/document.xml")
        .map_err(|e| format!("Failed to find document.xml in DOCX: {}", e))?;
    
    let mut xml_content = String::new();
    document_xml
        .read_to_string(&mut xml_content)
        .map_err(|e| format!("Failed to read document.xml: {}", e))?;
    
    // Parse XML and extract text from <w:t> tags
    let text = extract_text_from_docx_xml(&xml_content)?;
    
    if text.trim().is_empty() {
        return Err("DOCX contains no text".to_string());
    }
    
    log::info!("DOCX extraction successful: {} characters", text.len());
    Ok(text)
}

/// Extract text from PPTX file
pub async fn parse_pptx_file(file_path: &Path) -> Result<String, String> {
    log::info!("Parsing PPTX file: {:?}", file_path);
    
    let file = fs::File::open(file_path)
        .map_err(|e| format!("Failed to open PPTX file: {}", e))?;
    
    let mut archive = ZipArchive::new(file)
        .map_err(|e| format!("Failed to read PPTX archive: {}", e))?;
    
    let mut all_text = Vec::new();
    
    // PPTX stores slides in ppt/slides/slideN.xml
    for i in 0..archive.len() {
        let mut file = archive.by_index(i)
            .map_err(|e| format!("Failed to read archive entry: {}", e))?;
        
        let name = file.name().to_string();
        
        // Process slide files
        if name.starts_with("ppt/slides/slide") && name.ends_with(".xml") {
            let mut xml_content = String::new();
            file.read_to_string(&mut xml_content)
                .map_err(|e| format!("Failed to read slide XML: {}", e))?;
            
            if let Ok(text) = extract_text_from_pptx_xml(&xml_content) {
                if !text.trim().is_empty() {
                    all_text.push(format!("=== Slide {} ===\n{}", 
                        extract_slide_number(&name).unwrap_or(i + 1), 
                        text));
                }
            }
        }
    }
    
    if all_text.is_empty() {
        return Err("PPTX contains no text".to_string());
    }
    
    let result = all_text.join("\n\n");
    log::info!("PPTX extraction successful: {} slides, {} characters", all_text.len(), result.len());
    Ok(result)
}

/// Helper function to extract text from DOCX XML content
fn extract_text_from_docx_xml(xml: &str) -> Result<String, String> {
    let mut reader = Reader::from_str(xml);
    reader.config_mut().trim_text(true);
    
    let mut text_parts = Vec::new();
    let mut buf = Vec::new();
    let mut in_text_tag = false;
    
    loop {
        match reader.read_event_into(&mut buf) {
            Ok(Event::Start(e)) if e.name().as_ref() == b"w:t" => {
                in_text_tag = true;
            }
            Ok(Event::Text(e)) if in_text_tag => {
                if let Ok(txt) = e.unescape() {
                    text_parts.push(txt.to_string());
                }
            }
            Ok(Event::End(e)) if e.name().as_ref() == b"w:t" => {
                in_text_tag = false;
            }
            Ok(Event::Start(e)) if e.name().as_ref() == b"w:p" => {
                // Paragraph break
                if !text_parts.is_empty() && !text_parts.last().unwrap().ends_with('\n') {
                    text_parts.push("\n".to_string());
                }
            }
            Ok(Event::Eof) => break,
            Err(e) => return Err(format!("XML parsing error: {}", e)),
            _ => {}
        }
        buf.clear();
    }
    
    Ok(text_parts.join(""))
}

/// Helper function to extract text from PPTX XML content
fn extract_text_from_pptx_xml(xml: &str) -> Result<String, String> {
    let mut reader = Reader::from_str(xml);
    reader.config_mut().trim_text(true);
    
    let mut text_parts = Vec::new();
    let mut buf = Vec::new();
    let mut in_text_tag = false;
    
    loop {
        match reader.read_event_into(&mut buf) {
            Ok(Event::Start(e)) if e.name().as_ref() == b"a:t" => {
                in_text_tag = true;
            }
            Ok(Event::Text(e)) if in_text_tag => {
                if let Ok(txt) = e.unescape() {
                    let s = txt.to_string();
                    if !s.trim().is_empty() {
                        text_parts.push(s);
                    }
                }
            }
            Ok(Event::End(e)) if e.name().as_ref() == b"a:t" => {
                in_text_tag = false;
            }
            Ok(Event::Start(e)) if e.name().as_ref() == b"a:p" => {
                // Paragraph break
                if !text_parts.is_empty() && !text_parts.last().unwrap().ends_with('\n') {
                    text_parts.push("\n".to_string());
                }
            }
            Ok(Event::Eof) => break,
            Err(e) => return Err(format!("XML parsing error: {}", e)),
            _ => {}
        }
        buf.clear();
    }
    
    Ok(text_parts.join(" "))
}

/// Extract slide number from filename like "ppt/slides/slide1.xml"
fn extract_slide_number(filename: &str) -> Option<usize> {
    filename
        .trim_end_matches(".xml")
        .chars()
        .rev()
        .take_while(|c| c.is_numeric())
        .collect::<String>()
        .chars()
        .rev()
        .collect::<String>()
        .parse()
        .ok()
}

/// Main entry point for parsing document files
pub async fn parse_document_file(file_path: &Path) -> Result<String, String> {
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
    
    match extension.as_str() {
        "pdf" => parse_pdf_file(file_path).await,
        "docx" => parse_docx_file(file_path).await,
        "pptx" => parse_pptx_file(file_path).await,
        _ => Err(format!("Unsupported document format: {}", extension)),
    }
}
