use std::path::Path;
use std::fs;
use base64::{Engine as _, engine::general_purpose};
use serde::{Deserialize, Serialize};

use crate::file_types::is_image_extension;

#[derive(Serialize)]
struct ChatRequest {
    model: String,
    messages: Vec<ChatMessage>,
    max_tokens: u32,
}

#[derive(Serialize)]
struct ChatMessage {
    role: String,
    content: Vec<ContentPart>,
}

#[derive(Serialize)]
#[serde(tag = "type", rename_all = "snake_case")]
enum ContentPart {
    Text {
        text: String,
    },
    ImageUrl {
        image_url: ImageUrl,
    },
}

#[derive(Serialize)]
struct ImageUrl {
    url: String,
}

#[derive(Deserialize)]
struct ChatResponse {
    choices: Vec<Choice>,
}

#[derive(Deserialize)]
struct Choice {
    message: ResponseMessage,
}

#[derive(Deserialize)]
struct ResponseMessage {
    content: String,
}

pub async fn analyze_image_file(image_path: &Path) -> Result<String, String> {
    // Validation checks
    if !image_path.exists() {
        return Err(format!("Image file not found: {}", image_path.display()));
    }
    
    if !image_path.is_file() {
        return Err(format!("Path is not a file: {}", image_path.display()));
    }
    
    let extension = image_path
        .extension()
        .and_then(|ext| ext.to_str())
        .map(|ext| ext.to_lowercase())
        .unwrap_or_default();
    
    if !is_image_extension(&extension) {
        return Err(format!("Invalid image file format: {}", extension));
    }
    
    log::info!("Analyzing image file: {:?}", image_path);
    
    // Read image file
    let image_bytes = fs::read(image_path)
        .map_err(|e| format!("Failed to read image file: {}", e))?;
    
    // Encode to base64
    let image_base64 = general_purpose::STANDARD.encode(&image_bytes);
    
    // Determine mime type
    let mime_type = match extension.as_str() {
        "jpg" | "jpeg" => "image/jpeg",
        "png" => "image/png",
        "gif" => "image/gif",
        "webp" => "image/webp",
        "bmp" => "image/bmp",
        "tiff" | "tif" => "image/tiff",
        _ => "image/jpeg", // fallback
    };
    
    let data_url = format!("data:{};base64,{}", mime_type, image_base64);
    
    log::info!("Image encoded: {} bytes -> {} base64 chars", image_bytes.len(), image_base64.len());
    
    // Get Featherless AI API key
    let api_key = std::env::var("FEATHERLESS_API_KEY")
        .or_else(|_| std::env::var("API_KEY"))
        .or_else(|_| std::env::var("API_KEYS"))
        .map_err(|_| {
            "FEATHERLESS_API_KEY, API_KEY, or API_KEYS environment variable not set. Please set it in your .env file.".to_string()
        })?;
    
    let base_url = std::env::var("FEATHERLESS_BASE_URL")
        .unwrap_or_else(|_| "https://api.featherless.ai/v1".to_string());
    
    let model = std::env::var("FEATHERLESS_VISION_MODEL")
        .unwrap_or_else(|_| "google/gemma-3-4b-it".to_string());
    
    // Create request
    let request = ChatRequest {
        model: model.clone(),
        messages: vec![
            ChatMessage {
                role: "user".to_string(),
                content: vec![
                    ContentPart::Text {
                        text: "Please provide a comprehensive description of this image. Extract and describe:\n\
                               1. All visible text (if any)\n\
                               2. Main subjects, objects, and elements\n\
                               3. Visual context, setting, and composition\n\
                               4. Any diagrams, charts, or data visualizations\n\
                               5. Educational or informational content\n\
                               \nBe detailed and thorough - this information will be used for analysis by other AI models.".to_string(),
                    },
                    ContentPart::ImageUrl {
                        image_url: ImageUrl {
                            url: data_url,
                        },
                    },
                ],
            },
        ],
        max_tokens: 1000,
    };
    
    // Create client with longer timeout
    let client = reqwest::Client::builder()
        .timeout(std::time::Duration::from_secs(120)) // 2 minutes
        .build()
        .map_err(|e| format!("Failed to create HTTP client: {}", e))?;
    
    log::info!("Sending vision request to: {}/chat/completions (model: {})", base_url, model);
    log::debug!("Request payload: max_tokens={}, image_size={} bytes", 1000, image_bytes.len());
    
    let start_time = std::time::Instant::now();
    
    // Send request to Featherless AI
    let response = client
        .post(format!("{}/chat/completions", base_url))
        .header("Authorization", format!("Bearer {}", api_key))
        .header("Content-Type", "application/json")
        .json(&request)
        .send()
        .await
        .map_err(|e| {
            log::error!("Failed to connect to Featherless AI: {}", e);
            format!("Failed to connect to Featherless AI: {}", e)
        })?;
    
    let status = response.status();
    log::info!("Received response from Featherless AI: HTTP {}", status);
    
    if !status.is_success() {
        let error_body = response.text().await.unwrap_or_else(|_| "Unknown error".to_string());
        log::error!("Vision API failed with status {}: {}", status, error_body);
        return Err(format!("Vision API failed with status {}: {}", status, error_body));
    }
    
    // Parse response
    let response_json: ChatResponse = response
        .json()
        .await
        .map_err(|e| {
            log::error!("Failed to parse vision response: {}", e);
            format!("Failed to parse vision response: {}", e)
        })?;
    
    let description = response_json
        .choices
        .first()
        .ok_or_else(|| {
            log::error!("No choices in response from vision API");
            "No choices in response".to_string()
        })?
        .message
        .content
        .clone();
    
    let duration = start_time.elapsed();
    log::info!("Image analysis complete: {} characters in {:.2}s", description.len(), duration.as_secs_f64());
    
    Ok(description)
}
