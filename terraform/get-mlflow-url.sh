#!/bin/bash
# Quick script to get MLflow URL from Terraform and display it

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📊 Getting MLflow URL from Terraform...${NC}"

# Check if we're in the terraform directory
if [ ! -f "main.tf" ]; then
    echo "❌ Error: Run this script from the terraform directory"
    exit 1
fi

# Get MLflow URL from Terraform output
MLFLOW_URL=$(terraform output -raw mlflow_url 2>/dev/null)
if [ -z "$MLFLOW_URL" ]; then
    echo "❌ Error: Could not get MLflow URL from Terraform output"
    echo "💡 Make sure Terraform has been applied successfully"
    exit 1
fi

echo -e "${GREEN}✅ MLflow URL: $MLFLOW_URL${NC}"
echo ""
echo -e "${BLUE}🔗 You can use this URL in your .env file:${NC}"
echo "MLFLOW_TRACKING_URI=$MLFLOW_URL"
echo ""
echo -e "${BLUE}🧪 Test the connection:${NC}"
echo "curl $MLFLOW_URL/"
