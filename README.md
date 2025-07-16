# 🦷 Dental Caries Prediction MLOps Project

A MLOps pipeline for predicting dental caries using machine learning, deployed on Google Cloud Platform with MLflow for experiment tracking and model management,featuring cloud-native deployment, automated training, and real-time inference.

## 🎯 Problem Statement

The study is come form Singapore cohort study "Growing Up in Singapore Towards healthy Outcomes" (GUSTO) birth cohort study. GUSTO is a longitudinal study, meaning it follows children and their families over time, allowing researchers to track the progression of dental health and identify risk factors. In this project, I use the simulated data to build a machine learning model for predicting dental caries.

This system predicts the likelihood of dental caries in children based on:

Demographics: Age, race, gender
Socioeconomic factors: Household income, mother's education and occupation
Health indicators: Breastfeeding duration, delivery type, maternal smoking, feeding habits
(Plese note that the original dataset contains 1000+ features, I just extract few feature for this simulated project)

## 🏗️ Architecture Overview

This project implements a full MLOps pipeline with:
- **MLflow Server** on Google Cloud Run for experiment tracking and model registry
- **Google Cloud SQL** (PostgreSQL) for MLflow metadata storage
- **Google Cloud Storage** for MLflow artifact storage
- **Prediction Service** on Google Cloud Run for model serving
- **Apache Airflow** for ML pipeline orchestration
- **Terraform** for Infrastructure as Code (IaC)

<img width="580" height="663" alt="image" src="https://github.com/user-attachments/assets/11d0a343-920a-48e1-a3ef-779ad8b7544e" />


## 🚀 Quick Start Guide

### Prerequisites

1. **Google Cloud Platform Account**
   - Create a GCP project
   - Install `gcloud` CLI and authenticate
   - Create service account
   - Create Evidently AI account

2. **Required Tools**
   - Docker
   - Terraform
   - Python 3.11+
   - Mlflow
   - Airflow
   - Evindently AI

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
<img width="1899" height="729" alt="image" src="https://github.com/user-attachments/assets/4a3612e2-4059-453b-a19b-4c7523282e4a" />


### Step 3: Train Your Model

```bash
# Configure local Airflow for training
cd ../local-airflow

# Update .env with your MLflow URL (from step 2 output)
# Start Airflow
docker-compose up -d
```
- Access Airflow UI at http://localhost:8080
- Run the 'ml_pipeline_dag' to train and register your model 
<img width="1816" height="904" alt="image" src="https://github.com/user-attachments/assets/f10d99a2-fb36-4d86-ad84-0d6ff5a82deb" />



### Step 4: Deploy Prediction Service

```bash
# After model is trained and registered
cd ../terraform
./deploy-prediction-service.sh
```
After the deployment, you will have the Prediction Service url, you could use this website to predict whether the child will have caries by filling up the form

<img width="536" height="909" alt="image" src="https://github.com/user-attachments/assets/00e87c26-8f50-407e-bc1a-75234a5853dd" />


## 🧹 **Cleanup**

### Remove All Infrastructure
```bash
cd terraform/
./destroy.sh
```

This will:
- Delete Google Cloud Run service
- Remove container images
- Destroy all Google cloud infrastructure
- Clean up everything safely

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
```

# Project Progress
- ✅ **Cloud**: Synthetic dataset creation and validation
- ✅ **Experiment tracking and model registry**: Synthetic dataset creation and validation
- ✅ **Experiment tracking and model registry**: Both experiment tracking and model registry are used
- ✅ **Experiment tracking and model registry**: Fully deployed workflow
- ✅ **Model deployment**: The model deployment code is containerized and could be deployed to cloud or special tools for model deployment are used
- ✅ **Model monitoring**: Comprehensive model monitoring that sends alerts if the defined metrics threshold is violated
- ✅ **unit tests**
- ✅ **integration test**
- ✅ **Linter and/or code formatter**
- ✅ **pre-commit hooks**
- ✅ **CI/CD pipeline**
