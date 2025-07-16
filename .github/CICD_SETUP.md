# 🚀 CI/CD Setup Guide

## 📋 Prerequisites

Before the CI/CD pipelines can work, you need to configure GitHub secrets and repository settings.

## 🔐 Required GitHub Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions → New repository secret

### **Essential Secrets:**

1. **`GCP_PROJECT_ID`**
   - Value: `mlops-clementlwm` (your GCP project ID)
   - Used by: Deployment workflows

2. **`GCP_SA_KEY`**
   - Value: Your service account key JSON (entire file content)
   - Used by: Authentication to Google Cloud
   - 🚨 **CRITICAL**: Never commit this to code!

3. **`CLOUDSQL_PASSWORD`**
   - Value: Your Cloud SQL password (e.g., `MLflow2024!SecurePass`)
   - Used by: Terraform to create Cloud SQL instances

### **Optional Secrets (for advanced features):**

4. **`MLFLOW_TRACKING_URI`**
   - Value: Your MLflow server URL
   - Used by: Model training workflows (if added later)

5. **`MLFLOW_GCS_ARTIFACT_ROOT`**
   - Value: `gs://mlops-clement-artifacts/mlflow-artifacts/`
   - Used by: MLflow artifact storage

## 🛠️ How to Get Service Account Key

```bash
# 1. Create a service account (if not exists)
gcloud iam service-accounts create github-actions \
    --description="Service account for GitHub Actions" \
    --display-name="GitHub Actions"

# 2. Grant necessary permissions
gcloud projects add-iam-policy-binding mlops-clementlwm \
    --member="serviceAccount:github-actions@mlops-clementlwm.iam.gserviceaccount.com" \
    --role="roles/editor"

gcloud projects add-iam-policy-binding mlops-clementlwm \
    --member="serviceAccount:github-actions@mlops-clementlwm.iam.gserviceaccount.com" \
    --role="roles/storage.admin"

# 3. Create and download key
gcloud iam service-accounts keys create github-actions-key.json \
    --iam-account=github-actions@mlops-clementlwm.iam.gserviceaccount.com

# 4. Copy the entire content of github-actions-key.json
cat github-actions-key.json
# Copy this JSON content to GCP_SA_KEY secret

# 5. Clean up the key file (security!)
rm github-actions-key.json
```

## 🏗️ Workflow Overview

### **1. CI Workflow (`ci.yml`)**
**Triggers:** Push to main/master/develop, Pull Requests
**What it does:**
- ✅ Runs tests on Python 3.11 and 3.12
- ✅ Performs code linting and quality checks
- ✅ Scans for security vulnerabilities
- ✅ Builds Docker images to verify they work
- ✅ Generates test coverage reports

### **2. CD Workflow (`cd.yml`)**
**Triggers:** Push to main/master, Manual dispatch
**What it does:**
- 🏗️ Builds and pushes Docker images to GCR
- 🚀 Deploys infrastructure using Terraform
- 🧪 Performs health checks on deployed services
- 📊 Reports deployment status and URLs

### **3. PR Workflow (`pr.yml`)**
**Triggers:** Pull Requests
**What it does:**
- 🧹 Checks code formatting (Black, isort, flake8)
- 🧪 Runs targeted tests based on changed files
- 🐳 Validates Docker builds if Dockerfiles changed

## 🎯 Deployment Environments

### **Staging Environment**
- **Trigger:** Automatic on main branch push
- **Purpose:** Testing deployments before production
- **Infrastructure:** Full GCP setup with latest code

### **Production Environment**
- **Trigger:** Manual dispatch only
- **Purpose:** Live production system
- **Infrastructure:** Stable, manually approved deployments

## 🧪 Testing Strategy

### **Unit Tests**
- Test individual functions and components
- Run on every PR and push
- Located in `tests/` directory

### **Integration Tests**
- Test service interactions
- Validate API endpoints
- Check MLflow integration

### **Docker Tests**
- Verify container builds succeed
- Test image health and startup
- Validate service connectivity

## 🔄 Typical Workflow

1. **Development:**
   ```bash
   git checkout -b feature/new-model
   # Make changes
   git push origin feature/new-model
   # Create PR → Triggers PR checks
   ```

2. **PR Review:**
   - Automated tests run
   - Code quality checks pass
   - Manual review and approval

3. **Merge to Main:**
   - Triggers full CI pipeline
   - Automatic deployment to staging
   - Health checks verify deployment

4. **Production Deploy:**
   - Manual trigger from GitHub Actions
   - Select "production" environment
   - Deploys stable code to production

## 🚨 Security Best Practices

### **Secrets Management:**
- ✅ All sensitive data in GitHub Secrets
- ✅ Service account keys rotate regularly
- ✅ Minimum required permissions
- ✅ No secrets in code or logs

### **Access Control:**
- ✅ Protected main branch
- ✅ Required PR reviews
- ✅ Manual production deployments
- ✅ Environment-specific approvals

## 📊 Monitoring & Alerts

### **GitHub Actions:**
- 📧 Email notifications on failures
- 📱 Slack integration (optional)
- 📊 Workflow status badges

### **GCP Monitoring:**
- 📈 Cloud Run service metrics
- 🚨 Error rate alerts
- 💰 Cost monitoring

## 🎯 Next Steps After Setup

1. **Test the Pipeline:**
   - Make a small change and push
   - Verify CI workflow runs
   - Check deployment to staging

2. **Set Up Branch Protection:**
   - Require PR reviews
   - Require status checks to pass
   - Restrict direct pushes to main

3. **Configure Notifications:**
   - Set up Slack/email alerts
   - Configure failure notifications
   - Monitor deployment status

4. **Add More Environments:**
   - Development environment
   - User acceptance testing (UAT)
   - Regional deployments

## 🆘 Troubleshooting

### **Common Issues:**

**Authentication Errors:**
- Check GCP_SA_KEY secret format
- Verify service account permissions
- Ensure project ID is correct

**Terraform Failures:**
- Check terraform.tfvars generation
- Verify Cloud SQL password secret
- Ensure GCP APIs are enabled

**Docker Build Failures:**
- Check Dockerfile syntax
- Verify base image availability
- Review dependency installations

**Test Failures:**
- Check test dependencies
- Verify test data availability
- Review environment setup

### **Debug Commands:**
```bash
# Check workflow runs
gh workflow list
gh run list --workflow=ci.yml

# View specific run
gh run view <run-id>

# Re-run failed jobs
gh run rerun <run-id>
```

This CI/CD setup provides a robust, production-ready pipeline for your MLOps project! 🎉
