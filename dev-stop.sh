#!/bin/bash

# Shuffle Development Environment Stop Script
# This script stops all Docker services

echo "🛑 Stopping Shuffle Development Environment"
echo "=========================================="

# Stop Docker services
echo "🐳 Stopping Docker services..."
docker-compose -f docker-compose.dev.yml down

# Optional: Clean up
read -p "🗑️  Do you want to remove volumes (this will delete database data)? [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker-compose -f docker-compose.dev.yml down -v
    echo "✅ Volumes removed"
fi

echo "✅ Development environment stopped"
echo ""
echo "💡 To start again, run: ./dev-start.sh"