"""
ML Pipeline Utility Functions
Contains reusable functions for data processing and model training
"""

import logging
import os
import pickle

import mlflow
import mlflow.xgboost
import numpy as np
import optuna
import pandas as pd
import xgboost as xgb
from dotenv import load_dotenv
from evidently import BinaryClassification, DataDefinition, Dataset, Report
from evidently.metrics import *
from evidently.presets import ClassificationPreset, DataDriftPreset, DataSummaryPreset
from evidently.sdk.models import PanelMetric
from evidently.sdk.panels import DashboardPanelPlot
from evidently.ui.workspace import CloudWorkspace
from mlflow.models import infer_signature
from sklearn.metrics import roc_auc_score
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder

# Load environment variables
load_dotenv()
logger = logging.getLogger(__name__)


def create_dataset(n_samples=1000):
    """Create synthetic dataset for ML pipeline"""
    data_dict = {
        "race": ["chinese", "malay", "indian"],
        "gender": ["male", "female"],
        "mother_occupation": ["professional", "non-professional"],
        "household_income": ["<4000", ">=4000"],
        "mother_edu": ["no education", "primary/secondary", "university"],
        "delivery_type": ["normal", "not normal"],
        "smoke_mother": ["No", "Yes"],
        "night_bottle_feeding": ["No", "Yes"],
        "caries": ["No", "Yes"],
    }

    random_df = pd.DataFrame(
        {
            "race": np.random.choice(data_dict["race"], n_samples),
            "age": np.random.poisson(30, n_samples),
            "gender": np.random.choice(data_dict["gender"], n_samples),
            "breast_feeding_month": np.random.poisson(12, n_samples),
            "mother_occupation": np.random.choice(
                data_dict["mother_occupation"], n_samples
            ),
            "household_income": np.random.choice(
                data_dict["household_income"], n_samples
            ),
            "mother_edu": np.random.choice(data_dict["mother_edu"], n_samples),
            "delivery_type": np.random.choice(data_dict["delivery_type"], n_samples),
            "smoke_mother": np.random.choice(data_dict["smoke_mother"], n_samples),
            "night_bottle_feeding": np.random.choice(
                data_dict["night_bottle_feeding"], n_samples
            ),
            "caries": np.random.choice(data_dict["caries"], n_samples),
        }
    )
    return random_df


def prepare_data_function(dat):
    """Prepare data for training - split into train/test and encode target"""
    target_column = "caries"
    X = dat.drop(columns=[target_column])
    y = dat[target_column]
    target_encoder = LabelEncoder()
    y_encoded = target_encoder.fit_transform(y)

    # Convert integer columns to float to handle missing values
    integer_columns = X.select_dtypes(include=["int64", "int32"]).columns
    X[integer_columns] = X[integer_columns].astype("float64")

    X_train, X_test, y_train, y_test = train_test_split(
        X, y_encoded, test_size=0.2, random_state=42, stratify=y_encoded
    )

    return {"X_train": X_train, "X_test": X_test, "y_train": y_train, "y_test": y_test}


def train_xgboost_with_optuna(
    X_train,
    y_train,
    X_test,
    y_test,
    mlflow_uri=None,
    experiment_name="ml_pipeline_experiment",
    n_trials=50,
):
    """
    Train XGBoost with Optuna hyperparameter optimization

    Args:
        X_train: Training features
        y_train: Training target
        X_test: Test features
        y_test: Test target
        mlflow_uri: MLflow tracking server URI
        experiment_name: MLflow experiment name
        n_trials: Number of Optuna trials

    Returns:
        Best ROC AUC score from optimization
    """

    # Set MLflow tracking - use environment variable if mlflow_uri not provided
    if mlflow_uri is None:
        mlflow_uri = os.getenv("MLFLOW_TRACKING_URI", "http://localhost:5000")

    mlflow.set_tracking_uri(mlflow_uri)
    print(f"Using MLflow URI: {mlflow_uri}")

    # Create or get experiment with GCS artifact location
    try:
        # Use GCS artifact location from environment variable
        gcs_artifact_root = os.getenv(
            "MLFLOW_GCS_ARTIFACT_ROOT", "gs://mlops-clement-artifacts/mlflow-artifacts/"
        )
        experiment_id = mlflow.create_experiment(
            name=experiment_name, artifact_location=gcs_artifact_root
        )
        mlflow.set_experiment(experiment_name)
    except Exception:
        # Experiment already exists, continue
        experiment = mlflow.get_experiment_by_name(experiment_name)
        if experiment:
            experiment_id = experiment.experiment_id
            mlflow.set_experiment(experiment_name)
        else:
            raise Exception("Failed to create or find experiment")

    def objective_xgboost(trial):
        """Objective function for XGBoost hyperparameter tuning"""
        params = {
            "n_estimators": trial.suggest_int("n_estimators", 50, 300),
            "max_depth": trial.suggest_int("max_depth", 3, 10),
            "learning_rate": trial.suggest_float("learning_rate", 0.01, 0.3),
            "subsample": trial.suggest_float("subsample", 0.6, 1.0),
            "colsample_bytree": trial.suggest_float("colsample_bytree", 0.6, 1.0),
            "reg_alpha": trial.suggest_float("reg_alpha", 0, 10),
            "reg_lambda": trial.suggest_float("reg_lambda", 0, 10),
            "random_state": 42,
        }

        with mlflow.start_run(experiment_id=experiment_id) as run:
            xgb_model = xgb.XGBClassifier(**params, enable_categorical=True)
            xgb_model.fit(X_train, y_train)
            y_predict = xgb_model.predict_proba(X_test)[:, 1]

            roc_auc = roc_auc_score(y_true=y_test, y_score=y_predict)

            # Manual logging of hyperparameters
            for param_name, param_value in params.items():
                mlflow.log_param(param_name, param_value)

            # Log metrics
            mlflow.log_metric("roc_auc", roc_auc)
            mlflow.set_tag("model_type", "XGBoost")

            # Infer model signature
            signature = infer_signature(X_train, xgb_model.predict(X_train))

            # Log the XGBoost model using sklearn format
            mlflow.sklearn.log_model(
                sk_model=xgb_model, artifact_path="xgboost_model", signature=signature
            )

        return roc_auc

    # Run optimization
    study = optuna.create_study(direction="maximize")
    study.optimize(objective_xgboost, n_trials=n_trials)

    return study.best_value


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


def setup_evidently_cloud(project_name, evidently_token, evidently_org_id):
    ws = CloudWorkspace(token=evidently_token, url="https://app.evidently.cloud")
    project_exists = ws.search_project(project_name)

    if not project_exists:
        project = ws.create_project(project_name, org_id=evidently_org_id)
        project.dashboard.add_panel(
            DashboardPanelPlot(
                title="Row count",
                subtitle="Total number of evaluations over time.",
                size="half",
                values=[PanelMetric(legend="Row count", metric="RowCount")],
                plot_params={"plot_type": "counter", "aggregation": "sum"},
            ),
            tab="Data",
        )

        project.dashboard.add_panel(
            DashboardPanelPlot(
                title="Row count",
                subtitle="Latest number of evaluations.",
                size="half",
                values=[PanelMetric(legend="Row count", metric="RowCount")],
                plot_params={"plot_type": "counter", "aggregation": "last"},
            ),
            tab="Data",
        )

        project.dashboard.add_panel(
            DashboardPanelPlot(
                title="Dataset column drift",
                subtitle="Share of drifted columns",
                size="half",
                values=[
                    PanelMetric(
                        legend="prop of drifted column",
                        metric="DriftedColumnsCount",
                        metric_labels={"value_type": "share"},
                    ),
                ],
                plot_params={"plot_type": "line"},
            ),
            tab="Data",
        )

        project.dashboard.add_panel(
            DashboardPanelPlot(
                title="Prediction drift",
                subtitle="""Drift in the prediction column ("target"), method: Jensen-Shannon distance""",
                size="half",
                values=[
                    PanelMetric(
                        legend="prop of drifted target",
                        metric="ValueDrift",
                        metric_labels={"column": "target"},
                    ),
                ],
                plot_params={"plot_type": "bar"},
            ),
            tab="Data",
        )

        project.dashboard.add_panel(
            DashboardPanelPlot(
                title="Accuracy over time",
                subtitle="Share of drifted columns",
                size="half",
                values=[
                    PanelMetric(
                        legend="Accuracy",
                        metric="Accuracy",
                    ),
                ],
                plot_params={"plot_type": "line"},
            ),
            tab="Data",
        )
    else:
        project = project_exists[0]

    return ws, project
