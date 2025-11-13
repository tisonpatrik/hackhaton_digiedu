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

