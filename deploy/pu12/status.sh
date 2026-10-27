#!/bin/bash
# PU-12 运行状态一览（给 leo 看「发展情况」）
cd /work/liuyuanjie/pu12 || exit 1
echo "== pid =="
if [ -f pu12.pid ] && kill -0 "$(cat pu12.pid)" 2>/dev/null; then
  echo "running $(cat pu12.pid)  $(ps -o etime= -p "$(cat pu12.pid)")"
else
  echo "NOT running"
fi
echo "== gpu =="
nvidia-smi --query-gpu=index,memory.used,utilization.gpu --format=csv,noheader
echo "== latest =="
tail -5 logs/stdout.log 2>/dev/null
echo "== status.json =="
cat logs/status.json 2>/dev/null
echo
echo "== log lines =="
wc -l logs/run-*.jsonl 2>/dev/null
