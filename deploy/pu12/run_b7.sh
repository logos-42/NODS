#!/usr/bin/env bash
# b7 升维世界：三组顺序跑（限线程，避免打满容器 CPU）
#   1) W1 point  + her      —— 二维相对抽象能否自发涌现
#   2) W1 point  + vanilla  —— 对照
#   3) W2 seq    + her      —— 相对抽象的边界（部分可观测，需记忆）
set -u
cd "$(dirname "$0")" 2>/dev/null || cd /work/liuyuanjie/pu12
export OMP_NUM_THREADS=${OMP_NUM_THREADS:-4}
export MKL_NUM_THREADS=${MKL_NUM_THREADS:-4}
export PYTHONPATH=/work/liuyuanjie/pylibs:/work/liuyuanjie/pipdir
DEV=${DEV:-cuda}
GPU=${GPU:-2}
B=${B:-4096}

run() {
  name=$1; task=$2; pressure=$3
  echo "=== [b7] start $name ($task/$pressure) $(date '+%F %T') ==="
  CUDA_VISIBLE_DEVICES=$GPU python3 -u scripts/pu12_v33_b7_world2d.py \
    --task "$task" --pressure "$pressure" --B "$B" --device "$DEV" \
    --seg-ticks 5000 --segs 200 --eval-every 10 --eval-budget 120 \
    --out "logs_b7/$name"
  echo "=== [b7] done $name $(date '+%F %T') ==="
}

run w1_point_her     point     her
run w1_point_vanilla point     vanilla
run w2_seq_her       sequence  her
echo "=== [b7] ALL DONE $(date '+%F %T') ==="
