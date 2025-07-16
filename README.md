# 🦷 Dental Caries Prediction MLOps Project

A complete MLOps pipeline for predicting dental caries using machine learning, deployed on Google Cloud Platform with MLflow for experiment tracking and model management.

## 🎯 Problem Statement

This system predicts the likelihood of dental caries in children based on:
- **Demographics**: Age, race, gender
- **Socioeconomic factors**: Household income, mother's education and occupation
- **Health indicators**: Breastfeeding duration, delivery type, maternal smoking, feeding habits

## 🏗️ Architecture Overview

This project implements a full MLOps pipeline with:
- **MLflow Server** on Google Cloud Run for experiment tracking and model registry
- **Google Cloud SQL** (PostgreSQL) for MLflow metadata storage
- **Google Cloud Storage** for MLflow artifact storage
- **Prediction Service** on Google Cloud Run for model serving
- **Apache Airflow** for ML pipeline orchestration
- **Terraform** for Infrastructure as Code (IaC)

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Airflow DAG   │───▶│  MLflow Server  │───▶│ Prediction API  │
│  (Training)     │    │  (Tracking)     │    │   (Serving)     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Cloud Storage  │    │   Cloud SQL     │    │  Cloud Storage  │
│  (Artifacts)    │    │  (Metadata)     │    │  (Models)       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 📁 Project Structure

### 🎯 **Core Folders (Important)**

```
📦 mlops_project/
├── 🏗️ terraform/                    # Infrastructure as Code
│   ├── main.tf                     # GCP infrastructure definition
│   ├── terraform.tfvars.example    # Configuration template
│   ├── deploy-complete.sh          # Full deployment script
│   ├── deploy-prediction-service.sh # Prediction service deployment
│   ├── Dockerfile.mlflow          # MLflow server container
│   └── start-mlflow.sh            # MLflow startup script
│
├── 🔄 local-airflow/              # ML Pipeline Orchestration
│   ├── dags/
│   │   ├── ml_function.py         # Core ML training functions
│   │   └── test.py               # Training DAG definition
│   ├── docker-compose.yml        # Local Airflow setup
│   ├── requirements.txt          # Python dependencies
│   └── .env                     # Environment configuration
│
├── 🤖 deploy_service/             # Model Serving API
│   ├── service_test.py           # Flask prediction API
│   ├── predict_function.py       # Model prediction logic
│   ├── Dockerfile               # Prediction service container
│   ├── pyproject.toml          # Dependencies and config
│   └── templates/
│       └── index.html          # Web interface
│
└── 🧪 tests/                     # Testing
    ├── test_deploy_service.py    # API tests
    ├── test_ml_functions.py      # ML pipeline tests
    └── test_integration.py       # Integration tests
```

### 📂 **Supporting Folders**

- `project_archive/` - Legacy AWS implementation (archived)
- `google-mlflow/` - Alternative MLflow setup (not used)
- `.env.template` - Environment variables template

## 🚀 Quick Start Guide

### Prerequisites

1. **Google Cloud Platform Account**
   - Create a GCP project
   - Enable billing
   - Install `gcloud` CLI and authenticate

2. **Required Tools**
   - Docker
   - Terraform
   - Python 3.11+

### Step 1: Clone and Configure

```bash
# Clone the repository
git clone <your-repo-url>
cd mlops_project

# Configure Terraform
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your GCP project ID and secure database password
```

### Step 2: Deploy Infrastructure + MLflow

```bash
# Deploy MLflow server and infrastructure
./deploy-complete.sh
```

This will create:
- Google Cloud SQL PostgreSQL database
- Google Cloud Storage bucket
- MLflow server on Cloud Run
- Service accounts and IAM permissions

### Step 3: Train Your Model

```bash
# Configure local Airflow for training
cd ../local-airflow

# Update .env with your MLflow URL (from step 2 output)
# Start Airflow
docker-compose up -d

# Access Airflow UI at http://localhost:8080
# Run the 'ml_pipeline_dag' to train and register your model
```

### Step 4: Deploy Prediction Service

```bash
# After model is trained and registered
cd ../terraform
./deploy-prediction-service.sh
```

### Step 5: Test Your API

```bash
# Test the prediction endpoint
curl -X POST <prediction-service-url>/predict \
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

## 🔧 **Alternative: Manual Deployment (Legacy)**

<details>
<summary>Click to expand manual deployment steps</summary>

### 1. Deploy MLflow Infrastructure Manually
```bash
cd aws-ecs/
./deploy-mlflow.sh
```

### 2. Deploy Prediction Service Manually
```bash
cd deploy_service/
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
gcloud auth configure-docker

gcloud run deploy dental-prediction \
  --source . \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --port 9696
```

### 3. Update Environment Variables Manually
```bash
# Edit .env file with correct MLflow URL
# Edit local-airflow/.env file
```

### 4. Start Airflow
```bash
cd local-airflow/
./start-airflow.sh
```

</details>

## 🧹 **Cleanup**

### Remove All Infrastructure
```bash
cd terraform/
./destroy.sh
```

This will:
- Delete Google Cloud Run service
- Remove container images
- Destroy all AWS infrastructure (RDS, S3, ECS, VPC)
- Clean up everything safely

## 📁 Project Structure

```
├── terraform/                   # 🏗️ Infrastructure as Code (NEW!)
│   ├── main.tf                  # Main infrastructure definition
│   ├── deploy-complete.sh       # One-command deployment
│   ├── destroy.sh               # Complete cleanup
│   ├── update-env.sh            # Auto-update .env files
│   ├── get-mlflow-url.sh        # Get MLflow URL from Terraform
│   ├── terraform.tfvars.example # Configuration template
│   └── README.md                # Terraform documentation
├── aws-ecs/                     # ☁️ AWS MLflow Deployment (Legacy)
│   ├── deploy-mlflow.sh         # Manual ECS deployment script
│   ├── Dockerfile.mlflow        # MLflow server container
│   └── mlflow-task-definition.json # ECS task configuration
├── deploy_service/              # 🌐 Model Serving API
│   ├── service_test.py          # Flask web application
│   ├── predict_function.py      # ML inference logic
│   ├── Dockerfile               # Service containerization
│   ├── pyproject.toml           # Python dependencies
│   └── templates/index.html     # Web interface
├── local-airflow/               # 🔄 ML Pipeline Orchestration
│   ├── docker-compose.yml       # Airflow services setup
│   ├── requirements.txt         # ML dependencies
│   ├── start-airflow.sh         # Startup script (auto-loads .env)
│   └── dags/                    # ML pipeline definitions
│       ├── test.py              # Training pipeline
│       ├── dag_monitoring_pipeline.py # Model monitoring
│       └── ml_function.py       # Shared utilities
├── .env                         # Environment variables (auto-updated)
├── .env.template                # Environment template
└── .gitignore                   # Git ignore patterns
```

## 🆕 **What's New: Infrastructure as Code**

### Key Improvements:
- **🚀 One-Command Deployment**: Deploy everything with `./deploy-complete.sh`
- **🔄 Auto Environment Updates**: `.env` files updated automatically with correct MLflow URLs
- **🏗️ Infrastructure as Code**: Version-controlled, reproducible infrastructure
- **🧹 Easy Cleanup**: Remove everything with `./destroy.sh`
- **🔒 Security**: Proper VPC, security groups, and IAM roles
- **📊 Monitoring**: CloudWatch logging and health checks

### Benefits:
- **Faster Setup**: From 30+ minutes to 5 minutes
- **No Manual Errors**: Automated environment configuration
- **Reproducible**: Identical infrastructure every time
- **Cost Efficient**: Easy to spin up/down environments
- **Team Collaboration**: Infrastructure changes tracked in Git

## 🔧 Components Deep Dive

### Infrastructure (`terraform/`)
- **AWS Multi-AZ**: VPC with public/private subnets
- **ECS Fargate**: Serverless MLflow tracking server
- **RDS PostgreSQL**: Managed database for MLflow metadata
- **S3 Bucket**: Secure artifact storage with versioning
- **Google Cloud Run**: Auto-scaling prediction service
- **Security**: IAM roles, security groups, encryption

### ML Training Pipeline (`local-airflow/`)
- **Orchestration**: Apache Airflow with CeleryExecutor
- **Algorithm**: XGBoost with Optuna hyperparameter optimization
- **Data**: Synthetic pediatric health dataset generation
- **Tracking**: Comprehensive experiment logging to cloud MLflow
- **Optimization**: 3-10 trials of hyperparameter tuning per run

### Cloud MLflow (`aws-ecs/`)
- **Infrastructure**: AWS ECS Fargate (serverless containers)
- **Database**: PostgreSQL RDS for experiment metadata
- **Storage**: S3 bucket for model artifacts and data
- **Region**: ap-southeast-1 (Singapore)
- **Security**: VPC with security groups, IAM roles

### Model Serving (`deploy_service/`)
- **Framework**: Flask with Gunicorn WSGI server
- **Model Loading**: Direct integration with MLflow model registry
- **Interface**: Modern responsive web UI with real-time predictions
- **API**: RESTful `/predict` endpoint accepting JSON payloads
- **Deployment**: Google Cloud Run for auto-scaling serverless deployment
- **Production URL**: `https://ml-service-605659872031.us-central1.run.app` ✅

### Monitoring Pipeline
- **Tool**: Evidently AI for ML observability
- **Metrics**: Data drift, model performance, accuracy tracking
- **Visualization**: Cloud dashboard for real-time monitoring
- **Alerts**: Automated drift detection and performance degradation

## 🛠️ API Usage

### Web Interface
Navigate to `https://ml-service-605659872031.us-central1.run.app` and fill out the patient information form.

### REST API
```bash
curl -X POST https://ml-service-605659872031.us-central1.run.app/predict \
  -H "Content-Type: application/json" \
  -d '{
    "race": "chinese",
    "age": 30,
    "gender": "male",
    "breast_feeding_month": 12,
    "mother_occupation": "professional",
    "household_income": ">=4000",
    "mother_edu": "university",
    "delivery_type": "normal",
    "smoke_mother": "No",
    "night_bottle_feeding": "No"
  }'
```

**Response:**
```json
{
  "prediction": 0,
  "status": "success"
}
```

## 📊 Model Features

### Input Features
| Feature | Type | Values |
|---------|------|--------|
| `race` | Categorical | chinese, malay, indian |
| `age` | Numeric | Patient age in years |
| `gender` | Categorical | male, female |
| `breast_feeding_month` | Numeric | Duration of breastfeeding |
| `mother_occupation` | Categorical | professional, non-professional |
| `household_income` | Categorical | <4000, >=4000 |
| `mother_edu` | Categorical | no education, primary/secondary, university |
| `delivery_type` | Categorical | normal, not normal |
| `smoke_mother` | Categorical | No, Yes |
| `night_bottle_feeding` | Categorical | No, Yes |

### Output
- **Prediction**: Binary classification (0 = No caries, 1 = Caries likely)
- **Probability**: Confidence score for the prediction

## 🔍 Monitoring & Observability

### MLflow Tracking
- **Experiments**: Organized by pipeline runs
- **Metrics**: ROC AUC, accuracy, precision, recall
- **Parameters**: All hyperparameters logged automatically
- **Artifacts**: Models, plots, and metadata stored in S3

### Model Monitoring
- **Data Drift**: Feature distribution changes over time
- **Performance Monitoring**: Model accuracy degradation detection
- **Dashboard**: Real-time visualization in Evidently Cloud

### Health Checks
- **MLflow**: `http://47.129.53.131:5000/health`
- **Prediction Service**: `https://ml-service-605659872031.us-central1.run.app/` (should return web page)
- **Airflow**: `http://localhost:8080/health`

## 🚀 Production Deployment

### Google Cloud Run (Primary)
The prediction service is designed for Google Cloud Run deployment:

```bash
cd deploy_service/
# Setup Google Cloud project
gcloud auth login
gcloud config set project YOUR_PROJECT_ID

# Deploy to Cloud Run
gcloud run deploy dental-prediction \
  --source . \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --port 9696
```

### Benefits of Google Cloud Run:
- **Auto-scaling**: Scales to zero when not in use
- **Pay-per-request**: Only pay for actual usage
- **Global deployment**: Deploy to multiple regions
- **No server management**: Fully managed serverless platform

### Alternative Deployment
For local development only:
```bash
docker build -t dental-prediction .
docker run -p 9696:9696 dental-prediction
```

## 🔒 Security & Configuration

### Environment Variables
- `MLFLOW_TRACKING_URI`: MLflow server endpoint
- `AWS_ACCESS_KEY_ID`: AWS credentials for S3 access
- `AWS_SECRET_ACCESS_KEY`: AWS secret key
- `AWS_DEFAULT_REGION`: AWS region (ap-southeast-1)

### Security Features
- **MLflow**: Secure S3 artifact storage with IAM roles
- **API**: Input validation and error handling
- **Infrastructure**: VPC isolation and security groups
- **Secrets**: AWS Systems Manager for credential management

## 🧪 Development & Testing

### Running Automated Tests

All tests are centralized in the `tests/` folder for easy management:

#### Quick Start
```bash
cd tests/
# Install test dependencies
pip install -r requirements.txt

# Run all tests
pytest -v

# Run with coverage report
pytest --cov=../deploy_service --cov=../local-airflow/dags --cov-report=html
```

#### Specific Test Categories
```bash
cd tests/

# 1. Deploy Service Tests (Flask API)
pytest test_deploy_service.py -v

# 2. ML Functions Tests (Pipeline components)
pytest test_ml_functions.py -v

# Run specific test classes
pytest test_deploy_service.py::TestPreprocessFunction -v
pytest test_ml_functions.py::TestCreateDataset -v
pytest test_ml_functions.py::TestPrepareDataFunction -v
```

#### 3. Integration Testing
```bash
cd tests/

# Run integration tests (starts Flask service automatically)
pytest test_integration.py -v -m integration

# Or use the convenient script
./run_integration_tests.sh

# Run specific integration test
pytest test_integration.py::TestPredictionServiceIntegration::test_prediction_endpoint_integration -v
```

#### 4. Manual Service Testing
```bash
# Start all services
cd local-airflow && ./start-airflow.sh

# Trigger test DAG in Airflow UI
# Monitor at http://localhost:8080

# Test production prediction service API
curl -X POST https://ml-service-605659872031.us-central1.run.app/predict \
  -H "Content-Type: application/json" \
  -d '{"race":"chinese","age":25,"gender":"female","breast_feeding_month":6,"mother_occupation":"professional","household_income":">=4000","mother_edu":"university","delivery_type":"normal","smoke_mother":"No","night_bottle_feeding":"No"}'
```

### Test Coverage

#### Deploy Service Tests (`test_deploy_service.py`):
- ✅ **Flask routes**: Index and prediction endpoints
- ✅ **API validation**: Input validation and error handling
- ✅ **Data preprocessing**: Categorical encoding and validation
- ✅ **Edge cases**: Missing fields, invalid data types
- ✅ **Integration**: Full prediction pipeline testing

#### ML Functions Tests (`test_ml_functions.py`):
- ✅ **Data generation**: Synthetic dataset creation and validation
- ✅ **Data preparation**: Train/test splitting and target encoding
- ✅ **Preprocessing**: Categorical handling and unknown values

### Test Organization
```
tests/
├── conftest.py                    # Shared fixtures and configuration
├── pytest.ini                    # Pytest configuration
├── requirements.txt               # Test dependencies
├── README.md                      # Detailed testing documentation
├── run_integration_tests.sh       # Integration test runner script
├── test_deploy_service.py         # Flask API unit tests
├── test_ml_functions.py          # ML pipeline unit tests
└── test_integration.py           # End-to-end integration tests
```

### Continuous Integration

Run all tests before deployment:
```bash
# Test all components from centralized location
cd tests/

# 1. Run unit tests (fast)
pytest test_deploy_service.py test_ml_functions.py -v

# 2. Run integration tests (slower, but comprehensive)
pytest test_integration.py -v -m integration

# 3. Run all tests with coverage
pytest --cov=../deploy_service --cov=../local-airflow/dags --cov-report=term-missing

# Quick smoke test (stop on first failure)
pytest -x

# If all tests pass, deploy:
cd ../aws-ecs && ./deploy-mlflow.sh
cd ../local-airflow && ./start-airflow.sh
cd ../deploy_service && gcloud run deploy dental-prediction --source .
```

### Model Development
1. Modify ML pipeline in `local-airflow/dags/ml_function.py`
2. Update hyperparameter ranges in training functions
3. Test locally before deploying to production
4. Monitor experiments in MLflow UI

## 📈 Performance & Scaling

### Current Performance
- **Model Training**: ~30 seconds per hyperparameter trial
- **Inference**: <100ms per prediction
- **Throughput**: 1000+ predictions/minute
- **Model Accuracy**: ROC AUC ~0.58-0.70 on synthetic data

### Scaling Options
- **Horizontal**: Multiple ECS tasks behind load balancer
- **Vertical**: Increase container resources
- **Caching**: Redis for frequent predictions
- **Batch**: Process multiple predictions simultaneously

## 🔧 Troubleshooting

### Common Issues

**Terraform Deployment Errors:**
- Verify AWS CLI: `aws sts get-caller-identity`
- Verify GCP CLI: `gcloud auth list`
- Check terraform.tfvars configuration
- Ensure Docker is running for image build

**MLflow Connection Errors:**
- Check MLflow URL: `cd terraform && ./get-mlflow-url.sh`
- Verify .env file updated: `grep MLFLOW_TRACKING_URI .env`
- Test connection: `curl YOUR_MLFLOW_URL/`
- Check ECS service status in AWS console

**Model Loading Failures:**
- Confirm "champion" model exists in registry
- Check S3 bucket permissions
- Verify MLflow tracking URI in .env files

**Airflow DAG Failures:**
- Check Airflow logs: `docker-compose logs`
- Verify Python dependencies in requirements.txt
- Ensure sufficient Docker resources
- Restart Airflow after infrastructure changes

**Cloud Run Deployment Issues:**
- Verify GCP project ID in terraform.tfvars
- Check container image exists in GCR
- Ensure Cloud Run API is enabled
- Check service logs: `gcloud logging read "resource.type=cloud_run_revision"`

### Logs & Debugging
```bash
# Terraform logs
cd terraform && terraform show

# Airflow logs
cd local-airflow && docker-compose logs -f

# MLflow logs (AWS CloudWatch)
aws logs tail /ecs/mlflow-server --follow --region ap-southeast-1

# Cloud Run logs
gcloud logging read "resource.type=cloud_run_revision" --limit 50

# Get service status
cd terraform && terraform output
```

### Quick Fixes
```bash
# Reset everything and start fresh
cd terraform && ./destroy.sh
cd terraform && ./deploy-complete.sh

# Update .env files manually
cd terraform && ./update-env.sh

# Just get the MLflow URL
cd terraform && ./get-mlflow-url.sh
```


**Project Status**: ✅ Production Ready
**Last Updated**: July 2025
