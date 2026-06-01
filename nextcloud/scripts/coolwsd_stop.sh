#!/data/data/com.termux/files/usr/bin/bash
# Detiene el servidor Collabora CODE
PIDFILE="/data/data/com.termux/files/home/nextcloud_data/tmp/coolwsd.pid"
LOG="/data/data/com.termux/files/home/logs/coolwsd.log"

echo "[$(date)] ===== coolwsd_stop.sh =====" >> "$LOG"

if [ -f "$PIDFILE" ]; then
  PID=$(cat "$PIDFILE")
  if kill -0 "$PID" 2>/dev/null; then
    kill -15 "$PID" 2>/dev/null
    echo "[$(date)] coolwsd detenido (PID: $PID)" >> "$LOG"
    for i in $(seq 1 10); do
      kill -0 "$PID" 2>/dev/null || break
      sleep 1
    done
    kill -9 "$PID" 2>/dev/null
  fi
  rm -f "$PIDFILE"
else
  pkill -15 coolwsd 2>/dev/null
  echo "[$(date)] coolwsd detenido (pkill)" >> "$LOG"
fi
sleep 1
pkill -15 coolforkit-ns 2>/dev/null
pkill -9 coolforkit 2>/dev/null
exit 0