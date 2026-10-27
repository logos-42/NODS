#!/bin/bash
# 启动 PU-12 v3（多层格点宇宙：维度×子维度×亚维度×频率带，实体自主学习）—— 默认 GPU 3
set -e
cd /work/liuyuanjie/pu12 || exit 1
mkdir -p logs_v3
export CUDA_VISIBLE_DEVICES="${GPU:-3}"
export PYTHONPATH=/work/liuyuanjie/pylibs:/work/liuyuanjie/pipdir

if [ -f pu12v3.pid ] && kill -0 "$(cat pu12v3.pid)" 2>/dev/null; then
  echo "already running: pid $(cat pu12v3.pid)"
  exit 0
fi

B="${B:-16384}"
RATE="${RATE:-0.05}"
PHASES="${PHASES:-16}"
LOG_EVERY="${LOG_EVERY:-200}"
EXPLORE="${EXPLORE:-0.05}"
ANNEAL="${ANNEAL:-6000}"
DEPTH0="${DEPTH0:-2}"

setsid nohup python3 -u scripts/pu12_v3.py \
  --device cuda --B "$B" --rate "$RATE" --phases "$PHASES" --depth0 "$DEPTH0" \
  --explore "$EXPLORE" --anneal "$ANNEAL" --log-every "$LOG_EVERY" --ticks 0 --out logs_v3 \
  > logs_v3/stdout.log 2>&1 < /dev/null &
echo $! > pu12v3.pid
sleep 6
echo "started v3 pid $(cat pu12v3.pid)  GPU=$CUDA_VISIBLE_DEVICES  B=$B rate=$RATE anneal=$ANNEAL"
tail -4 logs_v3/stdout.log 2>/dev/null || true
