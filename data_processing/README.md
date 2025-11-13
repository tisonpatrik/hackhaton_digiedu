# Data Processing Service

## Running with Docker

1. Start all services:
```bash
cd .. && docker-compose up -d
```

2. Check services are running:
```bash
docker ps
```

3. Test the setup:
```bash
./test-docker.sh
```

Or test manually:
```bash
# Health check
curl http://localhost:8080/

# Test with audio file (will transcribe)
curl -X POST http://localhost:8080/upload-file \
  -H "Content-Type: application/json" \
  -d '{"path": "/app/sample-audio/Monologue.ogg"}'

# Test with non-audio file
curl -X POST http://localhost:8080/upload-file \
  -H "Content-Type: application/json" \
  -d '{"path": "/app/Cargo.toml"}'
```

4. View logs:
```bash
docker-compose logs -f data_processing
```

5. Stop everything:
```bash
cd .. && docker-compose down
```

## API Documentation

Swagger UI: http://localhost:8080/docs/

## How it works

- Upload any file to `/upload-file`
- If it's audio (mp3, wav, ogg, etc.) → automatically transcribes and returns transcript path
- If it's not audio → just confirms file exists