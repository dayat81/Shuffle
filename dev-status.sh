#!/bin/bash

# Shuffle Development Environment Status Script
# This script checks the status of all development components

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Icons
CHECK="✅"
CROSS="❌"
WARNING="⚠️ "
INFO="ℹ️ "

echo -e "${BLUE}🔍 Shuffle Development Environment Status${NC}"
echo "=============================================="
echo ""

# Function to check if a service is running on a port
check_port() {
    local port=$1
    local service=$2
    if netstat -tuln 2>/dev/null | grep -q ":$port "; then
        echo -e "${CHECK} ${GREEN}$service${NC} - Running on port $port"
        return 0
    elif ss -tuln 2>/dev/null | grep -q ":$port "; then
        echo -e "${CHECK} ${GREEN}$service${NC} - Running on port $port"
        return 0
    else
        echo -e "${CROSS} ${RED}$service${NC} - Not running on port $port"
        return 1
    fi
}

# Function to check HTTP endpoint
check_http() {
    local url=$1
    local service=$2
    local timeout=${3:-5}
    
    if curl -s --max-time $timeout "$url" > /dev/null 2>&1; then
        echo -e "${CHECK} ${GREEN}$service${NC} - HTTP endpoint responding"
        return 0
    else
        echo -e "${CROSS} ${RED}$service${NC} - HTTP endpoint not responding"
        return 1
    fi
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# System Requirements Check
echo -e "${BLUE}📋 System Requirements${NC}"
echo "------------------------"

# Docker
if command_exists docker; then
    if docker info >/dev/null 2>&1; then
        echo -e "${CHECK} ${GREEN}Docker${NC} - $(docker --version)"
        DOCKER_OK=true
    else
        echo -e "${WARNING} ${YELLOW}Docker${NC} - Installed but daemon not accessible"
        echo -e "   ${INFO} Try: sudo systemctl start docker"
        DOCKER_OK=false
    fi
else
    echo -e "${CROSS} ${RED}Docker${NC} - Not installed"
    echo -e "   ${INFO} Run: ./install-docker.sh"
    DOCKER_OK=false
fi

# Docker Compose
if command_exists docker && docker compose version >/dev/null 2>&1; then
    echo -e "${CHECK} ${GREEN}Docker Compose${NC} - $(docker compose version --short 2>/dev/null || echo 'Available')"
elif command_exists docker-compose; then
    echo -e "${CHECK} ${GREEN}Docker Compose${NC} - $(docker-compose --version)"
else
    echo -e "${CROSS} ${RED}Docker Compose${NC} - Not available"
fi

# Node.js and npm
if command_exists node; then
    echo -e "${CHECK} ${GREEN}Node.js${NC} - $(node --version)"
else
    echo -e "${CROSS} ${RED}Node.js${NC} - Not installed"
fi

if command_exists npm; then
    echo -e "${CHECK} ${GREEN}npm${NC} - $(npm --version)"
else
    echo -e "${CROSS} ${RED}npm${NC} - Not installed"
fi

# Go
export PATH=$HOME/go-local/bin:$PATH
if command_exists go; then
    echo -e "${CHECK} ${GREEN}Go${NC} - $(go version | cut -d' ' -f3)"
else
    echo -e "${CROSS} ${RED}Go${NC} - Not installed"
    echo -e "   ${INFO} Run: ./dev-start.sh (installs Go automatically)"
fi

# System settings
echo ""
echo -e "${BLUE}⚙️  System Configuration${NC}"
echo "-----------------------------"

# vm.max_map_count
MAX_MAP_COUNT=$(sysctl -n vm.max_map_count 2>/dev/null || cat /proc/sys/vm/max_map_count 2>/dev/null || echo "unknown")
if [[ "$MAX_MAP_COUNT" =~ ^[0-9]+$ ]] && [[ "$MAX_MAP_COUNT" -ge 262144 ]]; then
    echo -e "${CHECK} ${GREEN}vm.max_map_count${NC} - $MAX_MAP_COUNT (sufficient for OpenSearch)"
else
    echo -e "${WARNING} ${YELLOW}vm.max_map_count${NC} - $MAX_MAP_COUNT (should be >= 262144)"
    echo -e "   ${INFO} Run: sudo sysctl -w vm.max_map_count=262144"
fi

# Docker group membership
if groups $USER | grep -q docker; then
    echo -e "${CHECK} ${GREEN}Docker group${NC} - User $USER is in docker group"
else
    echo -e "${WARNING} ${YELLOW}Docker group${NC} - User $USER not in docker group"
    echo -e "   ${INFO} Run: sudo usermod -aG docker $USER && newgrp docker"
fi

# Directory Structure
echo ""
echo -e "${BLUE}📁 Directory Structure${NC}"
echo "-------------------------"

REQUIRED_DIRS=("shuffle-database" "shuffle-apps" "shuffle-files" "frontend" "backend/go-app")
for dir in "${REQUIRED_DIRS[@]}"; do
    if [[ -d "$dir" ]]; then
        echo -e "${CHECK} ${GREEN}$dir${NC} - Exists"
    else
        echo -e "${CROSS} ${RED}$dir${NC} - Missing"
    fi
done

# Configuration Files
echo ""
echo -e "${BLUE}📝 Configuration Files${NC}"
echo "----------------------------"

CONFIG_FILES=(".env" "docker-compose.dev.yml" "frontend/package.json" "backend/go-app/go.mod")
for file in "${CONFIG_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        echo -e "${CHECK} ${GREEN}$file${NC} - Exists"
    else
        echo -e "${CROSS} ${RED}$file${NC} - Missing"
    fi
done

# Docker Services Status
echo ""
echo -e "${BLUE}🐳 Docker Services${NC}"
echo "---------------------"

if [[ "$DOCKER_OK" == true ]]; then
    # Check if docker-compose.dev.yml services are running
    if docker-compose -f docker-compose.dev.yml ps --services --filter "status=running" 2>/dev/null | grep -q .; then
        echo "Running containers:"
        docker-compose -f docker-compose.dev.yml ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || \
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" --filter "name=shuffle"
    else
        echo -e "${CROSS} ${RED}No Shuffle Docker services running${NC}"
        echo -e "   ${INFO} Run: ./dev-start.sh"
    fi
else
    echo -e "${CROSS} ${RED}Docker not available - cannot check services${NC}"
fi

# Service Endpoints
echo ""
echo -e "${BLUE}🌐 Service Endpoints${NC}"
echo "----------------------"

# Frontend
if check_port 3000 "Frontend (React)"; then
    check_http "http://localhost:3000" "Frontend" 3
else
    echo -e "   ${INFO} Run: ./dev-frontend.sh"
fi

# Backend
if check_port 5001 "Backend (Go API)"; then
    check_http "http://localhost:5001/api/v1/health" "Backend API" 3
else
    echo -e "   ${INFO} Run: ./dev-backend.sh"
fi

# OpenSearch
if check_port 9200 "OpenSearch (Database)"; then
    check_http "http://localhost:9200" "OpenSearch" 3
else
    echo -e "   ${INFO} Start with: ./dev-start.sh"
fi

# Development Dependencies
echo ""
echo -e "${BLUE}📦 Development Dependencies${NC}"
echo "-------------------------------"

# Frontend dependencies
if [[ -d "frontend/node_modules" ]]; then
    echo -e "${CHECK} ${GREEN}Frontend dependencies${NC} - Installed"
else
    echo -e "${CROSS} ${RED}Frontend dependencies${NC} - Not installed"
    echo -e "   ${INFO} Run: cd frontend && npm install --legacy-peer-deps"
fi

# Backend dependencies
if [[ -f "backend/go-app/go.sum" ]]; then
    echo -e "${CHECK} ${GREEN}Backend dependencies${NC} - Downloaded"
else
    echo -e "${WARNING} ${YELLOW}Backend dependencies${NC} - May need downloading"
    echo -e "   ${INFO} Run: cd backend/go-app && go mod download"
fi

# Summary
echo ""
echo -e "${BLUE}📊 Development Environment Summary${NC}"
echo "=====================================+"

# Count running services
RUNNING_SERVICES=0
check_port 3000 "" && ((RUNNING_SERVICES++)) || true
check_port 5001 "" && ((RUNNING_SERVICES++)) || true  
check_port 9200 "" && ((RUNNING_SERVICES++)) || true

if [[ $RUNNING_SERVICES -eq 3 ]]; then
    echo -e "${CHECK} ${GREEN}All services running${NC} - Ready for development!"
    echo ""
    echo -e "${BLUE}🚀 Access Points:${NC}"
    echo "   • Frontend: http://localhost:3000"
    echo "   • Backend:  http://localhost:5001"
    echo "   • API Health: http://localhost:5001/api/v1/health"
    echo "   • OpenSearch: http://localhost:9200"
elif [[ $RUNNING_SERVICES -gt 0 ]]; then
    echo -e "${WARNING} ${YELLOW}Partial setup${NC} - $RUNNING_SERVICES/3 services running"
    echo ""
    echo -e "${BLUE}💡 Next steps:${NC}"
    [[ $(check_port 9200 "" 2>/dev/null; echo $?) -ne 0 ]] && echo "   • Start Docker services: ./dev-start.sh"
    [[ $(check_port 3000 "" 2>/dev/null; echo $?) -ne 0 ]] && echo "   • Start frontend: ./dev-frontend.sh"
    [[ $(check_port 5001 "" 2>/dev/null; echo $?) -ne 0 ]] && echo "   • Start backend: ./dev-backend.sh"
else
    echo -e "${CROSS} ${RED}No services running${NC} - Development environment not started"
    echo ""
    echo -e "${BLUE}💡 Quick start:${NC}"
    echo "   1. ./install-docker.sh  (if not done)"
    echo "   2. ./dev-start.sh       (Docker services)"
    echo "   3. ./dev-frontend.sh    (React server)"
    echo "   4. ./dev-backend.sh     (Go server)"
fi

echo ""