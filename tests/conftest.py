"""
Shared pytest configuration and fixtures
"""

import os
import sys
from unittest.mock import Mock

import pandas as pd
import pytest

# Add project paths to sys.path for imports
PROJECT_ROOT = os.path.dirname(os.path.dirname(__file__))
sys.path.insert(0, os.path.join(PROJECT_ROOT, "deploy_service"))
sys.path.insert(0, os.path.join(PROJECT_ROOT, "local-airflow", "dags"))


@pytest.fixture
def sample_patient_data():
    """Sample patient data for testing"""
    return {
        "race": "chinese",
        "age": 30,
        "gender": "male",
        "breast_feeding_month": 12,
        "mother_occupation": "professional",
        "household_income": ">=4000",
        "mother_edu": "university",
        "delivery_type": "normal",
        "smoke_mother": "No",
        "night_bottle_feeding": "No",
    }


@pytest.fixture
def sample_dataset():
    """Sample dataset DataFrame for testing"""
    data = [
        {
            "race": "chinese",
            "age": 30,
            "gender": "male",
            "breast_feeding_month": 12,
            "mother_occupation": "professional",
            "household_income": ">=4000",
            "mother_edu": "university",
            "delivery_type": "normal",
            "smoke_mother": "No",
            "night_bottle_feeding": "No",
            "caries": "No",
        },
        {
            "race": "malay",
            "age": 25,
            "gender": "female",
            "breast_feeding_month": 6,
            "mother_occupation": "non-professional",
            "household_income": "<4000",
            "mother_edu": "primary/secondary",
            "delivery_type": "not normal",
            "smoke_mother": "Yes",
            "night_bottle_feeding": "Yes",
            "caries": "Yes",
        },
    ]
    return pd.DataFrame(data)


@pytest.fixture
def mock_mlflow_model():
    """Mock MLflow model for testing"""
    mock_model = Mock()
    mock_model.predict_proba.return_value = [[0.3, 0.7], [0.8, 0.2]]
    mock_model.predict.return_value = [1, 0]
    return mock_model
