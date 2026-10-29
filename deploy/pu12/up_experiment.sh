#!/bin/bash
# 一条命令拉起持续迁移实验 + 看门狗（幂等）。
# GPU 实验：DEVICE=cuda CUDA_VISIBLE_DEVICES=2 bash up_experiment.sh
#   （DEVICE/CUDA_VISIBLE_DEVICES 会透传给看门狗重启，保证不间断也在 GPU 上）
cd /work/liuyuanjie/pu12 || exit 1
mkdir -p logs_experiment
export DEVICE="${DEVICE:-cpu}"
export CUDA_VISIBLE_DEVICES="${CUDA_VISIBLE_DEVICES:-}"
bash run_experiment.sh
if ! ps -eo cmd | grep -q "[w]atchdog_experiment.sh"; then
  (setsid nohup bash watchdog_experiment.sh > logs_experiment/watchdog.boot.log 2>&1 < /dev/null &)
  sleep 1
  echo "watchdog experiment started"
else
  echo "watchdog experiment already running"
fi
