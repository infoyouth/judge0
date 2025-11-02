#!/bin/bash
set -e

# Start Redis server in background (if not already running externally)
if [ -z "$REDIS_HOST" ] || [ "$REDIS_HOST" = "localhost" ] || [ "$REDIS_HOST" = "127.0.0.1" ]; then
    echo "Starting Redis server..."
    redis-server --daemonize yes --bind 127.0.0.1
    REDIS_PID=$!
fi

# Lightweight in-process scheduler to replace system cron.
# It runs two background loops:
#  - clear_cache: daily (every 24h)
#  - telemetry: every 12h (only if JUDGE0_TELEMETRY_ENABLE is not "false")

start_schedulers() {
    # Background: clear cache once every 24 hours
    (
        cd /api || exit 0
        # load environment if present
        [ -f /api/environment ] && source /api/environment || true
        while true; do
            # Run rake task (safe to fail)
            RAILS_ENV=${RAILS_ENV:-production} bundle exec rake judge0:clear_cache &> ./log/clear_cache.log || true
            # Sleep 24 hours
            sleep 86400
        done
    ) &
    SCHED_CLEAR_PID=$!

    # Background: telemetry every 12 hours (respect JUDGE0_TELEMETRY_ENABLE)
    (
        cd /api || exit 0
        [ -f /api/environment ] && source /api/environment || true
        while true; do
            if [ "${JUDGE0_TELEMETRY_ENABLE:-true}" != "false" ]; then
                ./bin/telemetry &> ./log/telemetry.log || true
            fi
            sleep 43200
        done
    ) &
    SCHED_TELE_PID=$!
}

# Function to handle shutdown
shutdown_handler() {
        echo "Shutting down..."
        # Kill scheduler background processes if started
        [ -n "$SCHED_CLEAR_PID" ] && kill "$SCHED_CLEAR_PID" 2>/dev/null || true
        [ -n "$SCHED_TELE_PID" ] && kill "$SCHED_TELE_PID" 2>/dev/null || true
        # Kill main app if running
        [ -n "$MAIN_PID" ] && kill "$MAIN_PID" 2>/dev/null || true
        # Kill Redis if we started it
        [ -n "$REDIS_PID" ] && kill "$REDIS_PID" 2>/dev/null || true
        wait
        exit 0
}

# Setup signal handlers
trap shutdown_handler SIGTERM SIGINT

# Start background schedulers
start_schedulers

# Start the main application
"$@" &
MAIN_PID=$!

# Wait for the main application to exit (or for any background process to die)
wait -n $MAIN_PID
exit $?
