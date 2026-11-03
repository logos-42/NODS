#!/usr/bin/env python3
"""方向 B 实验（leo，2026-11-03）——「改变问法」

三种模式，可同时在不同 GPU 并行跑：
  b1 换指标：持久宇宙 + 轮换目标（每段重置 N 防冻结），记录每段 regret / 适应拍数，
             并定期用 **贪婪评估(greedy, 固定起点 band)** 测各目标 -> 计算 ACC/BWT/FWT。
  b2 换表征：同 b1，但把状态从「绝对 band」改为「相对目标距离」(goal-relative)，
             使 Q 表 goal-invariant，检验方向依赖的负迁移是否消失。
  b3 换范式：学一个转移模型 T(band,action->band')，再用模型做「朝目标移动」的策略，
             零样本到达**未见目标**，检验基于模型/规划的迁移。

关键：b1/b2 的评估用 run(learn=False, greedy=True) 从**固定起点**出发，避免上一版
「起点位置」污染；评估用 L 的副本，不污染训练。

用法：
  python3 pu12_v33_b.py --mode b1 --B 4096 --device cuda --out logs_b/b1
  python3 pu12_v33_b.py --mode b2 --B 4096 --device cuda --out logs_b/b2
  python3 pu12_v33_b.py --mode b3 --B 4096 --device cuda --out logs_b/b3
"""

from __future__ import annotations

import argparse
import copy
import json
import os
import sys
import time
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import torch

import pu12_v33 as base
from pu12_v33_mirror import run, Lattice, Learners

N_BANDS, N_STATE, N_ACT, CELLS = base.N_BANDS, base.N_STATE, base.N_ACT, base.CELLS
DT = getattr(base, "DT", 0.01)


# ---------------- greedy 评估（固定起点，不污染训练） ----------------
def greedy_eval(u_ref, L_ref, gen, goal, budget, fixed_start):
    """在 u_ref 的副本上、把 band 全部置为 fixed_start，用 L 的副本贪婪评估到 goal。"""
    ue = copy.deepcopy(u_ref)
    ue.band = torch.full((ue.B,), int(fixed_start), dtype=torch.long, device=ue.device)
    ue.g = (CELLS * torch.rand(ue.B, generator=gen)).to(ue.device).double()
    ue.ever_top[:] = False
    ue.purpose_tick = -1
    ue.top_tick = -1
    Le = copy.deepcopy(L_ref)          # 评估用副本，N/Q 的增量不影响训练
    if MODE == "b2":
        base.CUR_GOAL = int(goal)      # 相对状态需要目标
    _, ticks, purpose = run(ue, Le, gen, budget, "goal", goal_k=goal, learn=False, greedy=True)
    return (purpose is not None), int(ticks)


MODE = "b1"
EVAL_GOALS = [5, 8, 10, 12, 15, 18]


# ---------------- b3：转移模型 + 规划 ----------------
def explore_transitions(u, gen, ticks):
    """用随机动作收集 T(band, action, next_band) 计数。"""
    T = torch.zeros(N_BANDS, N_ACT, N_BANDS, dtype=torch.float64, device=u.device)
    for _ in range(int(ticks)):
        u.advance_phase(DT)
        a = torch.randint(0, N_ACT, (u.B,), device=u.device)
        band0 = u.band.clone()
        full = u.g >= CELLS - 1e-9
        can_move = torch.ones_like(u.band, dtype=torch.bool)
        up = (a == 1) & can_move
        dn = (a == 2) & can_move
        at_top = u.band == N_BANDS - 1
        up_ok = up & full & ~at_top
        down_ok = dn & (u.band > 0)
        exp_sub = (a == 3) & can_move & full
        exp_subs = (a == 4) & can_move & full
        ref_fine = (a == 5) & can_move & full
        u.apply(up_ok, down_ok, exp_sub, exp_subs, ref_fine, gen)
        u.grow()
        idx = band0 * (N_ACT * N_BANDS) + a * N_BANDS + u.band
        T.view(-1).index_add_(0, idx, torch.ones_like(idx, dtype=torch.float64))
    return T


class ModelPolicy:
    """用学到的转移模型 T 选「朝目标移动」的动作（不学习、不探索）。"""
    def __init__(self, T, goal):
        cnt = T.sum(dim=2)                                # (N_BANDS, N_ACT)
        enb = (T * torch.arange(N_BANDS, device=T.device).view(1, 1, -1)).sum(dim=2)
        self.expected = enb / cnt.clamp(min=1e-9)          # E[band' | band, a]
        self.goal = int(goal)

    def act(self, u, s, explore, learn, t, greedy=False):
        band = u.band
        e = self.expected[band]                            # (B, N_ACT)
        up_a = e.argmax(dim=1)                             # 最能把 band 升高的动作
        dn_a = e.argmin(dim=1)                             # 最能把 band 降低的动作
        a = torch.where(band < self.goal, up_a,
                        torch.where(band > self.goal, dn_a, torch.zeros_like(band)))
        return a.long()

    def learn_from(self, *args, **kwargs):
        pass


def model_accuracy(T):
    """T 学到的方向是否与真实 1D 链一致（action1 升、action2 降）。"""
    cnt = T.sum(dim=2).clamp(min=1e-9)
    enb = (T * torch.arange(N_BANDS, device=T.device).view(1, 1, -1)).sum(dim=2) / cnt
    # action 1 应使 band 上升（除最顶带），action 2 应下降（除 0 带）
    up_ok = (enb[:-1, 1] > enb[:-1, 0]).double().mean().item() if N_BANDS > 1 else 0.0
    dn_ok = (enb[1:, 2] < enb[1:, 0]).double().mean().item() if N_BANDS > 1 else 0.0
    return up_ok, dn_ok


# ---------------- 主流程 ----------------
def main() -> int:
    global MODE
    ap = argparse.ArgumentParser()
    ap.add_argument("--mode", choices=["b1", "b2", "b3"], default="b1")
    ap.add_argument("--B", type=int, default=4096)
    ap.add_argument("--device", default="cuda")
    ap.add_argument("--schedule", default="18,15,12,8,5,10")
    ap.add_argument("--seg-ticks", type=int, default=60000)
    ap.add_argument("--eval-every", type=int, default=20, help="每多少段做一次贪婪评估")
    ap.add_argument("--eval-budget", type=int, default=30000)
    ap.add_argument("--fixed-start", type=int, default=9)
    ap.add_argument("--explore-ticks", type=int, default=2000, help="b3 每轮收集转移的拍数")
    ap.add_argument("--seed", type=int, default=0)
    ap.add_argument("--max-seconds", type=float, default=0.0, help=">0 时运行指定墙钟秒数后退出（冒烟/短跑用）")
    ap.add_argument("--out", default="logs_b")
    args = ap.parse_args()
    MODE = args.mode
    dev = args.device
    sched = [int(x) for x in args.schedule.split(",") if x.strip()]

    outdir = Path(args.out); outdir.mkdir(parents=True, exist_ok=True)
    seg_f = open(outdir / "segments.jsonl", "a", buffering=1)
    eval_f = open(outdir / "evals.jsonl", "a", buffering=1)

    print(f"[B-{MODE}] B={args.B} dev={dev} schedule={sched} seg={args.seg_ticks} "
          f"eval_every={args.eval_every} fixed_start={args.fixed_start}", flush=True)

    if MODE == "b2":
        def rel_state(u, achieved):
            rel = torch.clamp(u.band - int(base.CUR_GOAL), -9, 9)
            full = (u.g >= CELLS - 1e-9).long()
            s = (rel + 9) * 4 + full
            if achieved:
                s = s + 2
            return s
        base.CUR_GOAL = 0
        base.Learners.state = staticmethod(rel_state)
        print("[B-b2] 已切换为 goal-relative 状态（Q goal-invariant）", flush=True)

    u = Lattice(args.B, dev, seed=args.seed)
    L = Learners(args.B, dev)
    gen = torch.Generator().manual_seed(args.seed + 1)

    t0 = time.time()
    cum_regret = 0.0
    seg = 0

    if MODE == "b3":
        T = torch.zeros(N_BANDS, N_ACT, N_BANDS, dtype=torch.float64, device=dev)
        rounds = 0
        while True:
            if args.max_seconds and (time.time() - t0) > args.max_seconds:
                break
            T += explore_transitions(u, gen, args.explore_ticks)
            up_ok, dn_ok = model_accuracy(T)
            rounds += 1
            for g in EVAL_GOALS:
                ue = Lattice(args.B, dev, seed=args.seed + 100 + rounds)
                ue.band = torch.full((ue.B,), int(args.fixed_start), dtype=torch.long, device=dev)
                ue.g = (CELLS * torch.rand(ue.B, generator=gen)).to(dev).double()
                mp = ModelPolicy(T, g)
                _, ticks, purpose = run(ue, mp, gen, args.eval_budget, "goal", goal_k=g, learn=False)
                reached = purpose is not None
                row = {"round": rounds, "goal": g, "reached": reached, "ticks": int(ticks),
                       "model_up_ok": round(up_ok, 3), "model_dn_ok": round(dn_ok, 3),
                       "wall_s": round(time.time() - t0, 1)}
                eval_f.write(json.dumps(row, ensure_ascii=False) + "\n")
            print(f"[B-b3] round={rounds} depth={u.t} wall={time.time()-t0:.0f}s "
                  f"up_ok={up_ok:.2f} dn_ok={dn_ok:.2f} T_nonzero={int((T.sum(2)>0).sum())}", flush=True)
            time.sleep(2)
        return 0

    while True:
        if args.max_seconds and (time.time() - t0) > args.max_seconds:
            break
        goal = sched[seg % len(sched)]
        if MODE == "b2":
            base.CUR_GOAL = int(goal)
        _, ticks_used, purpose = run(u, L, gen, args.seg_ticks, "goal", goal_k=goal, learn=True)
        reached = purpose is not None
        bm = float(u.band.double().mean())
        regret = abs(bm - goal)
        cum_regret += regret
        seg_row = {"seg": seg, "goal": goal, "reached": reached, "ticks_used": int(ticks_used),
                   "band_mean": round(bm, 3), "regret": round(regret, 3),
                   "cum_regret": round(cum_regret, 1), "depth": int(u.t),
                   "wall_s": round(time.time() - t0, 1), "B": args.B, "mode": MODE}
        seg_f.write(json.dumps(seg_row, ensure_ascii=False) + "\n")
        # 防冻结：保留 Q，重置访问计数
        L.N.zero_(); L.total.fill_(1.0)
        seg += 1

        if seg % args.eval_every == 0:
            row_res = {}
            for eg in EVAL_GOALS:
                ok, et = greedy_eval(u, L, gen, eg, args.eval_budget, args.fixed_start)
                row_res[eg] = (ok, et)
                eval_f.write(json.dumps({"seg": seg, "goal_eval": eg, "reached": ok,
                                         "ticks": et, "wall_s": round(time.time() - t0, 1),
                                         "mode": MODE}, ensure_ascii=False) + "\n")
            acc = sum(1 for (ok, _) in row_res.values() if ok) / len(row_res)
            print(f"[B-{MODE}] seg={seg} depth={u.t} avg_regret={cum_regret/seg:.2f} "
                  f"eval_acc(greedy,fixed_start)={acc:.2f} detail={row_res}", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
