# Local Development Setup Guide

This guide helps you run Frontend and Backend locally while keeping other services in Docker.

## Prerequisites

1. **Docker** - for running OpenSearch, Orborus, and other services
2. **Node.js & npm** - for frontend development
3. **Go 1.24+** - for backend development

## Step 1: Start Required Docker Services

Create a custom docker-compose file for just the services you need:

```yaml
# docker-compose.dev.yml
services:
  opensearch:
    image: opensearchproject/opensearch:3.0.0
    hostname: shuffle-opensearch
    container_name: shuffle-opensearch
    environment:
      - "OPENSEARCH_JAVA_OPTS=-Xms4096m -Xmx4096m"
      - bootstrap.memory_lock=true
      - DISABLE_PERFORMANCE_ANALYZER_AGENT_CLI=true
      - cluster.initial_master_nodes=shuffle-opensearch
      - cluster.routing.allocation.disk.threshold_enabled=false
      - cluster.name=shuffle-cluster
      - node.name=shuffle-opensearch
      - node.store.allow_mmap=false
      - discovery.seed_hosts=shuffle-opensearch
      - OPENSEARCH_INITIAL_ADMIN_PASSWORD=${SHUFFLE_OPENSEARCH_PASSWORD}
    ulimits:
      memlock:
        soft: -1
        hard: -1
      nofile:
        soft: 65536 
        hard: 65536
    volumes:
      - shuffle-database:/usr/share/opensearch/data:z
    ports:
      - 9200:9200
    networks:
      - shuffle
    restart: unless-stopped

  orborus:
    image: ghcr.io/shuffle/shuffle-orborus:latest
    container_name: shuffle-orborus
    hostname: shuffle-orborus
    networks:
      - shuffle
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - SHUFFLE_APP_SDK_TIMEOUT=300
      - SHUFFLE_ORBORUS_EXECUTION_CONCURRENCY=7
      - ENVIRONMENT_NAME=Shuffle
      - ORG_ID=Shuffle
      - BASE_URL=http://localhost:5001  # Point to local backend
      - DOCKER_API_VERSION=1.40
      - SHUFFLE_STATS_DISABLED=true
      - SHUFFLE_LOGS_DISABLED=true
      - SHUFFLE_SWARM_CONFIG=run
      - SHUFFLE_WORKER_IMAGE=ghcr.io/shuffle/shuffle-worker:latest
    env_file: .env
    restart: unless-stopped
    security_opt:
      - seccomp:unconfined

volumes:
  shuffle-database:
    driver: local
    driver_opts:
      type: none
      device: ${DB_LOCATION}
      o: bind

networks:
  shuffle:
    driver: bridge
```

Start the services:
```bash
# Prepare the database directory
mkdir -p shuffle-database
sudo chown -R 1000:1000 shuffle-database

# Set system requirements for OpenSearch
sudo sysctl -w vm.max_map_count=262144
sudo swapoff -a

# Start the services
docker-compose -f docker-compose.dev.yml up -d
```

## Step 2: Setup Frontend Development

```bash
cd frontend

# Install dependencies (use legacy peer deps due to React version conflicts)
npm install --legacy-peer-deps

# Start development server
npm start
```

The frontend will run on http://localhost:3000

## Step 3: Setup Backend Development

```bash
cd backend/go-app

# Install dependencies
go mod download

# Set environment variables for local development
export SHUFFLE_APP_HOTLOAD_FOLDER=/home/pt/Shuffle/shuffle-apps
export SHUFFLE_FILE_LOCATION=/home/pt/Shuffle/shuffle-files
export DATASTORE_EMULATOR_HOST=localhost:9200  # Point to local OpenSearch

# Run the backend server
go run main.go
```

The backend will run on http://localhost:5001

## Step 4: Environment Configuration

Update your `.env` file for local development:

```bash
# .env
BACKEND_HOSTNAME=localhost
BACKEND_PORT=5001
FRONTEND_PORT=3000
FRONTEND_PORT_HTTPS=3443
OUTER_HOSTNAME=localhost
SHUFFLE_APP_HOTLOAD_LOCATION=/home/pt/Shuffle/shuffle-apps
SHUFFLE_FILE_LOCATION=/home/pt/Shuffle/shuffle-files
DB_LOCATION=/home/pt/Shuffle/shuffle-database
SHUFFLE_OPENSEARCH_PASSWORD=StrongPassword123!
```

## Step 5: Verify Setup

1. **Frontend**: Visit http://localhost:3000 - should show Shuffle login page
2. **Backend**: Visit http://localhost:5001/api/v1/health - should return API health status
3. **OpenSearch**: Visit http://localhost:9200 - should show OpenSearch cluster info
4. **Integration**: Create an account and test workflow creation

## Development Workflow

### Frontend Changes
- Frontend runs with hot reload at http://localhost:3000
- Changes to React components are automatically reflected
- Use `npm run lint` to check code quality

### Backend Changes  
- Backend requires manual restart after Go code changes
- Use `go run main.go` to restart after changes
- Use `go test` to run backend tests

### Building for Production
```bash
# Build frontend
cd frontend && npm run build

# The build script copies the built frontend to backend/go-app/build/
./build.sh

# Build backend
cd backend/go-app && go build
```

## Troubleshooting

1. **Port conflicts**: Ensure ports 3000, 5001, and 9200 are available
2. **OpenSearch issues**: Check that vm.max_map_count is set correctly
3. **Go dependencies**: Run `go mod tidy` if you encounter module issues
4. **React version conflicts**: Always use `--legacy-peer-deps` with npm
5. **Docker socket**: Ensure Orborus can access Docker socket for app execution

## Useful Commands

```bash
# Check running containers
docker ps

# View logs
docker-compose -f docker-compose.dev.yml logs -f

# Stop services
docker-compose -f docker-compose.dev.yml down

# Frontend linting
cd frontend && npm run lint

# Backend testing
cd backend/go-app && go test
```