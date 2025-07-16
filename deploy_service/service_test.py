import os

import mlflow
import pandas as pd
from flask import Flask, jsonify, render_template, request
from predict_function import preprocess_pd, xgb_model

try:
    from dotenv import load_dotenv

    load_dotenv()  # Load environment variables from .env file
except ImportError:
    pass  # dotenv not installed, use system environment variables

app = Flask(__name__)

# Initialize the XGBoost predictor
# Allow mocking during testing
if os.environ.get("TESTING") == "true":
    # Mock predictor for testing
    class MockPredictor:
        def predict(self, df):
            # Check for invalid data in testing
            if "age" in df.columns:
                try:
                    # Try to convert age to numeric
                    pd.to_numeric(df["age"])
                except (ValueError, TypeError):
                    raise ValueError("Invalid age value")

            # Return mock prediction
            df["prediction"] = [0] * len(df)
            df["predict_proba"] = [0.3] * len(df)
            return df

    predictor = MockPredictor()
else:
    # Production: Load real MLflow model from environment variable
    mlflow_uri = os.getenv("MLFLOW_TRACKING_URI", "http://localhost:5000")
    mlflow.set_tracking_uri(mlflow_uri)
    predictor = xgb_model(model_name="mlops_project", model_version="champion")


@app.route("/", methods=["GET"])
def index():
    return render_template("index.html")


@app.route("/predict", methods=["POST"])
def predict_api():
    if request.is_json:
        try:
            data = request.get_json()
            # Convert to pandas DataFrame
            df = pd.DataFrame([data])
            # Make prediction using the XGBoost predictor
            # This will modify df in-place and return numpy array
            predicted_df = predictor.predict(df)
            predictions = predicted_df["prediction"].values

            # df now contains 'predict_proba' and 'prediction' columns
            print(f"Binary predictions: {predictions}")

            # Return JSON response
            return jsonify(
                {
                    "prediction": predictions[0].item(),  # Convert to Python bool/int
                    "status": "success",
                }
            )
        except (ValueError, TypeError, KeyError) as e:
            return jsonify({"error": str(e)}), 400
    else:
        return jsonify({"error": "Request must be JSON"}), 400


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=9696, debug=True)
