#!/bin/bash
set -e

# Setup required directories
mkdir -p /var/run/cron /var/lib/cron /var/log/cron
chmod 777 /var/run/cron /var/lib/cron /var/log/cron

# Start cron daemon in background
cron -f &
CRON_PID=$!

# Function to handle shutdown
shutdown_handler() {
    echo "Shutting down..."
    kill $CRON_PID
    wait $CRON_PID
    exit 0
}

# Setup signal handlers
trap shutdown_handler SIGTERM SIGINT

# Start the main application
"$@" &
MAIN_PID=$!

# Wait for either process to exit
wait -n $MAIN_PID $CRON_PID
exit $?
