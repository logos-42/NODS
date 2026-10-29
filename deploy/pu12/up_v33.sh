#!/bin/bash
# 一条命令拉起 PU-12 v3.3（频率上限抬高版 + 看门狗），幂等。容器重启后用这个恢复。
cd /work/liuyuanjie/pu12 || exit 1
mkdir -p logs_v33

bash run_v33.sh

if ! ps -eo cmd | grep -q "[w]atchdog_v33.sh"; then
  (setsid nohup bash watchdog_v33.sh > logs_v33/watchdog.boot.log 2>&1 < /dev/null &)
  sleep 1
  echo "watchdog v3.3 started"
else
  echo "watchdog v3.3 already running"
fi
