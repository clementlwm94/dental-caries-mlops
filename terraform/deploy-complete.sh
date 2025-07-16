#!/bin/bash
# Complete deployment script for MLOps infrastructure and services

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Complete MLOps Infrastructure & Service Deployment${NC}"
echo ""

# Check prerequisites
echo -e "${BLUE}📋 Checking prerequisites...${NC}"

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    echo -e "${RED}❌ terraform.tfvars not found!${NC}"
    echo -e "${YELLOW}💡 Copy terraform.tfvars.example to terraform.tfvars and update with your values${NC}"
    exit 1
fi

# Check if GCP CLI is configured
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n 1 > /dev/null 2>&1; then
    echo -e "${RED}❌ GCP CLI not configured!${NC}"
    echo -e "${YELLOW}💡 Run 'gcloud auth login' first${NC}"
    exit 1
fi

# Get GCP project ID from terraform.tfvars
GCP_PROJECT_ID=$(grep 'gcp_project_id' terraform.tfvars | cut -d'"' -f2)
if [ -z "$GCP_PROJECT_ID" ]; then
    echo -e "${RED}❌ gcp_project_id not found in terraform.tfvars${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Prerequisites check passed${NC}"
echo -e "${BLUE}📦 GCP Project ID: $GCP_PROJECT_ID${NC}"
echo ""

# Step 1: Configure GCP Docker authentication
echo -e "${BLUE}🔐 Step 1: Configuring GCP Docker authentication...${NC}"
gcloud auth configure-docker --quiet

# Step 2: Build and push Docker images FIRST
echo -e "${BLUE}🏗️  Step 2: Building Docker images...${NC}"

# Build MLflow server image
echo -e "${BLUE}📦 Building MLflow server image...${NC}"
./build-mlflow-image.sh

# Build prediction service image
echo -e "${BLUE}📦 Building prediction service image...${NC}"
cd ../deploy_service/
docker build -t gcr.io/$GCP_PROJECT_ID/dental-prediction:latest .
docker push gcr.io/$GCP_PROJECT_ID/dental-prediction:latest
cd ../terraform/

echo -e "${GREEN}✅ Docker images built and pushed successfully!${NC}"
echo ""

# Step 3: Deploy infrastructure with Terraform (images now exist)
echo -e "${BLUE}🏗️  Step 3: Deploying infrastructure with Terraform...${NC}"
terraform init
terraform plan -out=tfplan
terraform apply tfplan

# Get outputs from Terraform
echo -e "${BLUE}📊 Getting infrastructure outputs...${NC}"
MLFLOW_URL=$(terraform output -raw mlflow_url 2>/dev/null || echo "")
PREDICTION_SERVICE_URL=$(terraform output -raw prediction_service_url 2>/dev/null || echo "")
POSTGRES_ENDPOINT=$(terraform output -raw postgres_endpoint 2>/dev/null || echo "")
GCS_BUCKET=$(terraform output -raw gcs_bucket 2>/dev/null || echo "")

echo -e "${GREEN}✅ Infrastructure deployed successfully!${NC}"

# Update .env files with MLflow URL
if [ ! -z "$MLFLOW_URL" ]; then
    echo -e "${BLUE}🔄 Updating .env files with MLflow URL...${NC}"
    ./update-env.sh
    echo -e "${GREEN}✅ Environment files updated!${NC}"
else
    echo -e "${YELLOW}⚠️  Warning: Could not get MLflow URL from Terraform${NC}"
fi

echo -e "${GREEN}✅ Cloud Run service deployed successfully!${NC}"
echo ""

# Step 5: Verify deployments
echo -e "${BLUE}🔍 Step 5: Verifying deployments...${NC}"

# Test MLflow (if URL is available)
if [ ! -z "$MLFLOW_URL" ]; then
    echo -e "${BLUE}🧪 Testing MLflow server...${NC}"
    if curl -s "$MLFLOW_URL/" > /dev/null; then
        echo -e "${GREEN}✅ MLflow server is responding${NC}"
    else
        echo -e "${YELLOW}⚠️  MLflow server not responding yet (may take a few minutes)${NC}"
    fi
fi

# Test Prediction service
if [ ! -z "$PREDICTION_SERVICE_URL" ]; then
    echo -e "${BLUE}🧪 Testing Prediction service...${NC}"
    if curl -s "$PREDICTION_SERVICE_URL/" > /dev/null; then
        echo -e "${GREEN}✅ Prediction service is responding${NC}"
    else
        echo -e "${YELLOW}⚠️  Prediction service not responding yet (may take a few minutes)${NC}"
    fi
fi

echo ""
echo -e "${GREEN}🎉 DEPLOYMENT COMPLETED SUCCESSFULLY!${NC}"
echo ""
echo -e "${BLUE}📋 Service URLs:${NC}"
if [ ! -z "$MLFLOW_URL" ]; then
    echo -e "${GREEN}🔬 MLflow Server: ${NC}$MLFLOW_URL"
fi
if [ ! -z "$PREDICTION_SERVICE_URL" ]; then
    echo -e "${GREEN}🤖 Prediction Service: ${NC}$PREDICTION_SERVICE_URL"
fi
if [ ! -z "$POSTGRES_ENDPOINT" ]; then
    echo -e "${GREEN}🗄️  Cloud SQL Endpoint: ${NC}$POSTGRES_ENDPOINT"
fi
if [ ! -z "$GCS_BUCKET" ]; then
    echo -e "${GREEN}📦 GCS Bucket: ${NC}$GCS_BUCKET"
fi
echo ""

echo -e "${BLUE}🧪 Test your prediction service:${NC}"
echo -e "${YELLOW}curl -X POST $PREDICTION_SERVICE_URL/predict \\
  -H \"Content-Type: application/json\" \\
  -d '{
    \"race\": \"chinese\",
    \"age\": 25,
    \"gender\": \"female\",
    \"breast_feeding_month\": 6,
    \"mother_occupation\": \"professional\",
    \"household_income\": \">=4000\",
    \"mother_edu\": \"university\",
    \"delivery_type\": \"normal\",
    \"smoke_mother\": \"No\",
    \"night_bottle_feeding\": \"No\"
  }'${NC}"
echo ""

echo -e "${BLUE}🌐 Access web interface: ${NC}$PREDICTION_SERVICE_URL"
echo ""
echo -e "${GREEN}🛑 To destroy everything: ${NC}terraform destroy"
echo ""
