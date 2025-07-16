#!/bin/bash

# Complete test runner script using uv environment
# Runs all tests with coverage reporting

set -e

echo "🚀 Starting All Tests with uv..."
echo "================================"

# Activate uv environment
source test-env/bin/activate

echo "📦 Environment activated..."

echo "🧪 Running all tests with coverage..."
echo ""

# Run all tests with coverage
pytest test_deploy_service.py test_ml_functions.py test_integration.py \
  --cov=../deploy_service \
  --cov=../local-airflow/dags \
  --cov-report=term-missing \
  --cov-report=html \
  -v

echo ""
echo "✅ All tests completed!"
echo "📊 Coverage report generated in htmlcov/"
echo "================================"
