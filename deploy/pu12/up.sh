#!/bin/bash
# 一条命令拉起 PU-12（模拟 + 看门狗），幂等：已在跑就不重复起。
# 容器重启后用这个恢复：bash /work/liuyuanjie/pu12/up.sh
cd /work/liuyuanjie/pu12 || exit 1
mkdir -p logs

bash run.sh

if ! ps -eo cmd | grep -q "[w]atchdog.sh"; then
  (setsid nohup bash watchdog.sh > logs/watchdog.boot.log 2>&1 < /dev/null &)
  sleep 1
  echo "watchdog started"
else
  echo "watchdog already running"
fi
