"""
Pytest tests for ML pipeline functions
"""

import os
import sys
from unittest.mock import Mock, patch

import numpy as np
import pandas as pd
import pytest

# Add the dags directory to the path so we can import ml_function
sys.path.insert(
    0, os.path.join(os.path.dirname(__file__), "..", "local-airflow", "dags")
)

from ml_function import create_dataset, prepare_data_function, preprocess_pd


class TestCreateDataset:
    """Test synthetic dataset creation"""

    def test_create_dataset_default_size(self):
        """Test dataset creation with default parameters"""
        df = create_dataset()

        assert isinstance(df, pd.DataFrame)
        assert len(df) == 1000  # Default size
        assert "caries" in df.columns  # Target column

        # Check all required columns exist
        expected_columns = [
            "race",
            "age",
            "gender",
            "breast_feeding_month",
            "mother_occupation",
            "household_income",
            "mother_edu",
            "delivery_type",
            "smoke_mother",
            "night_bottle_feeding",
            "caries",
        ]
        for col in expected_columns:
            assert col in df.columns

    def test_create_dataset_custom_size(self):
        """Test dataset creation with custom size"""
        custom_size = 500
        df = create_dataset(custom_size)

        assert len(df) == custom_size
        assert isinstance(df, pd.DataFrame)

    def test_dataset_categorical_values(self):
        """Test that categorical columns have expected values"""
        df = create_dataset(100)

        # Test categorical value ranges
        assert df["race"].isin(["chinese", "malay", "indian"]).all()
        assert df["gender"].isin(["male", "female"]).all()
        assert df["mother_occupation"].isin(["professional", "non-professional"]).all()
        assert df["household_income"].isin(["<4000", ">=4000"]).all()
        assert df["caries"].isin(["No", "Yes"]).all()

    def test_dataset_numeric_values(self):
        """Test that numeric columns have reasonable values"""
        df = create_dataset(100)

        # Age should be positive
        assert (df["age"] >= 0).all()
        # Breastfeeding months should be reasonable
        assert (df["breast_feeding_month"] >= 0).all()


class TestPrepareDataFunction:
    """Test data preparation function"""

    @pytest.fixture
    def sample_data(self):
        """Create sample data for testing"""
        return create_dataset(200)

    def test_prepare_data_function_structure(self, sample_data):
        """Test that data preparation returns correct structure"""
        result = prepare_data_function(sample_data)

        # Check return structure
        assert isinstance(result, dict)
        assert "X_train" in result
        assert "X_test" in result
        assert "y_train" in result
        assert "y_test" in result

        # Check data types
        assert isinstance(result["X_train"], pd.DataFrame)
        assert isinstance(result["X_test"], pd.DataFrame)
        assert isinstance(result["y_train"], np.ndarray)
        assert isinstance(result["y_test"], np.ndarray)

    def test_prepare_data_function_target_encoding(self, sample_data):
        """Test that target variable is properly encoded"""
        result = prepare_data_function(sample_data)

        # Target should be binary (0, 1)
        assert set(result["y_train"]).issubset({0, 1})
        assert set(result["y_test"]).issubset({0, 1})

    def test_prepare_data_function_no_target_leakage(self, sample_data):
        """Test that target column is not in features"""
        result = prepare_data_function(sample_data)

        # 'caries' should not be in X_train or X_test
        assert "caries" not in result["X_train"].columns
        assert "caries" not in result["X_test"].columns

    def test_prepare_data_function_train_test_split(self, sample_data):
        """Test train/test split proportions"""
        result = prepare_data_function(sample_data)

        total_samples = len(sample_data)
        train_samples = len(result["X_train"])
        test_samples = len(result["X_test"])

        # Should be roughly 80/20 split
        assert abs(train_samples / total_samples - 0.8) < 0.05
        assert abs(test_samples / total_samples - 0.2) < 0.05

        # Total should match original
        assert train_samples + test_samples == total_samples


class TestPreprocessPd:
    """Test preprocessing function"""

    @pytest.fixture
    def sample_raw_data(self):
        """Create sample raw data"""
        return pd.DataFrame(
            [
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
                }
            ]
        )

    def test_preprocess_pd_categorical_conversion(self, sample_raw_data):
        """Test categorical conversion"""
        result = preprocess_pd(sample_raw_data.copy())

        categorical_columns = [
            "race",
            "gender",
            "mother_occupation",
            "household_income",
            "mother_edu",
            "delivery_type",
            "smoke_mother",
            "night_bottle_feeding",
        ]

        for col in categorical_columns:
            if col in result.columns:
                assert result[col].dtype.name == "category"

    def test_preprocess_pd_unknown_categories(self):
        """Test handling of unknown categories"""
        data = pd.DataFrame(
            [
                {
                    "race": "unknown_race",
                    "age": 30,
                    "gender": "unknown_gender",
                    "breast_feeding_month": 12,
                    "mother_occupation": "unknown_job",
                    "household_income": "unknown_income",
                    "mother_edu": "unknown_edu",
                    "delivery_type": "unknown_delivery",
                    "smoke_mother": "unknown",
                    "night_bottle_feeding": "unknown",
                }
            ]
        )

        # Should handle gracefully without crashing
        result = preprocess_pd(data.copy())
        assert isinstance(result, pd.DataFrame)
        assert len(result) == 1


if __name__ == "__main__":
    pytest.main([__file__])
