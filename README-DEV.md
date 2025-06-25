# Shuffle Local Development Quick Start

This guide helps you quickly set up Shuffle for local development with frontend and backend running locally, while other services run in Docker.

## 🚀 One-Command Setup

```bash
# 1. Install Docker and dependencies
./install-docker.sh

# 2. Start development environment
./dev-start.sh
```

## 📋 Available Scripts

| Script | Purpose |
|--------|---------|
| `./install-docker.sh` | Install Docker, Go, and setup system requirements |
| `./dev-start.sh` | Start Docker services (OpenSearch + Orborus) |
| `./dev-stop.sh` | Stop all Docker services |
| `./dev-frontend.sh` | Start frontend development server |
| `./dev-backend.sh` | Start backend development server |
| `./dev-status.sh` | Show current status of development environment |

## 🔄 Development Workflow

### Initial Setup
```bash
# Install everything
./install-docker.sh

# Start Docker services
./dev-start.sh
```

### Daily Development (3 terminals)

**Terminal 1 - Docker Services:**
```bash
./dev-start.sh  # Start once, keeps running
```

**Terminal 2 - Frontend:**
```bash
./dev-frontend.sh  # React dev server on :3000
```

**Terminal 3 - Backend:**
```bash
./dev-backend.sh   # Go server on :5001
```

## 🌐 Access Points

- **Frontend**: http://localhost:3000 (React dev server)
- **Backend API**: http://localhost:5001 (Go server)
- **Backend Health**: http://localhost:5001/api/v1/health
- **OpenSearch**: http://localhost:9200 (Database)

## 🛠️ Manual Commands

If you prefer running commands manually:

```bash
# Start Docker services
docker-compose -f docker-compose.dev.yml up -d

# Frontend development
cd frontend
npm install --legacy-peer-deps
npm start

# Backend development (separate terminal)
cd backend/go-app
go mod download
go run main.go
```

## 🔍 Check Status

Use the status script to check your development environment:

```bash
./dev-status.sh
```

This shows:
- ✅ System requirements (Docker, Node.js, Go)
- ✅ Running services and ports
- ✅ Configuration files
- ✅ Development dependencies
- 💡 Next steps if something is missing

## 🐛 Troubleshooting

### Docker Issues
```bash
# Check Docker status
docker ps

# View logs
docker-compose -f docker-compose.dev.yml logs -f

# Restart services
./dev-stop.sh && ./dev-start.sh
```

### Permission Issues
```bash
# Fix database permissions
sudo chown -R 1000:1000 shuffle-database

# Add user to docker group
sudo usermod -aG docker $USER
# Then log out and back in
```

### System Requirements
```bash
# OpenSearch requirements
sudo sysctl -w vm.max_map_count=262144
sudo swapoff -a
```

### Port Conflicts
Make sure these ports are available:
- 3000 (Frontend)
- 5001 (Backend)
- 9200 (OpenSearch)

## 📁 Project Structure

```
/home/pt/Shuffle/
├── install-docker.sh      # Install Docker & dependencies
├── dev-start.sh          # Start Docker services
├── dev-stop.sh           # Stop Docker services  
├── dev-frontend.sh       # Frontend dev server
├── dev-backend.sh        # Backend dev server
├── docker-compose.dev.yml # Docker services only
├── LOCAL_DEV_SETUP.md    # Detailed setup guide
├── frontend/             # React application
├── backend/go-app/       # Go backend server
├── shuffle-database/     # OpenSearch data
├── shuffle-apps/         # Custom apps
└── shuffle-files/        # File storage
```

## 🎯 Development Tips

1. **Hot Reload**: Frontend changes are automatically reflected
2. **Backend Changes**: Restart backend server after Go code changes
3. **Database**: OpenSearch data persists in `shuffle-database/`
4. **Logs**: Use `docker-compose -f docker-compose.dev.yml logs -f` for service logs
5. **Clean Start**: Use `./dev-stop.sh` then `./dev-start.sh` to restart everything

## 📚 Next Steps

1. Visit http://localhost:3000 to access Shuffle
2. Create an admin account
3. Start building workflows!
4. Check the main documentation at https://shuffler.io/docs