mod normalization;
mod db;

pub use normalization::{normalize_label, find_similar_label, calculate_similarity};
pub use db::{
    get_or_create_label,
    associate_labels_with_chunk,
    get_all_labels,
    get_labels_for_chunk,
    search_chunks_by_labels,
    LabelInfo,
    ChunkWithLabels
};
