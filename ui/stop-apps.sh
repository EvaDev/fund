#!/bin/bash

echo "Stopping Fund Management UI Apps..."

# Function to stop an app
stop_app() {
    local app_name=$1
    local pid_file="${app_name}.pid"
    
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            echo "Stopping $app_name (PID: $pid)..."
            kill "$pid"
            rm "$pid_file"
            echo "$app_name stopped"
        else
            echo "$app_name was not running"
            rm "$pid_file"
        fi
    else
        echo "No PID file found for $app_name"
    fi
}

# Stop both apps
stop_app "fund-manager"
stop_app "beneficiary"

# Also kill any remaining vite processes
pkill -f "vite --port" 2>/dev/null || true

echo "All apps stopped"

