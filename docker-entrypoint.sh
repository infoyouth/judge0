#!/bin/bash

# Ensure cron directories exist with correct permissions
mkdir -p /var/run/cron
chown judge0:judge0 /var/run/cron

# Start cron service
/usr/sbin/cron -f &

# Execute the main command
exec "$@"
