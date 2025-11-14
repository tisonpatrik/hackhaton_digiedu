/// System prompt for reformatting documents into conversation/questionnaire format
pub fn reformat_to_conversation_system() -> &'static str {
    "You are an assistant that reformats texts into conversation or questionnaire format. \
    You preserve all content and meaning, only changing the format to resemble a natural \
    conversation or structured questionnaire."
}

/// User prompt template for reformatting a document
pub fn reformat_to_conversation_user(text: &str) -> String {
    format!(
        "Reformat the following text into a conversation or questionnaire format. \
        Preserve all content and meaning, but reformat it to resemble a natural \
        conversation or structured questionnaire. Text:\n\n{}",
        text
    )
}

