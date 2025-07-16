import logging
from typing import List, Optional, Union

import mlflow
import mlflow.sklearn
import mlflow.xgboost
import numpy as np
import pandas as pd

logger = logging.getLogger(__name__)


def preprocess_pd(dat):
    categorical_levels = {
        "race": ["chinese", "malay", "indian"],
        "gender": ["male", "female"],
        "mother_occupation": ["professional", "non-professional"],
        "household_income": ["<4000", ">=4000"],
        "mother_edu": ["no education", "primary/secondary", "university"],
        "delivery_type": ["normal", "not normal"],
        "smoke_mother": ["No", "Yes"],
        "night_bottle_feeding": ["No", "Yes"],
    }
    # Convert categorical columns with predefined levels
    for col, categories in categorical_levels.items():
        if col in dat.columns:
            # Create categorical with specific categories to match training data
            dat[col] = pd.Categorical(dat[col], categories=categories)

            # Check for unknown categories
            unknown_values = dat[col].isna()
            if unknown_values.any():
                unknown_vals = dat.loc[unknown_values, col].unique()
                logger.warning(f"Unknown categories in column '{col}': {unknown_vals}")
                # You might want to handle this by either:
                # 1. Raising an error
                # 2. Setting to a default category
                # 3. Using the most frequent category
    return dat


class xgb_model:
    """
    A class to load XGBoost models from MLflow and make predictions.
    """

    def __init__(self, model_name, model_version):
        """
        Initialize the MLflow XGBoost predictor.

        Args:
            model_name (str, optional): Name of the registered model in MLflow
            model_version (str, optional): Version alias (e.g., "champion", "latest") or version number
        """
        self.model = None
        self.model_name = model_name
        self.model_version = model_version
        self.is_loaded = False

        self.load_model(model_name, model_version)

    def load_model(self, model_name: str, model_version: str) -> None:
        """
        Load XGBoost model from MLflow model registry.

        Args:
            model_name (str): Name of the registered model in MLflow
            model_version (str): Version alias (e.g., "champion", "latest") or version number
        """
        try:
            # Construct model URI
            model_uri = f"models:/{model_name}@{model_version}"

            # Load the model from MLflow
            self.model = mlflow.sklearn.load_model(model_uri)

            self.model_name = model_name
            self.model_version = model_version
            self.is_loaded = True

            logger.info(f"Model loaded successfully from MLflow: {model_uri}")

        except Exception as e:
            logger.error(f"Failed to load model {model_name}@{model_version}: {str(e)}")
            raise

    def predict(self, dat: pd.DataFrame) -> np.ndarray:
        """
        Make predictions using the loaded XGBoost model.

        Args:
            dat: Input features as pandas DataFrame (will be modified in-place)

        Returns:
            np.ndarray: Binary predictions (True/False)
        """
        if not self.is_loaded:
            raise ValueError("Model not loaded. Call load_model() first.")

        try:
            dat_tmp = dat.copy()
            dat_tmp = preprocess_pd(dat_tmp)
            # Get prediction probabilities and make binary predictions
            dat_tmp["predict_proba"] = self.model.predict_proba(dat_tmp)[:, 1]
            dat_tmp["prediction"] = (dat_tmp["predict_proba"] > 0.5).astype(int)

            return dat_tmp

        except Exception as e:
            logger.error(f"Prediction failed: {str(e)}")
            raise ValueError("Not able to predict outcome")
