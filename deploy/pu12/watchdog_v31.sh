#!/bin/bash
# PU-12 v3.1 看门狗：进程消失就按 run_v31.sh 重启；5 分钟内重启 >=3 次即放弃（防崩溃循环）。
cd /work/liuyuanjie/pu12 || exit 1
LOG=logs_v31/watchdog.log
mkdir -p logs_v31
echo "$(date -Is) watchdog v3.1 up" >> "$LOG"

while true; do
  sleep 60
  PID=$(cat pu12v31.pid 2>/dev/null || echo "")
  if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
    continue
  fi
  NOW=$(date +%s)
  RECENT=$(awk -v now="$NOW" '$1 ~ /^[0-9]+$/ && now - $1 < 300 {c++} END {print c+0}' logs_v31/watchdog.restarts 2>/dev/null || echo 0)
  if [ "$RECENT" -ge 3 ]; then
    echo "$(date -Is) GIVE UP: $RECENT restarts within 300s — 需要人工看 logs_v31/stdout.log" >> "$LOG"
    exit 1
  fi
  echo "$NOW restart" >> logs_v31/watchdog.restarts
  echo "$(date -Is) restarting v3.1 (old pid=${PID:-none})" >> "$LOG"
  bash run_v31.sh >> "$LOG" 2>&1
done
