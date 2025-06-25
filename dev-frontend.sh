#!/bin/bash

# Frontend Development Helper Script
# This script sets up and runs the frontend development server

set -e

echo "⚛️  Starting Frontend Development Server"
echo "======================================"

# Navigate to frontend directory
cd frontend

# Check if node_modules exists
if [[ ! -d "node_modules" ]]; then
    echo "📦 Installing frontend dependencies..."
    npm install --legacy-peer-deps
else
    echo "✅ Dependencies already installed"
fi

# Check if backend is running
if ! curl -s http://localhost:5001/api/v1/health > /dev/null 2>&1; then
    echo "⚠️  Backend is not running on localhost:5001"
    echo "   Please start the backend first with: ./dev-backend.sh"
    echo "   Or run: cd backend/go-app && go run main.go"
    echo ""
fi

# Start development server
echo "🚀 Starting frontend development server with hot reload..."
echo "   Access at: http://localhost:3000"
echo "   🔥 Hot reload is enabled - changes will be reflected automatically"
echo "   Press Ctrl+C to stop"
echo ""

npm start