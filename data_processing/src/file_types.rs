pub const AUDIO_EXTENSIONS: &[&str] = &[
    "mp3", "wav", "ogg", "flac", "m4a", "aac", "wma", "opus"
];

pub const TEXT_EXTENSIONS: &[&str] = &[
    "txt", "md", "log"
];

pub const DOCUMENT_EXTENSIONS: &[&str] = &[
    "pdf", "docx", "pptx"
];

pub const TABULAR_EXTENSIONS: &[&str] = &[
    "csv", "xlsx", "xls", "tsv", "ods", "json", "yml", "yaml"
];

pub const IMAGE_EXTENSIONS: &[&str] = &[
    "png", "jpg", "jpeg", "gif", "webp", "bmp", "tiff", "tif"
];

pub fn is_audio_extension(extension: &str) -> bool {
    AUDIO_EXTENSIONS.contains(&extension)
}

pub fn is_text_extension(extension: &str) -> bool {
    TEXT_EXTENSIONS.contains(&extension)
}

pub fn is_document_extension(extension: &str) -> bool {
    DOCUMENT_EXTENSIONS.contains(&extension)
}

pub fn is_tabular_extension(extension: &str) -> bool {
    TABULAR_EXTENSIONS.contains(&extension)
}

pub fn is_image_extension(extension: &str) -> bool {
    IMAGE_EXTENSIONS.contains(&extension)
}

