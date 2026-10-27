#!/bin/bash
# 一条命令拉起 PU-12 v3.2（多层格点宇宙（深度放开） + 看门狗），幂等。容器重启后用这个恢复。
cd /work/liuyuanjie/pu12 || exit 1
mkdir -p logs_v32

bash run_v32.sh

if ! ps -eo cmd | grep -q "[w]atchdog_v3.sh"; then
  (setsid nohup bash watchdog_v32.sh > logs_v32/watchdog.boot.log 2>&1 < /dev/null &)
  sleep 1
  echo "watchdog v3.2 started"
else
  echo "watchdog v3 already running"
fi
