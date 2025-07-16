from datetime import datetime, timedelta

import numpy as np
import pandas as pd
from airflow.decorators import dag, task

# Import our custom utility functions
from ml_function import (
    create_dataset,
    prepare_data_function,
    preprocess_pd,
    train_xgboost_with_optuna,
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
    dag_id="ml_pipeline_dag",
    default_args=default_args,
    description="ML Pipeline with XGBoost",
    schedule=None,  # Manual trigger only
    catchup=False,
    tags=["ml", "xgboost", "optuna"],
)
def ml_pipeline():

    @task
    def create_df_and_prepare_data(n_samples=1000):
        """Combined task: Create dataset and prepare data for training"""
        # Create dataset
        dat = create_dataset(n_samples)

        # Prepare data
        data_prep = prepare_data_function(dat)

        # Convert to serializable format
        return {
            "X_train": data_prep["X_train"].to_dict("records"),
            "X_test": data_prep["X_test"].to_dict("records"),
            "y_train": data_prep["y_train"].tolist(),
            "y_test": data_prep["y_test"].tolist(),
        }

    @task
    def train_xgboost(data_and_splits):
        """Train XGBoost model using the imported function"""
        # Extract data from the data_and_splits
        X_train = pd.DataFrame(data_and_splits["X_train"])
        X_test = pd.DataFrame(data_and_splits["X_test"])
        y_train = np.array(data_and_splits["y_train"])
        y_test = np.array(data_and_splits["y_test"])

        # Reorder columns to expected order (to handle serialization column reordering)
        expected_column_order = [
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
        ]
        X_train = X_train[expected_column_order]
        X_test = X_test[expected_column_order]

        X_train = preprocess_pd(X_train.copy())
        X_test = preprocess_pd(X_test.copy())

        # Use the imported training function with environment variables
        best_score = train_xgboost_with_optuna(
            X_train,
            y_train,
            X_test,
            y_test,
            mlflow_uri=None,  # Will use environment variable MLFLOW_TRACKING_URI
            experiment_name="ml_pipeline_experiment",
            n_trials=10,
        )

        return best_score

    # Define task dependencies
    data_and_splits = create_df_and_prepare_data()
    result = train_xgboost(data_and_splits)


# Instantiate the DAG
ml_pipeline_dag = ml_pipeline()
