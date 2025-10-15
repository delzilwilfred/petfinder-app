#!/usr/bin/env bash
# monitor.sh - Basic log monitor + alerting + rotation
# Usage: sudo ./monitor.sh /var/log/petfinder.log


LOG_FILE=${1:-/var/log/petfinder.log}
ALERT_FILE=/var/log/petfinder_alerts.log
TEMP_LOG=/tmp/petfinder_monitor.tmp
THRESHOLD=5 # errors
WINDOW_SECONDS=60 # 1 minute
ROTATE_SIZE=$((1024*1024*5)) # 5MB


mkdir -p $(dirname "$ALERT_FILE")


# Ensure log exists
touch "$LOG_FILE"


# tail the log and process lines
# This implementation will run continuously; run under systemd or screen in background


while true; do
# capture current timestamp and check how many 5xx entries in last WINDOW_SECONDS
end_ts=$(date +%s)
start_ts=$((end_ts - WINDOW_SECONDS))


# use awk to filter lines by timestamps if log has ISO timestamps; fallback: scan last N lines
# Here we use a simple heuristic: check last 1000 lines for " 5xx " or "HTTP/1.1" 500
count=$(tail -n 1000 "$LOG_FILE" | egrep -c "\b5[0-9]{2}\b|HTTP/1\.[01]\"\s+500|status\s*:\s*500")


if [ "$count" -ge "$THRESHOLD" ]; then
echo "$(date -Iseconds) ALERT: High error rate detected: $count errors in last ${WINDOW_SECONDS}s" | tee -a "$ALERT_FILE"
fi


# Log rotation
filesize=$(stat -c%s "$LOG_FILE" 2>/dev/null || echo 0)
if [ "$filesize" -ge "$ROTATE_SIZE" ]; then
mv "$LOG_FILE" "$LOG_FILE.$(date +%Y%m%d%H%M%S)"
gzip -9 "$LOG_FILE."* || true
touch "$LOG_FILE"
echo "$(date -Iseconds) INFO: Rotated log" >> "$ALERT_FILE"
fi


sleep 10
done
