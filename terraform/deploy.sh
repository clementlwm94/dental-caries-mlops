#!/bin/bash
# Simple deployment script for MLOps infrastructure

set -e

echo "🚀 Deploying MLOps Infrastructure..."

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    echo "❌ terraform.tfvars not found!"
    echo "💡 Copy terraform.tfvars.example to terraform.tfvars and update with your values"
    exit 1
fi

# Initialize Terraform
echo "🔧 Initializing Terraform..."
terraform init

# Plan the deployment
echo "📋 Planning deployment..."
terraform plan -out=tfplan

# Apply the deployment
echo "🚀 Applying deployment..."
terraform apply tfplan

# Display outputs
echo "✅ Deployment completed!"
echo ""
echo "📊 MLflow URL: $(terraform output -raw mlflow_url)"
echo "🤖 Prediction Service URL: $(terraform output -raw prediction_service_url)"
echo "🗄️ RDS Endpoint: $(terraform output -raw rds_endpoint)"
echo ""
echo "🔧 To destroy infrastructure: terraform destroy"
