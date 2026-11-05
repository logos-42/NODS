#!/usr/bin/env bash
# b9 组件替换消融矩阵：等 b7/b8 结束后顺序跑 6 个配置
set -u
cd "$(dirname "$0")" 2>/dev/null || cd /work/liuyuanjie/pu12
export OMP_NUM_THREADS=${OMP_NUM_THREADS:-4}
export MKL_NUM_THREADS=${MKL_NUM_THREADS:-4}
export PYTHONPATH=/work/liuyuanjie/pylibs:/work/liuyuanjie/pipdir
GPU=${GPU:-2}
OUT=${OUT:-logs_b9}

echo "=== [b9] waiting for b7/b8 $(date '+%F %T') ==="
while pgrep -f "[b]7_world2d.py|[b]8_jepa.py" > /dev/null 2>&1; do sleep 60; done
echo "=== [b9] start ablation matrix $(date '+%F %T') ==="

for c in c0_flat c1_spatial_frozen c2_spatial_joint c3_temporal_frozen c4_temporal_joint c5_temporal_her; do
  echo "--- [b9] $c $(date '+%F %T') ---"
  CUDA_VISIBLE_DEVICES=$GPU python3 -u scripts/pu12_v33_b9_jepa_ablate.py \
    --config "$c" --device cuda --seed 0 \
    --ssl-steps 3000 --ssl-batch 256 --rl-batch 1024 \
    --segs 120 --seg-ticks 500 --eval-every 20 --eval-budget 120 \
    --out "$OUT/$c" || echo "--- [b9] $c FAILED ---"
done
echo "=== [b9] ALL DONE $(date '+%F %T') ==="
