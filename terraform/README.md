# Simple Terraform for MLOps Infrastructure

This is a **complete** Terraform setup that deploys your entire MLOps infrastructure and services automatically.

## 🎯 What This Creates

### AWS Components
- **S3 Bucket**: `mlops-clement` for MLflow artifacts
- **RDS PostgreSQL**: Database for MLflow metadata
- **ECS Fargate**: MLflow tracking server
- **VPC & Security**: Basic networking and security groups

### GCP Components
- **Cloud Run**: Auto-scaling prediction service
- **Container Registry**: Docker image storage

## 🚀 Complete Deployment (One Command!)

### 1. Setup Variables
```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values:
# - gcp_project_id = "your-gcp-project-id"
# - rds_password = "your-secure-password"
```

### 2. Deploy Everything
```bash
./deploy-complete.sh
```

**This single script will:**
- ✅ Deploy AWS infrastructure (RDS, S3, ECS, VPC)
- ✅ Build your prediction service Docker image
- ✅ Push image to Google Container Registry
- ✅ Deploy to Google Cloud Run
- ✅ Configure all environment variables
- ✅ Test all services
- ✅ Provide you with working URLs

### 3. Use Your Services
After deployment, you'll get:
- **MLflow Server**: `http://47.129.53.131:5000`
- **Prediction API**: `https://your-service-url.run.app`
- **Web Interface**: Same URL as prediction API

## 🔧 Prerequisites

### Before Running
```bash
# Configure AWS CLI
aws configure

# Configure GCP CLI
gcloud auth login
gcloud config set project YOUR_PROJECT_ID

# Make sure Docker is running
docker --version
```

## 🧪 Testing Your Deployment

### Test Prediction Service
```bash
# The script will show you this command after deployment
curl -X POST https://your-service-url.run.app/predict \
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
  }'
```

### Test MLflow Server
```bash
curl http://47.129.53.131:5000/
```

## 🗑️ Complete Cleanup

```bash
./destroy.sh
```

This will:
- Delete Cloud Run service
- Remove Container Registry images
- Destroy all AWS infrastructure
- Clean up everything

## 📁 Files Included

```
terraform/
├── main.tf                    # Main infrastructure definition
├── terraform.tfvars.example  # Example variables
├── deploy-complete.sh         # Complete deployment script
├── destroy.sh                 # Complete cleanup script
├── deploy.sh                  # Infrastructure-only deployment
└── README.md                  # This file
```

## 🎯 Why This is Better

### Old Way (Manual):
1. Run `terraform apply`
2. Build Docker image manually
3. Push to GCR manually
4. Deploy to Cloud Run manually
5. Configure environment variables manually
6. Test services manually

### New Way (Automated):
1. Run `./deploy-complete.sh`
2. ✅ Everything done automatically!

## 🔍 What Happens During Deployment

1. **Prerequisites Check**: Verifies AWS/GCP CLI configuration
2. **Infrastructure Deployment**: Creates all AWS resources
3. **Docker Build**: Builds your prediction service image
4. **Container Push**: Pushes to Google Container Registry
5. **Cloud Run Deploy**: Deploys with correct environment variables
6. **Service Testing**: Verifies all services are responding
7. **URL Display**: Shows you all service URLs

## 🛠️ Troubleshooting

### Common Issues:
- **AWS CLI not configured**: Run `aws configure`
- **GCP CLI not configured**: Run `gcloud auth login`
- **Docker not running**: Start Docker Desktop
- **Project ID wrong**: Check `terraform.tfvars`

### Logs:
```bash
# Check Terraform logs
terraform show

# Check Docker build logs
docker logs <container_id>

# Check Cloud Run logs
gcloud logging read "resource.type=cloud_run_revision"
```

This setup gives you a **production-ready MLOps platform** with one command! 🚀
