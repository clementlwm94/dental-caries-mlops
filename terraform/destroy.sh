#!/bin/bash
# Complete cleanup script for MLOps infrastructure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${RED}🗑️  Complete MLOps Infrastructure Cleanup${NC}"
echo ""

# Get GCP project ID from terraform.tfvars
if [ -f "terraform.tfvars" ]; then
    GCP_PROJECT_ID=$(grep 'gcp_project_id' terraform.tfvars | cut -d'"' -f2)
fi

echo -e "${YELLOW}⚠️  WARNING: This will destroy ALL infrastructure!${NC}"
echo -e "${BLUE}This includes:${NC}"
echo -e "  - AWS RDS database (all MLflow data will be lost)"
echo -e "  - AWS S3 bucket (all model artifacts will be lost)"
echo -e "  - AWS ECS cluster and MLflow server"
echo -e "  - Google Cloud Run service"
echo ""

read -p "Are you sure you want to continue? (yes/no): " -r
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo -e "${GREEN}❌ Cancelled.${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}🗑️  Step 1: Destroying Cloud Run service...${NC}"
if [ ! -z "$GCP_PROJECT_ID" ]; then
    gcloud run services delete dental-prediction \
        --region=us-central1 \
        --quiet 2>/dev/null || echo -e "${YELLOW}⚠️  Cloud Run service not found or already deleted${NC}"

    echo -e "${BLUE}🧹 Cleaning up Container Registry images...${NC}"
    gcloud container images delete gcr.io/$GCP_PROJECT_ID/dental-prediction:latest \
        --quiet 2>/dev/null || echo -e "${YELLOW}⚠️  Container image not found${NC}"
else
    echo -e "${YELLOW}⚠️  GCP project ID not found, skipping Cloud Run cleanup${NC}"
fi

echo -e "${BLUE}🗑️  Step 2: Destroying AWS infrastructure with Terraform...${NC}"
terraform destroy -auto-approve

echo ""
echo -e "${GREEN}✅ Cleanup completed successfully!${NC}"
echo ""
echo -e "${BLUE}🔍 Manual cleanup (if needed):${NC}"
echo -e "  - Check AWS console for any remaining resources"
echo -e "  - Check GCP console for any remaining Cloud Run services"
echo -e "  - Remove any local Docker images: docker image prune -a"
echo ""
echo -e "${GREEN}🎉 All infrastructure has been destroyed!${NC}"
