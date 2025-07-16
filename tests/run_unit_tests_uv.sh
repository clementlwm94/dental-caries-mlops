#!/bin/bash

# Unit test runner script using uv environment
# Runs fast unit tests with uv virtual environment

set -e

echo "🚀 Starting Unit Tests with uv..."
echo "=================================="

# Activate uv environment
source test-env/bin/activate

echo "🧪 Running unit tests..."
echo ""

# Run unit tests (fast)
pytest test_deploy_service.py test_ml_functions.py -v -m "not integration"

echo ""
echo "✅ Unit tests completed!"
echo "=================================="
