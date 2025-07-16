#!/bin/bash

# Integration test runner script using uv environment
# Runs integration tests with proper setup and cleanup

set -e

echo "🚀 Starting Integration Tests with uv..."
echo "========================================"

# Activate uv environment
source test-env/bin/activate

echo "🧪 Running integration tests..."
echo ""

# Run integration tests with verbose output
pytest test_integration.py -v -m integration

echo ""
echo "✅ Integration tests completed!"
echo "========================================"
