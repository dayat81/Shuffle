#!/bin/bash

# Shuffle Docker Installation Script
# This script installs Docker and Docker Compose on Ubuntu/Debian systems

set -e

echo "🐳 Installing Docker for Shuffle Development Environment"
echo "=============================================="

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo "❌ This script should not be run as root for security reasons"
   echo "Please run as a regular user with sudo privileges"
   exit 1
fi

# Detect OS
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    OS=$NAME
    VERSION=$VERSION_ID
else
    echo "❌ Cannot detect operating system"
    exit 1
fi

echo "📋 Detected OS: $OS $VERSION"

# Function to install Docker on Ubuntu/Debian
install_docker_ubuntu_debian() {
    echo "🔧 Installing Docker on Ubuntu/Debian..."
    
    # Remove old versions
    sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    
    # Update package index
    sudo apt-get update
    
    # Install prerequisites
    sudo apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    
    # Add Docker's official GPG key
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    # Set up repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Update package index again
    sudo apt-get update
    
    # Install Docker Engine
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Add user to docker group
    sudo usermod -aG docker $USER
    
    echo "✅ Docker installed successfully!"
}

# Function to install Docker on CentOS/RHEL/Fedora
install_docker_rhel() {
    echo "🔧 Installing Docker on RHEL/CentOS/Fedora..."
    
    # Remove old versions
    sudo yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine 2>/dev/null || true
    
    # Install prerequisites
    sudo yum install -y yum-utils
    
    # Add Docker repository
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    
    # Install Docker
    sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Start and enable Docker
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # Add user to docker group
    sudo usermod -aG docker $USER
    
    echo "✅ Docker installed successfully!"
}

# Check if Docker is already installed
if command -v docker &> /dev/null; then
    echo "✅ Docker is already installed"
    docker --version
    if command -v docker-compose &> /dev/null || docker compose version &> /dev/null; then
        echo "✅ Docker Compose is available"
    else
        echo "❌ Docker Compose not found"
        exit 1
    fi
else
    echo "📦 Docker not found, installing..."
    
    # Install based on OS
    case "$OS" in
        *Ubuntu*|*Debian*)
            install_docker_ubuntu_debian
            ;;
        *CentOS*|*"Red Hat"*|*Fedora*)
            install_docker_rhel
            ;;
        *)
            echo "❌ Unsupported operating system: $OS"
            echo "Please install Docker manually from: https://docs.docker.com/get-docker/"
            exit 1
            ;;
    esac
fi

# Test Docker installation
echo "🧪 Testing Docker installation..."

# Start Docker service if not running
sudo systemctl start docker 2>/dev/null || true

# Test Docker
if sudo docker run hello-world &> /dev/null; then
    echo "✅ Docker is working correctly!"
else
    echo "❌ Docker test failed"
    exit 1
fi

# Set up system requirements for OpenSearch
echo "⚙️  Configuring system for OpenSearch..."
sudo sysctl -w vm.max_map_count=262144
echo 'vm.max_map_count=262144' | sudo tee -a /etc/sysctl.conf

# Create directories
echo "📁 Creating required directories..."
mkdir -p shuffle-database shuffle-apps shuffle-files
sudo chown -R 1000:1000 shuffle-database

# Create .env file if it doesn't exist
if [[ ! -f .env ]]; then
    echo "📝 Creating .env file..."
    cat > .env << 'EOF'
# Shuffle Development Environment Variables
BACKEND_HOSTNAME=localhost
BACKEND_PORT=5001
FRONTEND_PORT=3000
FRONTEND_PORT_HTTPS=3443
OUTER_HOSTNAME=localhost
SHUFFLE_APP_HOTLOAD_LOCATION=/home/pt/Shuffle/shuffle-apps
SHUFFLE_FILE_LOCATION=/home/pt/Shuffle/shuffle-files
DB_LOCATION=/home/pt/Shuffle/shuffle-database
SHUFFLE_OPENSEARCH_PASSWORD=StrongPassword123!
EOF
    echo "✅ Created .env file"
else
    echo "✅ .env file already exists"
fi

echo ""
echo "🎉 Docker installation completed successfully!"
echo ""
echo "⚠️  IMPORTANT: You need to log out and log back in (or run 'newgrp docker')"
echo "   to use Docker without sudo due to group membership changes."
echo ""
echo "🚀 Next steps:"
echo "1. Log out and log back in"
echo "2. Run: ./dev-start.sh"
echo ""