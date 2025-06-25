#!/bin/bash

# Shuffle Hot Reload Development Script
# Starts both frontend and backend with hot reload enabled

set -e

echo "🔥 Starting Shuffle Development Environment with Hot Reload"
echo "=========================================================="

# Check if tmux is available for running multiple processes
if ! command -v tmux &> /dev/null; then
    echo "⚠️  tmux not found, starting processes sequentially"
    echo "   Install tmux for better development experience: sudo apt install tmux"
    echo ""
    
    echo "Starting backend with hot reload..."
    echo "Press Ctrl+C and run './dev-frontend.sh' in another terminal"
    ./dev-backend.sh
else
    echo "🚀 Starting both frontend and backend with hot reload in tmux session..."
    echo ""
    echo "📖 Tmux Commands:"
    echo "   • Ctrl+B then 0: Switch to backend pane"
    echo "   • Ctrl+B then 1: Switch to frontend pane" 
    echo "   • Ctrl+B then d: Detach from session"
    echo "   • tmux attach -t shuffle-dev: Reattach to session"
    echo "   • Ctrl+C in each pane: Stop services"
    echo ""
    
    # Kill existing session if it exists
    tmux kill-session -t shuffle-dev 2>/dev/null || true
    
    # Create new tmux session with backend
    tmux new-session -d -s shuffle-dev -n "backend" "./dev-backend.sh"
    
    # Create new window for frontend
    tmux new-window -t shuffle-dev -n "frontend" "./dev-frontend.sh"
    
    # Attach to the session
    tmux attach-session -t shuffle-dev
fi