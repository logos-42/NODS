#!/usr/bin/env python3
"""PU-12 v3.3 —— 持续迁移实验 / 无限递归循环（leo，2026-10-29）

假设（leo）：上一轮镜像 benchmark 的少样本负迁移（fewshot_speedup=0.50）< 可能是因为
**深度/训练时间不足**，而不是模型本质无能力。本实验用一台**持久宇宙**连续训练来验证：

  - 持久宇宙 u / Q 表 L **永不重置**，Q 跨所有目标累积 → 递归深度与训练时间持续累加；
  - 运行时不断轮换「迁移性目标」（兼容目标在前：高带需爬升；挑战目标在后：低带需下潜），
    让实体持续面对不同的迁移任务；
  - **每 2 小时**（墙钟）对一个新的、不同的目标做一次少样本迁移探针：
      热启动 = 在持久 Q 上继续训练到该目标；冷启动 = 全新 Q 训练到同一目标；
      记录 fewshot_speedup = 冷启动拍数 / 热启动拍数；speedup>1 表示已学到可迁移结构；
  - 无限循环、不设立停止时间；把 speedup / M3 策略最优性 / 物理一致性 随时间序列写入
    logs_experiment/experiment.jsonl，看更长 benchmark 下能力是否提升。

用法（CPU 小样本即可，与 GPU 上的 v3.3 主程序互不干扰）：
  python3 pu12_v33_experiment.py --schedule 18,15,12,8,5,10 --probe-every-seconds 7200
监控：
  tail -f logs_experiment/experiment.jsonl
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import torch

from pu12_v33_mirror import (run, Lattice, Learners, probe_physics,
                             probe_policy_optimality, N_BANDS, FLOOR_LOG10, CEIL_LOG10)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--B", type=int, default=1024)
    ap.add_argument("--device", default="cpu")
    ap.add_argument("--schedule", default="18,15,12,8,5,10",
                    help="迁移性目标带序列（逗号分隔）。兼容目标(高带,需爬升)放前，挑战目标(低带,需下潜)放后")
    ap.add_argument("--seg-ticks", type=int, default=30000,
                    help="每个迁移目标训练多少拍再切下一个目标")
    ap.add_argument("--probe-every-seconds", type=int, default=7200,
                    help="每隔多少墙钟秒做一次少样本迁移探针（默认 2 小时）")
    ap.add_argument("--probe-train-ticks", type=int, default=60000,
                    help="探针里冷/热启动各自最多训练多少拍去够到目标")
    ap.add_argument("--seed", type=int, default=0)
    ap.add_argument("--out", default="logs_experiment")
    ap.add_argument("--reset-n", action="store_true",
                    help="每段结束重置访问计数 N（保留 Q/知识）；Q-learning 步长与 UCB 探索随访问次数衰减会「冻结」，"
                         "重置 N 恢复探索与学习率，使持久宇宙能持续跟踪不同目标带（非平稳 RL 标准做法）")
    ap.add_argument("--heartbeat-segments", type=int, default=20,
                    help="每多少个迁移段打印一次心跳")
    args = ap.parse_args()

    dev = args.device
    sched = [int(x) for x in args.schedule.split(",") if x.strip() != ""]
    if not sched:
        sched = [N_BANDS - 2]
    outdir = Path(args.out); outdir.mkdir(parents=True, exist_ok=True)
    jsonl = outdir / "experiment.jsonl"
    status = outdir / "status.json"

    print(f"[experiment] 持久宇宙 B={args.B} device={dev} | 迁移目标序列 {sched}")
    print(f"[experiment] 每 {args.seg_ticks} 拍切目标；每 {args.probe_every_seconds}s 做迁移探针；无限循环不停止")
    print(f"[experiment] 频率：地板 10^{FLOOR_LOG10:.0f} 天花板 10^{CEIL_LOG10:.0f} | {N_BANDS} 带")

    # 持久宇宙（Q 不重置）
    u = Lattice(args.B, dev, seed=args.seed)
    L = Learners(args.B, dev)
    gen = torch.Generator().manual_seed(args.seed + 1)

    t0 = time.time()
    last_probe = 0.0
    seg_idx = 0
    first_speedup = None
    rows_written = 0
    f = open(jsonl, "a", buffering=1)
    print(f"[experiment] log -> {jsonl}", flush=True)

    try:
        while True:  # 不设立停止时间
            goal = sched[seg_idx % len(sched)]
            # 在持久宇宙上训练当前迁移目标
            run(u, L, gen, args.seg_ticks, "goal", goal_k=goal, learn=True, record=False)
            seg_idx += 1

            if seg_idx % args.heartbeat_segments == 0:
                cov, cov_tot = L.coverage()
                print(f"[hb] seg={seg_idx:5d} depth(ticks)={u.t:8d} goal={goal} "
                      f"band_mean={float(u.band.double().mean()):5.2f} ever_top={float(u.ever_top.double().mean()):.2f} "
                      f"cov={cov}/{cov_tot} wall={time.time()-t0:.0f}s", flush=True)

            elapsed = time.time() - t0
            if elapsed - last_probe >= args.probe_every_seconds:
                last_probe = elapsed
                # 选一个「不同的」探针目标：序列里下一个，与刚训的 goal 不同
                probe_goal = sched[seg_idx % len(sched)]

                # 热启动：在持久 Q 上继续训练到 probe_goal
                warm_before = u.t
                _, warm_ticks, warm_purpose = run(u, L, gen, args.probe_train_ticks,
                                                 "goal", goal_k=probe_goal, learn=True)
                warm_reached = warm_purpose is not None
                warm_ticks = warm_ticks if warm_reached else args.probe_train_ticks

                # 冷启动：全新宇宙 / 全新 Q
                u_cold = Lattice(args.B, dev, seed=args.seed + 100 + seg_idx)
                L_cold = Learners(args.B, dev)
                g_cold = torch.Generator().manual_seed(args.seed + 200 + seg_idx)
                _, cold_ticks, cold_purpose = run(u_cold, L_cold, g_cold, args.probe_train_ticks,
                                                 "goal", goal_k=probe_goal, learn=True)
                cold_reached = cold_purpose is not None
                cold_ticks = cold_ticks if cold_reached else args.probe_train_ticks

                speedup = (cold_ticks / warm_ticks) if (warm_reached and cold_reached and warm_ticks > 0) else None
                m3 = probe_policy_optimality(L)["optimal_agreement"]
                phys = probe_physics(u)["energy_conserved"]
                plasticity = max(0.0, min(1.0, (speedup - 1) / 4.0)) if speedup is not None else 0.0
                score = 0.5 * m3 + 0.5 * plasticity if speedup is not None else 0.5 * m3

                if first_speedup is None:
                    first_speedup = speedup

                row = {
                    "wall_s": round(elapsed, 1), "seg_idx": seg_idx, "depth_ticks": int(u.t),
                    "train_goal": goal, "probe_goal": probe_goal,
                    "warm_ticks": warm_ticks, "warm_reached": warm_reached,
                    "cold_ticks": cold_ticks, "cold_reached": cold_reached,
                    "fewshot_speedup": (round(speedup, 3) if speedup is not None else None),
                    "first_speedup": (round(first_speedup, 3) if first_speedup is not None else None),
                    "m3_optimal_agreement": round(m3, 3),
                    "energy_conserved": phys,
                    "capability_score": round(score, 3),
                    "schedule": sched, "B": args.B,
                }
                f.write(json.dumps(row, ensure_ascii=False) + "\n")
                rows_written += 1
                status.write_text(json.dumps(row, ensure_ascii=False, indent=1))
                trend = ""
                if speedup is not None and first_speedup is not None:
                    trend = " ↑提升" if speedup > first_speedup else (" ↓下降" if speedup < first_speedup else " →持平")
                print(f"[PROBE] wall={elapsed/3600:.1f}h depth={u.t} probe_goal={probe_goal} "
                      f"warm={warm_ticks}({'Y' if warm_reached else 'N'}) cold={cold_ticks}({'Y' if cold_reached else 'N'}) "
                      f"speedup={('%.3f'%speedup) if speedup is not None else 'N/A'}{trend} "
                      f"m3={m3:.2f} phys={phys} score={score:.2f}", flush=True)

            # 防冻结：保留 Q（知识持续累积），但每段重置访问计数 -> 恢复探索与学习率，
            # 让持久宇宙能在轮换目标后仍爬到高带（否则 1/(n+1) 步长衰减到 0 会把 Q 冻在某个低带）。
            if args.reset_n:
                L.N.zero_(); L.total.fill_(1.0)
    except KeyboardInterrupt:
        print("\n[experiment] 收到中断，写入已完成行并退出（下次可从同状态续跑需另存 checkpoint，本实验默认不存）", flush=True)
    finally:
        f.close()
        print(f"[experiment] 结束：共 {rows_written} 次探针，最后 depth={u.t} ticks，日志 {jsonl}", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
