use serde::{Deserialize, Serialize};
use utoipa::ToSchema;
use schemars::JsonSchema;

#[derive(Deserialize, Serialize, ToSchema)]
pub struct UploadFileRequest {
    /// Path to the file on the local filesystem
    #[schema(example = "/path/to/file.txt")]
    pub path: String,
}

#[derive(Serialize, Deserialize, ToSchema)]
pub struct LabelResponse {
    /// Label ID
    pub id: i32,
    /// Label name
    pub name: String,
    /// Normalized name for comparison
    pub normalized_name: String,
    /// Optional category
    #[serde(skip_serializing_if = "Option::is_none")]
    pub category: Option<String>,
    /// Usage count
    pub usage_count: i32,
}

#[derive(Serialize, Deserialize, ToSchema)]
pub struct FileUploadResponse {
    /// Status of the upload
    #[schema(example = "ok")]
    pub status: String,
    /// Type of file detected
    #[schema(example = "audio")]
    pub file_type: String,
    /// Original filename
    #[schema(example = "recording.mp3")]
    pub filename: String,
    /// Path where file was saved
    #[schema(example = "/app/audio_files/recording.mp3")]
    pub file_path: String,
    /// Transcript text (for audio files)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub transcript_text: Option<String>,
    /// Path to transcript file (for audio files)
    #[serde(skip_serializing_if = "Option::is_none")]
    #[schema(example = "/app/transcripts/recording.txt")]
    pub transcript_path: Option<String>,
    /// Extracted labels from content
    #[serde(skip_serializing_if = "Option::is_none")]
    pub labels: Option<Vec<LabelResponse>>,
}

#[derive(Serialize, Deserialize, ToSchema)]
pub struct FileUploadError {
    /// Error message
    #[schema(example = "Failed to save file")]
    pub error: String,
}

#[derive(Serialize, Deserialize, ToSchema)]
pub struct UploadFileResponse {
    /// Status of the file check
    #[schema(example = "ok")]
    pub status: String,
    /// Type of file detected
    #[schema(example = "audio")]
    pub file_type: String,
    /// Path to transcript (only for audio files)
    #[serde(skip_serializing_if = "Option::is_none")]
    #[schema(example = "/app/transcripts/recording.txt")]
    pub transcript_path: Option<String>,
}

#[derive(Serialize, Deserialize, ToSchema)]
pub struct UploadFileError {
    /// Error message
    #[schema(example = "File not found")]
    pub error: String,
}

#[derive(Deserialize, Serialize, ToSchema)]
pub struct TranscribeRequest {
    /// Path to the audio file on the local filesystem
    #[schema(example = "/home/user/audio/recording.mp3")]
    pub audio_path: String,
}

#[derive(Serialize, Deserialize, ToSchema)]
pub struct TranscribeResponse {
    /// Status of the transcription
    #[schema(example = "ok")]
    pub status: String,
    /// Path to the generated transcript file
    #[schema(example = "/home/user/transcripts/recording.txt")]
    pub transcript_path: String,
}

#[derive(Serialize, Deserialize, ToSchema)]
pub struct TranscribeError {
    /// Error message
    #[schema(example = "Audio file not found")]
    pub error: String,
}

#[derive(Serialize, Deserialize, Clone, JsonSchema)]
pub struct QuestionAnswer {
    /// Optional question identifier (e.g., internal key or column name)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub question_id: Option<String>,
    /// Question text (if extractable from text)
    pub question_text: String,
    /// Answer from respondent
    pub answer: String,
}

#[derive(Serialize, Deserialize, Clone, JsonSchema)]
pub struct NormalizedResponse {
    /// Optional timestamp (format unknown)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub timestamp: Option<String>,
    /// Original text that the model saw
    pub raw_input: String,
    /// List of question-answer pairs
    pub qa: Vec<QuestionAnswer>,
    /// Topic labels for categorization
    pub topic_labels: Vec<String>,
}

#[derive(Serialize, Deserialize, ToSchema)]
pub struct ChunkWithLabelsResponse {
    /// Chunk document name
    pub document_name: String,
    /// Chunk content
    pub content: String,
    /// Associated labels
    pub labels: Vec<LabelResponse>,
}

#[derive(Serialize, Deserialize, ToSchema)]
pub struct LabelsListResponse {
    /// List of all labels
    pub labels: Vec<LabelResponse>,
}

#[derive(Serialize, Deserialize, ToSchema)]
pub struct SearchByLabelsRequest {
    /// Label IDs to search for
    pub label_ids: Vec<i32>,
}

#[derive(Serialize, Deserialize, ToSchema)]
pub struct SearchByLabelsResponse {
    /// Chunks matching the labels
    pub chunks: Vec<ChunkWithLabelsResponse>,
}
