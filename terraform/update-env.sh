#!/bin/bash
# Script to update .env file with MLflow URL from Terraform output

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔄 Updating .env file with MLflow URL from Terraform...${NC}"

# Check if we're in the terraform directory
if [ ! -f "main.tf" ]; then
    echo -e "${RED}❌ Error: Run this script from the terraform directory${NC}"
    exit 1
fi

# Get MLflow URL from Terraform output
MLFLOW_URL=$(terraform output -raw mlflow_url 2>/dev/null)
if [ -z "$MLFLOW_URL" ]; then
    echo -e "${RED}❌ Error: Could not get MLflow URL from Terraform output${NC}"
    echo -e "${YELLOW}💡 Make sure Terraform has been applied successfully${NC}"
    exit 1
fi

echo -e "${GREEN}✅ MLflow URL from Terraform: $MLFLOW_URL${NC}"

# Path to .env file
ENV_FILE="../.env"

# Check if .env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}❌ Error: .env file not found at $ENV_FILE${NC}"
    echo -e "${YELLOW}💡 Make sure .env file exists in the project root${NC}"
    exit 1
fi

# Backup original .env file
cp "$ENV_FILE" "$ENV_FILE.backup"
echo -e "${BLUE}📦 Backed up original .env file to .env.backup${NC}"

# Update MLFLOW_TRACKING_URI in .env file
if grep -q "MLFLOW_TRACKING_URI=" "$ENV_FILE"; then
    # Update existing line
    sed -i "s|MLFLOW_TRACKING_URI=.*|MLFLOW_TRACKING_URI=$MLFLOW_URL|" "$ENV_FILE"
    echo -e "${GREEN}✅ Updated existing MLFLOW_TRACKING_URI in .env file${NC}"
else
    # Add new line
    echo "MLFLOW_TRACKING_URI=$MLFLOW_URL" >> "$ENV_FILE"
    echo -e "${GREEN}✅ Added MLFLOW_TRACKING_URI to .env file${NC}"
fi

# Also update local-airflow .env if it exists
LOCAL_AIRFLOW_ENV="../local-airflow/.env"
if [ -f "$LOCAL_AIRFLOW_ENV" ]; then
    cp "$LOCAL_AIRFLOW_ENV" "$LOCAL_AIRFLOW_ENV.backup"

    if grep -q "MLFLOW_TRACKING_URI=" "$LOCAL_AIRFLOW_ENV"; then
        sed -i "s|MLFLOW_TRACKING_URI=.*|MLFLOW_TRACKING_URI=$MLFLOW_URL|" "$LOCAL_AIRFLOW_ENV"
        echo -e "${GREEN}✅ Updated local-airflow/.env file${NC}"
    else
        echo "MLFLOW_TRACKING_URI=$MLFLOW_URL" >> "$LOCAL_AIRFLOW_ENV"
        echo -e "${GREEN}✅ Added MLFLOW_TRACKING_URI to local-airflow/.env file${NC}"
    fi
fi

echo ""
echo -e "${BLUE}📋 Updated configuration:${NC}"
echo -e "${GREEN}MLFLOW_TRACKING_URI=$MLFLOW_URL${NC}"
echo ""
echo -e "${BLUE}🔄 Next steps:${NC}"
echo -e "1. ${YELLOW}Restart Airflow to pick up new environment variables:${NC}"
echo -e "   cd ../local-airflow && ./start-airflow.sh"
echo ""
echo -e "2. ${YELLOW}Test MLflow connection:${NC}"
echo -e "   curl $MLFLOW_URL/"
echo ""
echo -e "${GREEN}✅ Environment files updated successfully!${NC}"
