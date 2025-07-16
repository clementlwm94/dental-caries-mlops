import os
from datetime import datetime, timedelta

import mlflow
import numpy as np
from airflow.decorators import dag, task

try:
    from dotenv import load_dotenv

    load_dotenv()  # Load environment variables from .env file
except ImportError:
    pass  # dotenv not installed, use system environment variables

from evidently import BinaryClassification, DataDefinition, Dataset, Report
from evidently.presets import ClassificationPreset, DataDriftPreset

# Import our custom utility functions
from ml_function import (
    create_dataset,
    prepare_data_function,
    preprocess_pd,
    setup_evidently_cloud,
    xgb_model,
)

default_args = {
    "owner": "data-team",
    "depends_on_past": False,
    "start_date": datetime(2025, 7, 7),
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=5),
}


@dag(
    dag_id="ml_monitoring_pipeline",
    default_args=default_args,
    description="ML Model Monitoring Pipeline with Evidently",
    schedule="@yearly",  # Run once per year
    catchup=False,
    tags=["ml", "monitoring", "evidently"],
)
def ml_monitoring_pipeline():

    @task
    def run_model_monitoring():
        """ML monitoring pipeline based on monitoring.py"""

        # Set MLflow tracking URI from environment variable
        mlflow_uri = os.getenv("MLFLOW_TRACKING_URI", "http://localhost:5000")
        mlflow.set_tracking_uri(mlflow_uri)
        # Load model using xgb_model class
        predictor = xgb_model(model_name="mlops_project", model_version="champion")

        # Define categorical columns
        categorical_cols = [
            "race",
            "gender",
            "mother_occupation",
            "household_income",
            "mother_edu",
            "delivery_type",
            "smoke_mother",
            "night_bottle_feeding",
        ]

        # Create and prepare data
        dat = create_dataset(100)
        dat_processed = prepare_data_function(dat)
        X_ref = preprocess_pd(dat_processed["X_train"].copy())
        X_test = preprocess_pd(dat_processed["X_test"].copy())

        # Make predictions using the predictor
        predicted_X_ref = predictor.predict(X_ref)
        predicted_X_test = predictor.predict(X_test)
        predicted_X_ref["target"] = dat_processed["y_train"]
        predicted_X_test["target"] = dat_processed["y_test"]

        # Create schema and datasets
        numerical_cols = np.setdiff1d(
            predicted_X_ref.drop(["target", "prediction"], axis=1).columns,
            categorical_cols,
        ).tolist()
        categorical_cols_extended = categorical_cols + ["target", "prediction"]

        schema = DataDefinition(
            numerical_columns=numerical_cols,
            categorical_columns=categorical_cols_extended,
            classification=[
                BinaryClassification(
                    target="target",
                    prediction_labels="prediction",
                    prediction_probas="predict_proba",
                )
            ],
        )

        eval_X_ref = Dataset.from_pandas(predicted_X_ref, data_definition=schema)
        eval_X_test = Dataset.from_pandas(predicted_X_test, data_definition=schema)

        # Project setup - load from environment variables
        project_name = "mlops_project"
        evidently_token = os.getenv("EVIDENTLY_TOKEN")
        evidently_org_id = os.getenv("EVIDENTLY_ORG_ID")

        # Validate required environment variables
        if not evidently_token:
            raise ValueError("EVIDENTLY_TOKEN environment variable is required")
        if not evidently_org_id:
            raise ValueError("EVIDENTLY_ORG_ID environment variable is required")
        ws, project = setup_evidently_cloud(
            project_name, evidently_token, evidently_org_id
        )

        # Generate reports
        report = Report(
            [ClassificationPreset()], include_tests=True, tags=["Classification_test"]
        )
        my_eval = report.run(eval_X_test, eval_X_ref)
        ws.add_run(project.id, my_eval, include_data=False)

        report = Report([DataDriftPreset()], include_tests=True, tags=["Data_Drift"])
        my_eval = report.run(eval_X_test, eval_X_ref)
        ws.add_run(project.id, my_eval, include_data=False)

        return "Monitoring reports uploaded successfully"

    # Single task execution
    run_model_monitoring()


# Instantiate the DAG
ml_monitoring_dag = ml_monitoring_pipeline()
