use async_openai::{
    config::OpenAIConfig,
    types::{
        chat::{ChatCompletionRequestMessage, CreateChatCompletionRequestArgs},
        embeddings::{CreateEmbeddingRequestArgs, EmbeddingInput},
    },
    Client,
};

fn create_client() -> Result<Client<OpenAIConfig>, String> {
    let api_base = "https://api.featherless.ai/v1";
    // Try API_KEY first, then fall back to API_KEYS for compatibility
    let api_key = std::env::var("API_KEY")
        .or_else(|_| std::env::var("API_KEYS"))
        .map_err(|_| {
            "API_KEY or API_KEYS environment variable not set. Please set it in your .env file or environment variables.".to_string()
        })?;
    
    let client = Client::with_config(
        OpenAIConfig::new()
            .with_api_key(&api_key)
            .with_api_base(api_base),
    );
    
    Ok(client)
}

pub async fn create_embedding(text: &str) -> Result<Vec<f32>, String> {
    let client = create_client()?;
    
    let request = CreateEmbeddingRequestArgs::default()
        .model("text-embedding-ada-002")
        .input(EmbeddingInput::String(text.to_string()))
        .build()
        .map_err(|e| format!("Failed to create embedding request: {}", e))?;
    
    let response = client
        .embeddings()
        .create(request)
        .await
        .map_err(|e| format!("Failed to create embedding: {}", e))?;
    
    let embedding = response
        .data
        .first()
        .ok_or("No embedding data in response")?
        .embedding
        .clone();
    
    Ok(embedding)
}

pub async fn chat_completion(
    messages: Vec<ChatCompletionRequestMessage>,
) -> Result<String, String> {
    let client = create_client()?;
    
    let request = CreateChatCompletionRequestArgs::default()
        .model("zai-org/GLM-4.6")
        .messages(messages)
        .temperature(0.1)
        .top_p(1.0)
        .frequency_penalty(0.0)
        .presence_penalty(0.0)
        .build()
        .map_err(|e| format!("Failed to create chat completion request: {}", e))?;

    let response = client
        .chat()
        .create(request)
        .await
        .map_err(|e| format!("Failed to create chat completion: {}", e))?;
    
    let content = response
        .choices
        .first()
        .and_then(|choice| choice.message.content.as_ref())
        .ok_or("No content in response")?
        .clone();
    
    Ok(content)
}