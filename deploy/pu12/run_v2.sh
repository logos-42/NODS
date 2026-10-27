#!/bin/bash
# 启动 PU-12 v2（实体宇宙：自主学习升频 + 高维屏蔽降频体验）—— 默认 GPU 3（leo 独占）
set -e
cd /work/liuyuanjie/pu12 || exit 1
mkdir -p logs_v2
export CUDA_VISIBLE_DEVICES="${GPU:-3}"
export PYTHONPATH=/work/liuyuanjie/pylibs:/work/liuyuanjie/pipdir

if [ -f pu12v2.pid ] && kill -0 "$(cat pu12v2.pid)" 2>/dev/null; then
  echo "already running: pid $(cat pu12v2.pid)"
  exit 0
fi

B="${B:-16384}"
RATE="${RATE:-0.005}"
PHASES="${PHASES:-16}"
LOG_EVERY="${LOG_EVERY:-200}"
EXPLORE="${EXPLORE:-0.03}"

setsid nohup python3 -u scripts/pu12_v2.py \
  --device cuda --B "$B" --rate "$RATE" --phases "$PHASES" \
  --explore "$EXPLORE" --log-every "$LOG_EVERY" --ticks 0 --out logs_v2 \
  > logs_v2/stdout.log 2>&1 < /dev/null &
echo $! > pu12v2.pid
sleep 5
echo "started v2 pid $(cat pu12v2.pid)  GPU=$CUDA_VISIBLE_DEVICES  B=$B rate=$RATE"
tail -3 logs_v2/stdout.log 2>/dev/null || true
