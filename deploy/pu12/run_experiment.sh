#!/bin/bash
# 启动 PU-12 v3.3 持续迁移实验。默认 CPU；GPU 实验传 DEVICE=cuda CUDA_VISIBLE_DEVICES=<n>。
cd /work/liuyuanjie/pu12 || exit 1
mkdir -p logs_experiment
export PYTHONPATH=/work/liuyuanjie/pylibs:/work/liuyuanjie/pipdir
export CUDA_VISIBLE_DEVICES="${CUDA_VISIBLE_DEVICES:-}"
DEVICE="${DEVICE:-cpu}"

if [ -f pu12exp.pid ] && kill -0 "$(cat pu12exp.pid)" 2>/dev/null; then
  echo "experiment already running: pid $(cat pu12exp.pid)"
  exit 0
fi

SCHED="${SCHED:-18,15,12,8,5,10}"   # 兼容目标(高带)在前，挑战目标(低带)在后
EVERY="${EVERY:-7200}"              # 每 2 小时做一次迁移探针
SEG="${SEG:-30000}"                 # 每个迁移目标训练拍数
PTRAIN="${PTRAIN:-60000}"           # 探针里冷/热启动最大训练拍数
B="${B:-1024}"

setsid nohup python3 -u scripts/pu12_v33_experiment.py \
  --B "$B" --device "$DEVICE" --schedule "$SCHED" --seg-ticks "$SEG" \
  --probe-every-seconds "$EVERY" --probe-train-ticks "$PTRAIN" \
  --out logs_experiment \
  > logs_experiment/stdout.log 2>&1 < /dev/null &
echo $! > pu12exp.pid
sleep 5
echo "started experiment pid $(cat pu12exp.pid)  device=$DEVICE CUDA=${CUDA_VISIBLE_DEVICES:-cpu} B=$B sched=$SCHED"
tail -3 logs_experiment/stdout.log 2>/dev/null || true
