use serde::{Deserialize, Serialize};
use utoipa::ToSchema;

#[derive(Deserialize, Serialize, ToSchema)]
pub struct UploadFileRequest {
    /// Path to the file on the local filesystem
    #[schema(example = "/path/to/file.txt")]
    pub path: String,
}

#[derive(Serialize, Deserialize, ToSchema)]
pub struct UploadFileResponse {
    /// Status of the file check
    #[schema(example = "ok")]
    pub status: String,
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

