#!/bin/sh
set -eu

# Run migrations before starting the server
echo "Running database migrations..."
/app/bin/migrate || {
    echo "Warning: Migration failed or already up to date, continuing startup..."
}

# Start the server
echo "Starting Phoenix server..."
exec /app/bin/server
