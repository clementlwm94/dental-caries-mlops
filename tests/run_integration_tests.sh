#!/bin/bash

# Integration test runner script
# Runs integration tests with proper setup and cleanup

set -e

echo "🚀 Starting Integration Tests..."
echo "=================================="

# Check if Python dependencies are installed
echo "📦 Checking dependencies..."
pip install -r requirements.txt > /dev/null 2>&1

echo "🧪 Running integration tests..."
echo ""

# Run integration tests with verbose output
pytest test_integration.py -v -m integration

echo ""
echo "✅ Integration tests completed!"
echo "=================================="
