# File Upload Integration Guide

This document explains how the file upload system works across the educational data processing platform.

## Architecture Overview

```
User Browser (Phoenix LiveView)
        ↓ (uploads file via multipart/form-data)
Phoenix App (live_dashboard:4000)
        ↓ (forwards file to Rust API)
Rust API (data_processing:8080)
        ↓ (if audio file)
Faster-Whisper Service (faster-whisper:8000)
        ↓ (returns transcription)
Back to User with results
```

## Components

### 1. Rust Data Processing API (`data_processing/`)

**New Endpoint**: `POST /upload`
- Accepts multipart file uploads
- Automatically detects audio files by extension (mp3, wav, ogg, flac, m4a, aac, wma, opus)
- Audio files → saved to `/app/audio_files/` and transcribed
- Other files → saved to `/app/uploads/`
- Returns JSON with file info and transcript (if audio)

**Dependencies Added**:
- `actix-multipart = "0.7"` - For handling file uploads
- `actix-cors = "0.7"` - For CORS support
- `futures-util = "0.3"` - For async stream processing

**API Response** (for audio files):
```json
{
  "status": "ok",
  "file_type": "audio",
  "filename": "interview.mp3",
  "file_path": "/app/audio_files/interview.mp3",
  "transcript_text": "The actual transcription text...",
  "transcript_path": "/app/transcripts/interview.txt"
}
```

**API Response** (for other files):
```json
{
  "status": "ok",
  "file_type": "other",
  "filename": "document.pdf",
  "file_path": "/app/uploads/document.pdf"
}
```

### 2. Phoenix LiveView Frontend (`live_dashboard/`)

**New Page**: `/upload` - `FileUploadLive`

Features:
- Drag-and-drop file upload interface
- Real-time upload progress
- Automatic file type detection
- Displays transcription results for audio files
- Shows file metadata and paths
- Error handling with user-friendly messages

**Navigation**: Added to sidebar under "Data Processing" section

**Environment Variable**:
- `DATA_PROCESSING_URL` - Points to Rust API (default: `http://data_processing:8080`)

### 3. Docker Compose Configuration

**Updated Services**:
- `live_dashboard` now includes `DATA_PROCESSING_URL` environment variable
- `live_dashboard` depends on `data_processing` service
- `data_processing` has new volume for uploads: `data_processing_uploads:/app/uploads`

**Volumes**:
- `data_processing_audio` - Stores audio files
- `data_processing_transcripts` - Stores transcription text files
- `data_processing_uploads` - Stores non-audio files

## How to Use

### Starting the System

```bash
# Start all services
make run

# Or with docker-compose directly
docker-compose up --build
```

### Accessing the Upload Interface

1. Open browser to `http://localhost:4000`
2. Click "Data Processing" in the sidebar
3. Click "File Upload"
4. Drag & drop a file or click to browse
5. Click "Upload & Process"

### Testing with Your Audio File

```bash
# Copy your audio file to the project (optional, can upload directly from UI)
cp /home/artogahr/czech-interview-5min.mp3 /home/artogahr/hackhaton_digiedu/

# Or just use the web UI to upload it directly!
```

### API Testing (curl)

```bash
# Upload an audio file directly to the API
curl -X POST http://localhost:8080/upload \
  -F "file=@/path/to/your/audio.mp3"

# Upload any other file
curl -X POST http://localhost:8080/upload \
  -F "file=@/path/to/your/document.pdf"
```

## File Flow Example

1. **User uploads `interview.mp3` via web interface**
2. **Phoenix receives file**, reads it into memory
3. **Phoenix sends file** to Rust API at `http://data_processing:8080/upload`
4. **Rust API**:
   - Detects it's audio (`.mp3` extension)
   - Saves to `/app/audio_files/interview.mp3`
   - Calls Faster-Whisper service
   - Receives transcription
   - Saves transcript to `/app/transcripts/interview.txt`
   - Returns JSON response
5. **Phoenix displays**:
   - Filename: `interview.mp3`
   - File type: `audio`
   - Transcription text (in a nice formatted box)
   - File paths

## Supported File Types

### Audio Files (Auto-transcribed):
- MP3 (`.mp3`)
- WAV (`.wav`)
- OGG (`.ogg`)
- FLAC (`.flac`)
- M4A (`.m4a`)
- AAC (`.aac`)
- WMA (`.wma`)
- OPUS (`.opus`)

### Other Files:
- Any file type accepted
- Stored for future processing
- Could be extended for PDF text extraction, image analysis, etc.

## For Hackathon Demo

This demonstrates:
- **Multi-service architecture** - Phoenix (frontend) + Rust (processing) + Faster-Whisper (AI)
- **Educational data processing** - Transcribe lectures, interviews, student presentations
- **Real-time feedback** - Users see results immediately
- **Scalable design** - Each service can scale independently
- **Multiple data types** - Audio now, can extend to video, documents, etc.

## Future Enhancements

Potential additions for the hackathon:
- [ ] Save transcriptions to PostgreSQL database
- [ ] Show history of uploaded files
- [ ] Support batch uploads (multiple files at once)
- [ ] Add speaker identification in transcriptions
- [ ] Extract keywords/topics from transcriptions using AI
- [ ] Generate summaries of audio content
- [ ] Support video file uploads and extract audio
- [ ] PDF text extraction and analysis
- [ ] Language detection and translation

## Troubleshooting

### File upload fails
- Check that `data_processing` service is running: `docker ps`
- Check logs: `docker-compose logs data_processing`
- Verify CORS is working (check browser console)

### Transcription fails
- Check `faster-whisper` service: `docker-compose logs faster-whisper`
- Verify audio file format is supported
- Check file size (max 100MB by default)

### Phoenix can't connect to Rust API
- Ensure `DATA_PROCESSING_URL=http://data_processing:8080` is set
- Check docker network: `docker network inspect hackhaton_digiedu_default`
- Try accessing API directly: `curl http://localhost:8080/`

## API Documentation

Swagger UI available at: `http://localhost:8080/docs/`

This provides interactive API documentation for all endpoints including the new `/upload` endpoint.
