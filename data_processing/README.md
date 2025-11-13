# Data Processing Service

## Setup

1. Create `.env` file from `.env.example`:
```bash
cp .env.example .env
```

2. Adjust `.env` as needed (HOST, PORT)

## Running

Use the Makefile for common tasks:

```bash
make run    # Start the server
make build  # Build the project
make test   # Run tests
make stop   # Stop running server
```

## API Documentation

API documentation is available on Swagger UI:
- http://localhost:8080/docs/