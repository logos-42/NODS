#!/bin/bash
# 启动 PU-12 v3.2（多层格点宇宙，地址深度放开到 204 位 12 进制）—— 默认 GPU 3
set -e
cd /work/liuyuanjie/pu12 || exit 1
mkdir -p logs_v32
export CUDA_VISIBLE_DEVICES="${GPU:-3}"
export PYTHONPATH=/work/liuyuanjie/pylibs:/work/liuyuanjie/pipdir

if [ -f pu12v32.pid ] && kill -0 "$(cat pu12v32.pid)" 2>/dev/null; then
  echo "already running: pid $(cat pu12v32.pid)"
  exit 0
fi

B="${B:-16384}"
RATE="${RATE:-0.05}"
PHASES="${PHASES:-16}"
LOG_EVERY="${LOG_EVERY:-200}"
EXPLORE="${EXPLORE:-0.05}"
ANNEAL="${ANNEAL:-6000}"
DEPTH0="${DEPTH0:-2}"
WINDOW="${WINDOW:-64}"

setsid nohup python3 -u scripts/pu12_v32.py \
  --device cuda --B "$B" --rate "$RATE" --phases "$PHASES" --depth0 "$DEPTH0" \
  --window "$WINDOW" --explore "$EXPLORE" --anneal "$ANNEAL" \
  --log-every "$LOG_EVERY" --ticks 0 --out logs_v32 \
  > logs_v32/stdout.log 2>&1 < /dev/null &
echo $! > pu12v32.pid
sleep 6
echo "started v3.2 pid $(cat pu12v32.pid)  GPU=$CUDA_VISIBLE_DEVICES  B=$B rate=$RATE window=$WINDOW"
tail -4 logs_v32/stdout.log 2>/dev/null || true
