#!/bin/bash
# 启动 PU-12 v3.3（频率上限抬高到 10^81 / 地板 10^-19 / 20 带 / 实体×100）—— 默认 GPU 3
set -e
cd /work/liuyuanjie/pu12 || exit 1
mkdir -p logs_v33
export CUDA_VISIBLE_DEVICES="${GPU:-3}"
export PYTHONPATH=/work/liuyuanjie/pylibs:/work/liuyuanjie/pipdir

if [ -f pu12v33.pid ] && kill -0 "$(cat pu12v33.pid)" 2>/dev/null; then
  echo "already running: pid $(cat pu12v33.pid)"
  exit 0
fi

B="${B:-1638400}"        # 实体数：相对 v3.2 (16384) 提高两个数量级
RATE="${RATE:-0.05}"
PHASES="${PHASES:-16}"
LOG_EVERY="${LOG_EVERY:-200}"
EXPLORE="${EXPLORE:-0.05}"
ANNEAL="${ANNEAL:-6000}"
DEPTH0="${DEPTH0:-2}"
WINDOW="${WINDOW:-64}"

setsid nohup python3 -u scripts/pu12_v33.py \
  --device cuda --B "$B" --rate "$RATE" --phases "$PHASES" --depth0 "$DEPTH0" \
  --window "$WINDOW" --explore "$EXPLORE" --anneal "$ANNEAL" \
  --log-every "$LOG_EVERY" --ticks 0 --out logs_v33 \
  > logs_v33/stdout.log 2>&1 < /dev/null &
echo $! > pu12v33.pid
sleep 6
echo "started v3.3 pid $(cat pu12v33.pid)  GPU=$CUDA_VISIBLE_DEVICES  B=$B rate=$RATE window=$WINDOW"
tail -4 logs_v33/stdout.log 2>/dev/null || true
