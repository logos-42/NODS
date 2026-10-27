#!/bin/bash
# 启动 PU-12 宇宙模拟（默认 GPU 3 —— 该卡由 leo 独占；0/1/2 被别的任务占着）
set -e
cd /work/liuyuanjie/pu12 || exit 1
mkdir -p logs
export CUDA_VISIBLE_DEVICES="${GPU:-3}"
export PYTHONPATH=/work/liuyuanjie/pipdir

if [ -f pu12.pid ] && kill -0 "$(cat pu12.pid)" 2>/dev/null; then
  echo "already running: pid $(cat pu12.pid)"
  exit 0
fi

B="${B:-4096}"
MATURE="${MATURE:-3000}"
DWELL="${DWELL:-500}"
PHASES="${PHASES:-64}"
LOG_EVERY="${LOG_EVERY:-200}"

setsid nohup python3 scripts/pu12_gpu.py \
  --device cuda --B "$B" --mature "$MATURE" --dwell "$DWELL" --phases "$PHASES" \
  --log-every "$LOG_EVERY" --ticks 0 --out logs \
  > logs/stdout.log 2>&1 < /dev/null &
echo $! > pu12.pid
sleep 3
echo "started pid $(cat pu12.pid)  GPU=$CUDA_VISIBLE_DEVICES  B=$B mature=$MATURE"
tail -3 logs/stdout.log 2>/dev/null || true
