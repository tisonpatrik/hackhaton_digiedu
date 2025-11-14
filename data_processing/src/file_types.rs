pub const AUDIO_EXTENSIONS: &[&str] = &[
    "mp3", "wav", "ogg", "flac", "m4a", "aac", "wma", "opus"
];

pub const TEXT_EXTENSIONS: &[&str] = &[
    "txt", "md", "log", "doc", "docx"
];

pub const TABULAR_EXTENSIONS: &[&str] = &[
    "csv", "xlsx", "xls", "tsv", "ods", "json", "yml", "yaml"
];

pub fn is_audio_extension(extension: &str) -> bool {
    AUDIO_EXTENSIONS.contains(&extension)
}

pub fn is_text_extension(extension: &str) -> bool {
    TEXT_EXTENSIONS.contains(&extension)
}

pub fn is_tabular_extension(extension: &str) -> bool {
    TABULAR_EXTENSIONS.contains(&extension)
}

