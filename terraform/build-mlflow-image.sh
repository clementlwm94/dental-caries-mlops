#!/bin/bash

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🐳 Building MLflow container image...${NC}"

# Get project ID from terraform.tfvars
PROJECT_ID=$(grep 'gcp_project_id' terraform.tfvars | cut -d'"' -f2)
if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}❌ Error: Could not find gcp_project_id in terraform.tfvars${NC}"
    exit 1
fi

echo -e "${BLUE}📦 Project ID: $PROJECT_ID${NC}"

# Configure Docker for GCR
echo -e "${BLUE}🔧 Configuring Docker for Google Container Registry...${NC}"
gcloud auth configure-docker

# Build the MLflow image
echo -e "${BLUE}🏗️  Building MLflow server image...${NC}"
docker build -f Dockerfile.mlflow -t gcr.io/$PROJECT_ID/mlflow-server:latest .

# Push to GCR
echo -e "${BLUE}📤 Pushing image to Google Container Registry...${NC}"
docker push gcr.io/$PROJECT_ID/mlflow-server:latest

echo -e "${GREEN}✅ MLflow image built and pushed successfully!${NC}"
echo -e "${GREEN}🎯 Image: gcr.io/$PROJECT_ID/mlflow-server:latest${NC}"
