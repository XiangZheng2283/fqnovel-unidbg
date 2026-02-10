#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

INTERVAL_SECONDS="${INTERVAL_SECONDS:-1800}"   # 30 min
LOG_FILE="${LOG_FILE:-target/auto-restart-30m.log}"
LOCK_FILE="${LOCK_FILE:-/tmp/fqnovel_restart_30m.lock}"

mkdir -p target

if [ -f "$LOCK_FILE" ]; then
  OLD_PID="$(cat "$LOCK_FILE" 2>/dev/null || true)"
  if [ -n "${OLD_PID:-}" ] && kill -0 "$OLD_PID" 2>/dev/null; then
    echo "[$(date)] already running. pid=$OLD_PID"
    exit 1
  fi
fi

echo $$ > "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT

echo "[$(date)] restart loop started. interval=${INTERVAL_SECONDS}s" | tee -a "$LOG_FILE"

while true; do
  echo "[$(date)] run restart.sh" | tee -a "$LOG_FILE"
  if bash ./restart.sh >> "$LOG_FILE" 2>&1; then
    echo "[$(date)] restart.sh finished successfully" | tee -a "$LOG_FILE"
  else
    echo "[$(date)] restart.sh failed, continue next round" | tee -a "$LOG_FILE"
  fi

  echo "[$(date)] sleep ${INTERVAL_SECONDS}s" | tee -a "$LOG_FILE"
  sleep "$INTERVAL_SECONDS"
done

