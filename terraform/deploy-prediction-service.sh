#!/bin/bash
# Deploy prediction service after model is trained and registered

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🤖 Deploying Prediction Service${NC}"
echo ""

# Check prerequisites
echo -e "${BLUE}📋 Checking prerequisites...${NC}"

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    echo -e "${RED}❌ terraform.tfvars not found!${NC}"
    exit 1
fi

# Get GCP project ID
GCP_PROJECT_ID=$(grep 'gcp_project_id' terraform.tfvars | cut -d'"' -f2)
if [ -z "$GCP_PROJECT_ID" ]; then
    echo -e "${RED}❌ gcp_project_id not found in terraform.tfvars${NC}"
    exit 1
fi

# Check if MLflow server is deployed
MLFLOW_URL=$(terraform output -raw mlflow_url 2>/dev/null || echo "")
if [ -z "$MLFLOW_URL" ]; then
    echo -e "${RED}❌ MLflow server not found. Deploy MLflow first!${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Prerequisites check passed${NC}"
echo -e "${BLUE}📦 GCP Project ID: $GCP_PROJECT_ID${NC}"
echo -e "${BLUE}🔬 MLflow URL: $MLFLOW_URL${NC}"
echo ""

# Step 1: Check if model exists in MLflow
echo -e "${BLUE}🔍 Checking if model 'mlops_project' exists in MLflow...${NC}"
if curl -s "$MLFLOW_URL/api/2.0/mlflow/registered-models/get?name=mlops_project" | grep -q "mlops_project"; then
    echo -e "${GREEN}✅ Model 'mlops_project' found in MLflow!${NC}"
else
    echo -e "${RED}❌ Model 'mlops_project' not found in MLflow!${NC}"
    echo -e "${YELLOW}💡 Please train and register your model first${NC}"
    exit 1
fi

# Step 2: Uncomment prediction service in main.tf
echo -e "${BLUE}🔧 Enabling prediction service in Terraform...${NC}"
sed -i 's|# 5. GCP Cloud Run for Prediction Service - COMMENTED OUT FOR PHASE 1|# 5. GCP Cloud Run for Prediction Service|' main.tf
sed -i 's|# Uncomment after training the model||' main.tf
sed -i 's|/\*||g' main.tf
sed -i 's|\*/||g' main.tf

# Step 3: Uncomment the output
sed -i 's|# Commented out until prediction service is deployed||' main.tf
sed -i 's|# output "prediction_service_url"|output "prediction_service_url"|' main.tf
sed -i 's|#   description = "Prediction service URL"|  description = "Prediction service URL"|' main.tf
sed -i 's|#   value = google_cloud_run_service.prediction_service.status\[0\].url|  value = google_cloud_run_service.prediction_service.status[0].url|' main.tf
sed -i 's|# }|}|' main.tf

echo -e "${GREEN}✅ Terraform configuration updated!${NC}"

# Step 4: Build and push prediction service Docker image
echo -e "${BLUE}🐳 Building prediction service Docker image...${NC}"
cd ../deploy_service/
docker build -t gcr.io/$GCP_PROJECT_ID/dental-prediction:latest .
docker push gcr.io/$GCP_PROJECT_ID/dental-prediction:latest
cd ../terraform/

echo -e "${GREEN}✅ Docker image built and pushed!${NC}"

# Step 5: Apply Terraform changes
echo -e "${BLUE}🏗️  Deploying prediction service with Terraform...${NC}"
terraform plan -out=tfplan
terraform apply tfplan

# Step 6: Get prediction service URL
PREDICTION_SERVICE_URL=$(terraform output -raw prediction_service_url 2>/dev/null || echo "")

echo -e "${GREEN}🎉 PREDICTION SERVICE DEPLOYED SUCCESSFULLY!${NC}"
echo ""
echo -e "${BLUE}📋 Service URLs:${NC}"
echo -e "${GREEN}🔬 MLflow Server: ${NC}$MLFLOW_URL"
echo -e "${GREEN}🤖 Prediction Service: ${NC}$PREDICTION_SERVICE_URL"
echo ""

# Step 7: Test the prediction service
echo -e "${BLUE}🧪 Testing prediction service...${NC}"
if [ ! -z "$PREDICTION_SERVICE_URL" ]; then
    echo -e "${BLUE}Testing home page...${NC}"
    if curl -s "$PREDICTION_SERVICE_URL/" > /dev/null; then
        echo -e "${GREEN}✅ Prediction service is responding!${NC}"

        echo -e "${BLUE}Testing prediction endpoint...${NC}"
        TEST_RESPONSE=$(curl -s -X POST "$PREDICTION_SERVICE_URL/predict" \
            -H "Content-Type: application/json" \
            -d '{
                "race": "chinese",
                "age": 25,
                "gender": "female",
                "breast_feeding_month": 6,
                "mother_occupation": "professional",
                "household_income": ">=4000",
                "mother_edu": "university",
                "delivery_type": "normal",
                "smoke_mother": "No",
                "night_bottle_feeding": "No"
            }' || echo "")

        if [ ! -z "$TEST_RESPONSE" ] && echo "$TEST_RESPONSE" | grep -q "prediction"; then
            echo -e "${GREEN}✅ Prediction endpoint working!${NC}"
            echo -e "${BLUE}📊 Test response: ${NC}$TEST_RESPONSE"
        else
            echo -e "${YELLOW}⚠️  Prediction endpoint might have issues${NC}"
            echo -e "${BLUE}📊 Response: ${NC}$TEST_RESPONSE"
        fi
    else
        echo -e "${YELLOW}⚠️  Prediction service not responding yet (may take a few minutes)${NC}"
    fi
fi

echo ""
echo -e "${BLUE}🧪 Manual test command:${NC}"
echo -e "${YELLOW}curl -X POST $PREDICTION_SERVICE_URL/predict \\\
  -H \"Content-Type: application/json\" \\\
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
echo -e "${BLUE}🌐 Web interface: ${NC}$PREDICTION_SERVICE_URL"
echo ""
