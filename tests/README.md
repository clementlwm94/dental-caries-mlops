# MLOps Platform Test Suite

Comprehensive pytest test suite for the pediatric dental caries prediction MLOps platform.

## 📁 Test Structure

```
tests/
├── conftest.py                    # Shared fixtures and configuration
├── pytest.ini                    # Pytest configuration
├── requirements.txt               # Test dependencies
├── README.md                      # This file
├── run_integration_tests.sh       # Integration test runner script
├── test_deploy_service.py         # Flask prediction service tests
├── test_ml_functions.py          # ML pipeline function tests
└── test_integration.py           # End-to-end integration tests
```

## 🚀 Quick Start

### Install Dependencies
```bash
cd tests/
pip install -r requirements.txt
```

### Run All Tests
```bash
# Run all tests with verbose output
pytest -v

# Run with coverage report
pytest --cov=../deploy_service --cov=../local-airflow/dags --cov-report=html

# Run specific test file
pytest test_deploy_service.py -v
```

## 📋 Test Categories

### 1. Deploy Service Tests (`test_deploy_service.py`)
Tests the Flask prediction API and data preprocessing:

```bash
# Run all deploy service tests
pytest test_deploy_service.py -v

# Run specific test class
pytest test_deploy_service.py::TestPreprocessFunction -v

# Run single test
pytest test_deploy_service.py::test_predict_endpoint_valid_data -v
```

**Coverage:**
- ✅ Flask route testing (index, predict endpoints)
- ✅ API input validation and error handling
- ✅ Data preprocessing and categorical encoding
- ✅ Edge cases (missing fields, invalid data)
- ✅ Integration with mocked MLflow model

### 2. ML Functions Tests (`test_ml_functions.py`)
Tests the machine learning pipeline components:

```bash
# Run all ML function tests
pytest test_ml_functions.py -v

# Run dataset creation tests
pytest test_ml_functions.py::TestCreateDataset -v

# Run preprocessing tests
pytest test_ml_functions.py::TestPreprocessPd -v
```

**Coverage:**
- ✅ Synthetic dataset creation and validation
- ✅ Data preparation (train/test split, encoding)
- ✅ Feature preprocessing and categorical handling

### 3. Integration Tests (`test_integration.py`)
Tests the complete prediction service end-to-end:

```bash
# Run integration tests
pytest test_integration.py -v -m integration

# Or use the convenient script
./run_integration_tests.sh

# Run specific integration test
pytest test_integration.py::TestPredictionServiceIntegration::test_prediction_endpoint_integration -v
```

**Coverage:**
- ✅ Service health check and startup
- ✅ HTTP API endpoint testing
- ✅ Real request/response validation
- ✅ Error handling and edge cases
- ✅ Multiple request scenarios
- ✅ Service stability testing


## 🏷️ Test Markers

Use pytest markers to run specific test categories:

```bash
# Run only unit tests
pytest -m unit

# Run only integration tests
pytest -m integration


# Skip slow tests
pytest -m "not slow"
```

## 🔧 Test Configuration

### Environment Variables
Set these for complete testing:
```bash
export MLFLOW_TRACKING_URI="http://47.129.53.131:5000"
export AWS_DEFAULT_REGION="ap-southeast-1"
```

### Mock Configuration
Tests use mocks to avoid external dependencies:
- **MLflow**: Model loading and predictions are mocked
- **AWS services**: Boto3 clients are mocked
- **External APIs**: Network calls are intercepted

## 📊 Coverage Reports

Generate coverage reports:
```bash
# HTML coverage report
pytest --cov=../deploy_service --cov=../local-airflow/dags --cov-report=html

# Terminal coverage report
pytest --cov=../deploy_service --cov=../local-airflow/dags --cov-report=term-missing

# XML coverage report (for CI/CD)
pytest --cov=../deploy_service --cov=../local-airflow/dags --cov-report=xml
```

## 🐛 Debugging Tests

### Verbose Output
```bash
# Extra verbose with full traceback
pytest -vvv --tb=long

# Show print statements
pytest -s

# Stop on first failure
pytest -x
```

### Specific Test Debugging
```bash
# Debug single test with pdb
pytest --pdb test_deploy_service.py::test_predict_endpoint_valid_data

# Show warnings
pytest --disable-warnings
```

## 🔄 Continuous Integration

### Pre-commit Testing
```bash
# Run all tests before commit
pytest

# Quick smoke test
pytest -x -q

# Focus on core functionality tests
pytest test_ml_functions.py::TestCreateDataset -v
```

### Test Data
Tests use:
- **Synthetic data**: Generated test datasets
- **Mock objects**: For external service dependencies
- **Fixtures**: Shared test data and configurations
- **Temporary files**: For file system testing

## 📈 Test Metrics

### Current Coverage
- **Deploy Service**: ~90% line coverage
- **ML Functions**: ~75% line coverage (core functions only)

### Performance
- **Unit tests**: ~2-5 seconds
- **Integration tests**: ~10-20 seconds
- **Full suite**: ~30-60 seconds

## 🛠️ Adding New Tests

### 1. Create Test File
```python
# tests/test_new_feature.py
import pytest
from unittest.mock import Mock, patch

def test_new_functionality():
    # Test implementation
    assert True
```

### 2. Use Shared Fixtures
```python
def test_with_sample_data(sample_patient_data):
    # Use fixture from conftest.py
    assert sample_patient_data['race'] == 'chinese'
```

### 3. Add Test Markers
```python
@pytest.mark.integration
@pytest.mark.slow
def test_slow_integration():
    # Long-running integration test
    pass
```

## 📚 Resources

- [Pytest Documentation](https://docs.pytest.org/)
- [Pytest-Mock Plugin](https://pytest-mock.readthedocs.io/)
- [Coverage.py Documentation](https://coverage.readthedocs.io/)
- [Flask Testing](https://flask.palletsprojects.com/en/2.3.x/testing/)

---

**Test Status**: ✅ All tests passing
**Last Updated**: July 2025
