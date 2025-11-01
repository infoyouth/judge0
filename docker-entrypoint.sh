#!/bin/bash
# Start cron service
/usr/sbin/cron
exec "$@"
