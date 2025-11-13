#!/bin/bash

echo "=== Testing Docker Setup ==="
echo ""

echo "1. Checking if services are running..."
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(data_processing|faster_whisper|NAMES)"
echo ""

echo "2. Testing health endpoint..."
curl -s http://localhost:8080/ 
echo ""
echo ""

echo "3. Testing with non-audio file (should return file_type: other)..."
curl -s -X POST http://localhost:8080/upload-file \
  -H "Content-Type: application/json" \
  -d '{"path": "/app/Cargo.toml"}' | jq '.'
echo ""

echo "4. Testing with audio file (should transcribe)..."
# First, copy test audio into the container
docker cp /home/artogahr/hackhaton_digiedu/data_processing/sample-audio/Monologue.ogg data_processing:/app/test-audio.ogg

curl -s -X POST http://localhost:8080/upload-file \
  -H "Content-Type: application/json" \
  -d '{"path": "/app/test-audio.ogg"}' | jq '.'
echo ""

echo "5. Checking if transcript was created..."
docker exec data_processing ls -lh /app/transcripts/
echo ""

echo "=== Test Complete ==="
