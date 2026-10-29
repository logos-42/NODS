#!/bin/bash
# PU-12 v3.3 镜像 benchmark（对照版智能探针）：CPU 小样本即可，不需要 GPU。
# 用法：bash run_mirror.sh            （默认 B=1024, 训练 40000 拍）
#       B=2048 TICKS=60000 bash run_mirror.sh
cd /work/liuyuanjie/pu12 || exit 1
mkdir -p logs_mirror
export PYTHONPATH=/work/liuyuanjie/pylibs:/work/liuyuanjie/pipdir

B="${B:-1024}"
TICKS="${TICKS:-80000}"
GOAL="${GOAL:-10}"
SEED="${SEED:-0}"

echo "== mirror benchmark: B=$B TICKS=$TICKS GOAL=$GOAL SEED=$SEED =="
python3 -u scripts/pu12_v33_mirror.py \
  --B "$B" --train-ticks "$TICKS" --goal-k "$GOAL" --seed "$SEED" --device cpu \
  --out logs_mirror 2>&1 | tee logs_mirror/run.log
echo "== done -> logs_mirror/benchmark.json =="
