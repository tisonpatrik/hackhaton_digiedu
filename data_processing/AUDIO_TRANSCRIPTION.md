# Audio Transcription Feature

This document describes the audio transcription capability added to the data processing service.

## Overview

The service provides a REST API endpoint that transcribes audio files to text using faster-whisper (base model).

## Architecture

- **Rust API**: Provides the `/transcribe` endpoint (port 8080)
- **faster-whisper service**: Runs in Docker (fedirz/faster-whisper-server), handles actual transcription using OpenAI-compatible API (port 8000)
- **File storage**: Audio files are temporarily copied for processing, transcripts are saved to `./transcripts/` directory

## Setup

1. Start all services:
```bash
make run
```

This will start:
- PostgreSQL database
- faster-whisper service (on port 8000)
- Rust API (on port 8080)
- Phoenix dashboard

**Note:** The faster-whisper service uses an OpenAI-compatible API with the base model.

## API Usage

### Endpoint: POST `/transcribe`

**Request Body:**
```json
{
  "audio_path": "/absolute/path/to/audio/file.ogg"
}
```

**Success Response (200):**
```json
{
  "status": "ok",
  "transcript_path": "./transcripts/file.txt"
}
```

**Error Responses:**
- `404`: Audio file not found
- `500`: Transcription failed or service unavailable

### Example with curl:

```bash
curl -X POST http://localhost:8080/transcribe \
  -H "Content-Type: application/json" \
  -d '{"audio_path": "/home/artogahr/hackhaton_digiedu/data_processing/sample-audio/Monologue.ogg"}'
```

### Example with sample file:

```bash
curl -X POST http://localhost:8080/transcribe \
  -H "Content-Type: application/json" \
  -d '{"audio_path": "'$(pwd)'/sample-audio/Monologue.ogg"}'
```

## Swagger Documentation

Interactive API documentation is available at:
```
http://localhost:8080/docs/
```

## How It Works

1. User sends audio file path to `/transcribe` endpoint
2. Rust API validates the file exists
3. Audio file is copied to `./audio_files/` (shared volume)
4. Request is sent to faster-whisper service
5. Transcription is saved to `./transcripts/` directory
6. Path to transcript file is returned

## Supported Audio Formats

faster-whisper supports most common audio formats:
- MP3
- WAV
- OGG
- M4A
- FLAC
- And more...

## Configuration

Environment variable:
- `WHISPER_URL`: URL of faster-whisper service (default: `http://localhost:8000`)

## Test Results

Successfully tested with `sample-audio/Monologue.ogg` (1.4MB):
- Transcription time: ~18 seconds
- Output saved to: `./transcripts/Monologue.txt`
- Accuracy: Excellent (base model)

## Directories

- `./audio_files/`: Temporary storage for audio files being processed
- `./transcripts/`: Output directory for transcript files
