#!/bin/bash

# Shuffle Development Environment Startup Script
# This script starts the Docker services and provides instructions for local development

set -e

echo "🚀 Starting Shuffle Development Environment"
echo "=========================================="

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please run ./install-docker.sh first"
    exit 1
fi

# Check if user is in docker group
if ! groups $USER | grep -q docker; then
    echo "❌ User $USER is not in the docker group."
    echo "Please run: sudo usermod -aG docker $USER"
    echo "Then log out and log back in, or run: newgrp docker"
    exit 1
fi

# Check if Docker daemon is running
if ! docker info &> /dev/null; then
    echo "🔄 Starting Docker daemon..."
    sudo systemctl start docker
    sleep 2
fi

# Verify Docker is working
echo "🧪 Verifying Docker installation..."
if ! docker ps &> /dev/null; then
    echo "❌ Docker is not working properly"
    exit 1
fi

# Create required directories
echo "📁 Creating required directories..."
mkdir -p shuffle-database shuffle-apps shuffle-files

# Set ownership for OpenSearch
echo "🔧 Setting up permissions..."
sudo chown -R 1000:1000 shuffle-database 2>/dev/null || {
    echo "⚠️  Could not set ownership for shuffle-database. You may need to run:"
    echo "   sudo chown -R 1000:1000 shuffle-database"
}

# Set system requirements for OpenSearch
echo "⚙️  Configuring system settings for OpenSearch..."
sudo sysctl -w vm.max_map_count=262144 2>/dev/null || {
    echo "⚠️  Could not set vm.max_map_count. You may need to run:"
    echo "   sudo sysctl -w vm.max_map_count=262144"
}

# Disable swap if possible
sudo swapoff -a 2>/dev/null || echo "⚠️  Could not disable swap (this is optional)"

# Check if .env file exists
if [[ ! -f .env ]]; then
    echo "📝 Creating .env file..."
    cat > .env << EOF
BACKEND_HOSTNAME=localhost
BACKEND_PORT=5001
FRONTEND_PORT=3000
FRONTEND_PORT_HTTPS=3443
OUTER_HOSTNAME=localhost
SHUFFLE_APP_HOTLOAD_LOCATION=$(pwd)/shuffle-apps
SHUFFLE_FILE_LOCATION=$(pwd)/shuffle-files
DB_LOCATION=$(pwd)/shuffle-database
SHUFFLE_OPENSEARCH_PASSWORD=StrongPassword123!
EOF
fi

# Check if Go is installed
if ! command -v go &> /dev/null; then
    echo "📦 Go is not installed. Installing Go 1.24.3..."
    
    # Download and install Go
    if [[ ! -f go1.24.3.linux-amd64.tar.gz ]]; then
        curl -fsSL https://golang.org/dl/go1.24.3.linux-amd64.tar.gz -o go1.24.3.linux-amd64.tar.gz
    fi
    
    # Extract Go to user's home directory
    mkdir -p $HOME/go-local
    tar -C $HOME/go-local -xzf go1.24.3.linux-amd64.tar.gz --strip-components=1
    
    # Add to PATH
    export PATH=$HOME/go-local/bin:$PATH
    echo 'export PATH=$HOME/go-local/bin:$PATH' >> ~/.bashrc
    
    echo "✅ Go installed to $HOME/go-local"
    rm -f go1.24.3.linux-amd64.tar.gz
else
    echo "✅ Go is already installed: $(go version)"
fi

# Stop any existing containers
echo "🛑 Stopping existing containers..."
docker-compose -f docker-compose.dev.yml down 2>/dev/null || true

# Start Docker services
echo "🐳 Starting Docker services (OpenSearch + Orborus)..."
docker-compose -f docker-compose.dev.yml up -d

# Wait for services to be ready
echo "⏳ Waiting for services to start..."
sleep 10

# Check if OpenSearch is ready
echo "🔍 Checking OpenSearch status..."
for i in {1..30}; do
    if curl -s http://localhost:9200 > /dev/null 2>&1; then
        echo "✅ OpenSearch is ready!"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "⚠️  OpenSearch may not be ready yet. Check with: curl http://localhost:9200"
    fi
    sleep 2
done

# Show running containers
echo "📋 Running containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "🎉 Docker services are running!"
echo ""
echo "📚 Next steps for local development:"
echo ""
echo "1️⃣  Frontend Development (Terminal 1):"
echo "   cd frontend"
echo "   npm install --legacy-peer-deps"
echo "   npm start"
echo "   → http://localhost:3000"
echo ""
echo "2️⃣  Backend Development (Terminal 2):"
echo "   cd backend/go-app"
echo "   go mod download"
echo "   go run main.go"
echo "   → http://localhost:5001"
echo ""
echo "3️⃣  Verify Services:"
echo "   • Frontend: http://localhost:3000"
echo "   • Backend: http://localhost:5001/api/v1/health"
echo "   • OpenSearch: http://localhost:9200"
echo ""
echo "🛠️  Useful commands:"
echo "   • View logs: docker-compose -f docker-compose.dev.yml logs -f"
echo "   • Stop services: docker-compose -f docker-compose.dev.yml down"
echo "   • Restart services: ./dev-start.sh"
echo ""
echo "📖 For detailed setup instructions, see: LOCAL_DEV_SETUP.md"
echo ""