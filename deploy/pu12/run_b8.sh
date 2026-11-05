#!/usr/bin/env bash
# b8 MU-JEPA：等 b7 跑完后自动执行（预训练 -> 表征探针 -> 冻结编码器学 Q）
set -u
cd "$(dirname "$0")" 2>/dev/null || cd /work/liuyuanjie/pu12
export OMP_NUM_THREADS=${OMP_NUM_THREADS:-4}
export MKL_NUM_THREADS=${MKL_NUM_THREADS:-4}
export PYTHONPATH=/work/liuyuanjie/pylibs:/work/liuyuanjie/pipdir
GPU=${GPU:-2}
OUT=${OUT:-logs_b8}

echo "=== [b8] waiting for b7 to finish $(date '+%F %T') ==="
while pgrep -f "[b]7_world2d.py" > /dev/null 2>&1; do sleep 60; done
echo "=== [b8] b7 done, start MU-JEPA $(date '+%F %T') ==="

CUDA_VISIBLE_DEVICES=$GPU python3 -u scripts/pu12_v33_b8_jepa.py \
  --phase pretrain --device cuda --seed 0 \
  --ssl-steps 4000 --ssl-batch 256 --lr 3e-4 \
  --var-lambda 1.0 --var-gamma 1.0 --out "$OUT"

CUDA_VISIBLE_DEVICES=$GPU python3 -u scripts/pu12_v33_b8_jepa.py \
  --phase probe --device cuda --out "$OUT"

CUDA_VISIBLE_DEVICES=$GPU python3 -u scripts/pu12_v33_b8_jepa.py \
  --phase rl --device cuda --seed 0 --rl-batch 1024 \
  --segs 120 --seg-ticks 500 --eval-every 10 --eval-budget 120 --out "$OUT"

echo "=== [b8] ALL DONE $(date '+%F %T') ==="
