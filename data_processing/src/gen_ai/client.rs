// Use direct HTTP request to Mistral API for custom model support
use serde::{Deserialize, Serialize};
use serde_json::json;
use std::sync::OnceLock;
use crate::models::NormalizedResponse;

static HTTP_CLIENT: OnceLock<reqwest::Client> = OnceLock::new();

fn get_client() -> &'static reqwest::Client {
    HTTP_CLIENT.get_or_init(|| {
        reqwest::Client::builder()
            .timeout(std::time::Duration::from_secs(60))
            .build()
            .expect("Failed to create HTTP client")
    })
}

#[derive(Serialize)]
struct ChatRequest {
    model: String,
    messages: Vec<ChatMessageRequest>,
    temperature: f32,
    top_p: f32,
    max_tokens: Option<u32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    response_format: Option<serde_json::Value>,
}

#[derive(Serialize)]
struct ChatMessageRequest {
    role: String,
    content: String,
}

#[derive(Deserialize)]
struct ChatResponse {
    choices: Vec<Choice>,
}

#[derive(Deserialize)]
struct Choice {
    message: Message,
}

#[derive(Deserialize)]
struct Message {
    content: String,
}

pub async fn extract_qa_structured(
    system_message: &str,
    user_message: &str,
) -> Result<NormalizedResponse, String> {
    let api_key = std::env::var("MISTRAL_API_KEY")
        .map_err(|_| {
            "MISTRAL_API_KEY environment variable not set. Please set it in your .env file or environment variables.".to_string()
        })?;
    
    let client = get_client();
    let model_name = "mistral-small-2506";
    
    let json_schema = json!({
        "type": "object",
        "properties": {
            "timestamp": {
                "oneOf": [
                    {"type": "string"},
                    {"type": "null"}
                ]
            },
            "raw_input": {
                "type": "string"
            },
            "qa": {
                "type": "array",
                "items": {
                    "type": "object",
                    "properties": {
                        "question_id": {
                            "oneOf": [
                                {"type": "string"},
                                {"type": "null"}
                            ]
                        },
                        "question_text": {
                            "type": "string"
                        },
                        "answer": {
                            "type": "string"
                        }
                    },
                    "required": ["question_text", "answer"],
                    "additionalProperties": false
                }
            },
            "topic_labels": {
                "type": "array",
                "items": {
                    "type": "string"
                }
            }
        },
        "required": ["raw_input", "qa", "topic_labels"],
        "additionalProperties": false
    });
    
    let response_format = json!({
        "type": "json_schema",
        "json_schema": {
            "name": "normalized_response",
            "strict": true,
            "schema": json_schema
        }
    });
    
    let request = ChatRequest {
        model: model_name.to_string(),
        messages: vec![
            ChatMessageRequest {
                role: "system".to_string(),
                content: system_message.to_string(),
            },
            ChatMessageRequest {
                role: "user".to_string(),
                content: user_message.to_string(),
            },
        ],
        temperature: 0.1,
        top_p: 1.0,
        max_tokens: Some(16000),
        response_format: Some(response_format),
    };
    
    let response = client
        .post("https://api.mistral.ai/v1/chat/completions")
        .header("Authorization", format!("Bearer {}", api_key))
        .header("Content-Type", "application/json")
        .json(&request)
        .send()
        .await
        .map_err(|e| format!("Failed to send request to Mistral API: {}", e))?;
    
    if !response.status().is_success() {
        let status = response.status();
        let error_body = response.text().await.unwrap_or_else(|_| "Unknown error".to_string());
        return Err(format!("Mistral API error ({}): {}", status, error_body));
    }
    
    let chat_response: ChatResponse = response
        .json()
        .await
        .map_err(|e| format!("Failed to parse response: {}", e))?;
    
    let content = chat_response
        .choices
        .first()
        .ok_or("No choices in response")?
        .message
        .content
        .clone();
    
    let normalized: NormalizedResponse = serde_json::from_str(&content)
        .map_err(|e| format!("Failed to parse structured response: {}", e))?;
    
    Ok(normalized)
}

#[derive(Serialize)]
struct EmbedRequest {
    model: String,
    input: Vec<String>,
}

#[derive(Deserialize)]
struct EmbedResponse {
    data: Vec<EmbedData>,
}

#[derive(Deserialize)]
struct EmbedData {
    embedding: Vec<f32>,
}

pub async fn create_embedding(text: &str) -> Result<Vec<f32>, String> {
    let api_key = std::env::var("MISTRAL_API_KEY")
        .map_err(|_| {
            "MISTRAL_API_KEY environment variable not set. Please set it in your .env file or environment variables.".to_string()
        })?;
    
    let client = get_client();
    let model_name = "mistral-embed";
    
    let request = EmbedRequest {
        model: model_name.to_string(),
        input: vec![text.to_string()],
    };
    
    let response = client
        .post("https://api.mistral.ai/v1/embeddings")
        .header("Authorization", format!("Bearer {}", api_key))
        .header("Content-Type", "application/json")
        .json(&request)
        .send()
        .await
        .map_err(|e| format!("Failed to send request to Mistral Embed API: {}", e))?;
    
    if !response.status().is_success() {
        let status = response.status();
        let error_body = response.text().await.unwrap_or_else(|_| "Unknown error".to_string());
        return Err(format!("Mistral Embed API error ({}): {}", status, error_body));
    }
    
    let embed_response: EmbedResponse = response
        .json()
        .await
        .map_err(|e| format!("Failed to parse embedding response: {}", e))?;
    
    let embedding = embed_response
        .data
        .first()
        .ok_or("No embedding data in response")?
        .embedding
        .clone();
    
    Ok(embedding)
}