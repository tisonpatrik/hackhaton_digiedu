mod db;
mod document;
mod chunk;

pub use document::inject_document;
pub use chunk::create_chunks_from_document;

#[allow(unused_imports)]
pub use chunk::TextChunk;
