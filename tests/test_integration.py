"""
Integration tests for the prediction service
Tests the actual Flask service running locally
"""

import os
import signal
import subprocess
import sys
import time
from unittest.mock import patch

import pytest
import requests

# Add the deploy_service directory to the path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "deploy_service"))


@pytest.fixture(scope="module")
def flask_service():
    """Start Flask service for integration testing"""
    # Change to deploy_service directory
    deploy_service_dir = os.path.join(os.path.dirname(__file__), "..", "deploy_service")

    # Set environment variable to enable testing mode
    env = os.environ.copy()
    env["TESTING"] = "true"

    # Start Flask service in background with testing environment
    process = subprocess.Popen(
        [sys.executable, "service_test.py"],
        cwd=deploy_service_dir,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        env=env,
    )

    # Wait for service to start
    time.sleep(5)

    # Check if service is running
    try:
        response = requests.get("http://localhost:9696/", timeout=10)
        if response.status_code != 200:
            raise Exception("Service not responding")
    except requests.exceptions.RequestException as e:
        process.terminate()
        pytest.skip(f"Could not start Flask service: {e}")

    yield "http://localhost:9696"

    # Cleanup
    try:
        process.terminate()
        process.wait(timeout=5)
    except subprocess.TimeoutExpired:
        process.kill()


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


@pytest.mark.integration
class TestPredictionServiceIntegration:
    """Integration tests for the prediction service"""

    def test_service_health_check(self, flask_service):
        """Test that the service is running and returns the web page"""
        response = requests.get(flask_service)

        assert response.status_code == 200
        assert b"html" in response.content.lower()

    def test_prediction_endpoint_integration(self, flask_service, sample_patient_data):
        """Test the prediction endpoint with actual HTTP request"""
        response = requests.post(
            f"{flask_service}/predict",
            json=sample_patient_data,
            headers={"Content-Type": "application/json"},
        )

        assert response.status_code == 200

        data = response.json()
        assert data["status"] == "success"
        assert "prediction" in data
        assert data["prediction"] in [0, 1]

    def test_prediction_endpoint_invalid_data(self, flask_service):
        """Test prediction endpoint with invalid data"""
        invalid_data = {"race": "chinese", "age": "invalid_age"}  # Invalid age

        response = requests.post(
            f"{flask_service}/predict",
            json=invalid_data,
            headers={"Content-Type": "application/json"},
        )

        # Should handle error gracefully
        assert response.status_code in [400, 500]

    def test_prediction_endpoint_missing_content_type(
        self, flask_service, sample_patient_data
    ):
        """Test prediction endpoint without JSON content type"""
        response = requests.post(
            f"{flask_service}/predict", data=sample_patient_data  # Not JSON
        )

        assert response.status_code == 400
        data = response.json()
        assert data["error"] == "Request must be JSON"

    def test_prediction_multiple_requests(self, flask_service, sample_patient_data):
        """Test multiple prediction requests to ensure service stability"""
        for i in range(3):
            response = requests.post(
                f"{flask_service}/predict",
                json=sample_patient_data,
                headers={"Content-Type": "application/json"},
            )

            assert response.status_code == 200
            data = response.json()
            assert data["status"] == "success"
            assert "prediction" in data

    def test_prediction_different_patient_data(self, flask_service):
        """Test prediction with different patient scenarios"""
        test_cases = [
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
            },
            {
                "race": "indian",
                "age": 35,
                "gender": "male",
                "breast_feeding_month": 18,
                "mother_occupation": "professional",
                "household_income": ">=4000",
                "mother_edu": "university",
                "delivery_type": "normal",
                "smoke_mother": "No",
                "night_bottle_feeding": "No",
            },
        ]

        for test_data in test_cases:
            response = requests.post(
                f"{flask_service}/predict",
                json=test_data,
                headers={"Content-Type": "application/json"},
            )

            assert response.status_code == 200
            data = response.json()
            assert data["status"] == "success"
            assert "prediction" in data
            assert data["prediction"] in [0, 1]


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
