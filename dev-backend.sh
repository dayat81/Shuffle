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

# Override OpenSearch URL for local development
export SHUFFLE_OPENSEARCH_URL="https://localhost:9200"
export SHUFFLE_OPENSEARCH_SKIPSSL_VERIFY="true"
export SHUFFLE_OPENSEARCH_USERNAME="admin"
export SHUFFLE_OPENSEARCH_PASSWORD="StrongShufflePassword321!"

# Check if OpenSearch is running
if ! curl -s -k https://localhost:9200 > /dev/null 2>&1 && ! curl -s http://localhost:9200 > /dev/null 2>&1; then
    echo "⚠️  OpenSearch is not running on localhost:9200"
    echo "   Please start Docker services first with: ./dev-start.sh"
    echo ""
else
    echo "✅ OpenSearch is running on localhost:9200"
fi

# Start backend server
echo "🚀 Starting backend development server..."
echo "   API will be available at: http://localhost:5001"
echo "   Health check: http://localhost:5001/api/v1/health"
echo "   Press Ctrl+C to stop"
echo ""

# Add Go bin to PATH
export PATH=$HOME/go/bin:$HOME/go-local/bin:$PATH

# Check if Air is available for hot reloading
if command -v air &> /dev/null; then
    echo "🔥 Starting backend with hot reload (Air)..."
    air
else
    echo "⚠️  Air not found, starting without hot reload..."
    echo "   Install Air with: go install github.com/air-verse/air@latest"
    go run main.go walkoff.go docker.go
fi