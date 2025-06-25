#!/bin/bash

# Backend Development Helper Script
# This script sets up and runs the backend development server

set -e

echo "🔧 Starting Backend Development Server"
echo "====================================="

# Check if Go is available
if ! command -v go &> /dev/null; then
    echo "❌ Go is not installed"
    echo "   Run ./dev-start.sh to install Go"
    exit 1
fi

# Navigate to backend directory
cd backend/go-app

# Check if go.mod exists
if [[ ! -f go.mod ]]; then
    echo "❌ go.mod not found in backend/go-app"
    exit 1
fi

# Download dependencies if needed
echo "📦 Checking Go dependencies..."
go mod download

# Set environment variables for local development
export SHUFFLE_APP_HOTLOAD_FOLDER="$(pwd)/../../shuffle-apps"
export SHUFFLE_FILE_LOCATION="$(pwd)/../../shuffle-files"

# Check if OpenSearch is running
if ! curl -s http://localhost:9200 > /dev/null 2>&1; then
    echo "⚠️  OpenSearch is not running on localhost:9200"
    echo "   Please start Docker services first with: ./dev-start.sh"
    echo ""
fi

# Start backend server
echo "🚀 Starting backend development server..."
echo "   API will be available at: http://localhost:5001"
echo "   Health check: http://localhost:5001/api/v1/health"
echo "   Press Ctrl+C to stop"
echo ""

go run main.go