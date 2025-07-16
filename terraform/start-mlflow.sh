#!/bin/bash

# Debug environment variables
echo "Environment variables:"
echo "MLFLOW_BACKEND_STORE_URI: $MLFLOW_BACKEND_STORE_URI"
echo "MLFLOW_DEFAULT_ARTIFACT_ROOT: $MLFLOW_DEFAULT_ARTIFACT_ROOT"
echo "GOOGLE_CLOUD_PROJECT: $GOOGLE_CLOUD_PROJECT"

# Wait for database to be ready
echo "Waiting for PostgreSQL to be ready..."
DB_HOST=$(echo $MLFLOW_BACKEND_STORE_URI | sed 's/.*@\([^:]*\):.*/\1/')
echo "Database host: $DB_HOST"
while ! nc -z $DB_HOST 5432; do
  echo "Waiting for database connection..."
  sleep 2
done

echo "Starting MLflow server..."
mlflow server \
  --backend-store-uri "$MLFLOW_BACKEND_STORE_URI" \
  --default-artifact-root "$MLFLOW_DEFAULT_ARTIFACT_ROOT" \
  --host 0.0.0.0 \
  --port 5000 \
  --serve-artifacts
