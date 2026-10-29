#!/bin/bash
# 持续迁移实验看门狗：进程消失就按 run_experiment.sh 重启；5 分钟内重启 >=3 次即放弃。
cd /work/liuyuanjie/pu12 || exit 1
LOG=logs_experiment/watchdog.log
mkdir -p logs_experiment
echo "$(date -Is) watchdog experiment up" >> "$LOG"
while true; do
  sleep 60
  PID=$(cat pu12exp.pid 2>/dev/null || echo "")
  if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then continue; fi
  NOW=$(date +%s)
  RECENT=$(awk -v now="$NOW" '$1 ~ /^[0-9]+$/ && now - $1 < 300 {c++} END {print c+0}' logs_experiment/watchdog.restarts 2>/dev/null || echo 0)
  if [ "$RECENT" -ge 3 ]; then
    echo "$(date -Is) GIVE UP: $RECENT restarts within 300s" >> "$LOG"
    exit 1
  fi
  echo "$NOW restart" >> logs_experiment/watchdog.restarts
  echo "$(date -Is) restarting experiment (old pid=${PID:-none})" >> "$LOG"
  bash run_experiment.sh >> "$LOG" 2>&1
done
