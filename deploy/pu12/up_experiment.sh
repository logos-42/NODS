#!/bin/bash
# 一条命令拉起持续迁移实验 + 看门狗（幂等）。
# GPU 实验：DEVICE=cuda CUDA_VISIBLE_DEVICES=2 bash up_experiment.sh
# 变体：OUT=logs_experiment_v2 PIDF=pu12exp_v2.pid RESET=1 SEG=60000 PTRAIN=90000 bash up_experiment.sh
cd /work/liuyuanjie/pu12 || exit 1
export OUT="${OUT:-logs_experiment}"
export PIDF="${PIDF:-pu12exp.pid}"
export DEVICE="${DEVICE:-cpu}"
export CUDA_VISIBLE_DEVICES="${CUDA_VISIBLE_DEVICES:-}"
mkdir -p "$OUT"
bash run_experiment.sh
if ! ps -eo cmd | grep -q "[w]atchdog_experiment.sh"; then
  (setsid nohup bash watchdog_experiment.sh > "$OUT/watchdog.boot.log" 2>&1 < /dev/null &)
  sleep 1
  echo "watchdog experiment started (out=$OUT pidf=$PIDF)"
else
  echo "watchdog experiment already running"
fi
