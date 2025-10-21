#!/bin/bash

echo "Starting Fund Management UI Apps..."

# Function to start an app in the background
start_app() {
    local app_name=$1
    local port=$2
    local dir=$3
    
    echo "Starting $app_name on port $port..."
    cd "$dir"
    npm start &
    local pid=$!
    echo "$app_name started with PID $pid on port $port"
    echo $pid > "${app_name}.pid"
}

# Start both apps
start_app "fund-manager" "3001" "fund-manager-app"
start_app "beneficiary" "3002" "beneficiary-app"

echo ""
echo "Both apps are starting up..."
echo "Fund Manager App: http://localhost:3001"
echo "Beneficiary App: http://localhost:3002"
echo ""
echo "To stop the apps, run: ./stop-apps.sh"
echo "Or manually kill the processes using the PIDs in the .pid files"

