#!/bin/bash
# PU-12 看门狗：模拟进程消失就按 run.sh 重启。
# 防崩溃循环：5 分钟内已重启 >=3 次则放弃（写 watchdog.log 后退出），不烧 GPU。
cd /work/liuyuanjie/pu12 || exit 1
LOG=logs/watchdog.log
mkdir -p logs
echo "$(date -Is) watchdog up (pgrep target: pu12_gpu.py)" >> "$LOG"

while true; do
  sleep 60
  PID=$(cat pu12.pid 2>/dev/null || echo "")
  if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
    continue
  fi
  NOW=$(date +%s)
  RECENT=$(awk -v now="$NOW" '$1 ~ /^[0-9]+$/ && now - $1 < 300 {c++} END {print c+0}' logs/watchdog.restarts 2>/dev/null || echo 0)
  if [ "$RECENT" -ge 3 ]; then
    echo "$(date -Is) GIVE UP: $RECENT restarts within 300s — 需要人工看 logs/stdout.log" >> "$LOG"
    exit 1
  fi
  echo "$NOW restart" >> logs/watchdog.restarts
  echo "$(date -Is) restarting (old pid=${PID:-none})" >> "$LOG"
  bash run.sh >> "$LOG" 2>&1
done
