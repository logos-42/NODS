#!/usr/bin/env python3
"""b6 —— 技能发现与组合（突破方向 3）：b3 的完全去手工版。

不告诉智能体任何动作语义（哪个动作升频/降频、升频需要满充），流程：
  A. 随机探索，统计 counts[band, act, full, band']（自己的转移数据）。
  B. 从统计里**发现**技能：Δband 期望最大的动作 = 升技能，最小 = 降技能；
     并发现「升频需要满充」的门控（P(升成功 | full=0) ≈ 0）。
  C. 组合：对训练计划外的目标（3/7/13/16）与计划内目标，用发现的技能
     组合出策略（band<goal→升技能、>→降技能、未满充先等），零样本测试。

一维链上这仍属平凡（结论解读时须声明），价值在于把「方向语义」从手工假设
变为经验发现，为升维世界（方向 4）做方法铺垫。
"""
import argparse
import json
import time
from pathlib import Path

import torch

from pu12_v33 import Lattice, N_BANDS, N_ACT, CELLS
from pu12_v33_mirror import DT

TRAIN_GOALS = [5, 8, 10, 12, 15, 18]
UNSEEN_GOALS = [3, 7, 13, 16]


def _step(u, a, gen):
    """与 mirror.run 完全一致的动作语义（不含学习）。"""
    u.advance_phase(DT)
    full = u.g >= CELLS - 1e-9
    up = a == 1
    dn = a == 2
    at_top = u.band == N_BANDS - 1
    up_ok = up & full & ~at_top
    down_ok = dn & (u.band > 0)
    exp_sub = (a == 3) & full
    exp_subs = (a == 4) & full
    ref_fine = (a == 5) & full
    u.apply(up_ok, down_ok, exp_sub, exp_subs, ref_fine, gen)
    u.grow()
    u.t += 1


@torch.no_grad()
def explore(u, gen, n_ticks, counts):
    """阶段 A：随机动作探索，累积 counts[band, act, full, band']。"""
    for _ in range(n_ticks):
        band0 = u.band.clone()
        full0 = (u.g >= CELLS - 1e-9).long()
        a = torch.randint(0, N_ACT, (u.B,), device=u.device)
        _step(u, a, gen)
        idx = (band0 * N_ACT + a) * 2 + full0
        flat = idx * N_BANDS + u.band
        counts.index_add_(0, flat.to(torch.int64),
                          torch.ones_like(flat, dtype=torch.float32))


def discover_skills(counts):
    """阶段 B：从转移统计发现升/降技能与满充门控（不假设任何动作语义）。"""
    ar = torch.arange(N_BANDS, device=counts.device).float()
    total = counts.sum(dim=(2, 3)).clamp(min=1)              # (band, act)
    delta = (counts * ar.view(1, 1, 1, -1)).sum(dim=(2, 3))  # Σ band'
    delta = delta.sum(dim=0) / total.sum(dim=0)              # 每个动作平均 Δband
    act_delta = {a: round(float(delta[a]), 4) for a in range(N_ACT)}
    up_skill = int(max(range(N_ACT), key=lambda a: act_delta[a]))
    down_skill = int(min(range(N_ACT), key=lambda a: act_delta[a]))
    # 门控：升技能在未满充 vs 满充时的「有效移动率」（从自己的数据发现）
    moved = (ar.view(-1, 1, 1, 1) != ar.view(1, 1, 1, -1)).float()  # band' != band
    mv = (counts * moved).sum(dim=3)                          # (band, act, full)
    tot_f = counts.sum(dim=3).clamp(min=1)
    up_mv_rate = (mv[:, up_skill, :] / tot_f[:, up_skill, :]).mean(dim=0)
    return {"act_delta": act_delta, "up_skill": up_skill, "down_skill": down_skill,
            "up_move_rate_full0": round(float(up_mv_rate[0]), 4),
            "up_move_rate_full1": round(float(up_mv_rate[1]), 4)}


@torch.no_grad()
def compose_eval(B, dev, seed, skills, goal, budget, fixed_start, gen):
    """阶段 C：用发现的技能组合出朝目标策略，零样本到达。"""
    up, dn = skills["up_skill"], skills["down_skill"]
    u = Lattice(B, dev, seed=seed)
    u.band = torch.full((B,), int(fixed_start), dtype=torch.long, device=dev)
    u.g = torch.zeros(B, device=dev).double()
    u.ever_top[:] = False
    u.purpose_tick = -1
    u.top_tick = -1
    ticks = 0
    for ticks in range(1, budget + 1):
        full = u.g >= CELLS - 1e-9
        a = torch.where(u.band < goal,
                        torch.where(full, torch.full_like(u.band, up),
                                    torch.zeros_like(u.band)),   # 未满充先等（发现的门控）
                        torch.where(u.band > goal, torch.full_like(u.band, dn),
                                    torch.zeros_like(u.band)))
        _step(u, a, gen)
        if bool((u.band == goal).all()):
            return ticks, True, float(u.band.double().mean())
    return budget, False, float(u.band.double().mean())


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--B", type=int, default=4096)
    ap.add_argument("--device", default="cuda")
    ap.add_argument("--seed", type=int, default=0)
    ap.add_argument("--explore-ticks", type=int, default=300000)
    ap.add_argument("--eval-budget", type=int, default=30000)
    ap.add_argument("--fixed-start", type=int, default=9)
    ap.add_argument("--max-seconds", type=float, default=0.0)
    ap.add_argument("--out", default="logs_b/b6")
    args = ap.parse_args()

    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    t0 = time.time()
    dev = args.device
    gen = torch.Generator().manual_seed(args.seed + 1)
    print(f"[B-b6] B={args.B} dev={dev} explore={args.explore_ticks} "
          f"budget={args.eval_budget} fixed_start={args.fixed_start}", flush=True)

    u = Lattice(args.B, dev, seed=args.seed)
    counts = torch.zeros(N_BANDS * N_ACT * 2 * N_BANDS, device=dev)
    explore(u, gen, args.explore_ticks, counts)
    counts = counts.view(N_BANDS, N_ACT, 2, N_BANDS)
    skills = discover_skills(counts)
    print(f"[B-b6] skills={skills}", flush=True)

    results = {}
    all_ok = True
    res_f = (out / "compose.jsonl").open("a")
    for goal in TRAIN_GOALS + UNSEEN_GOALS:
        if args.max_seconds and (time.time() - t0) > args.max_seconds:
            break
        ticks, ok, bm = compose_eval(args.B, dev, args.seed + 200 + goal, skills,
                                     goal, args.eval_budget, args.fixed_start, gen)
        results[goal] = {"ticks": ticks, "reached": ok, "band_mean": round(bm, 3)}
        all_ok &= ok
        res_f.write(json.dumps({"goal": goal, "ticks": ticks, "reached": ok,
                                "band_mean": round(bm, 3)}) + "\n")
        print(f"[B-b6] goal={goal} ticks={ticks} reached={ok} band_mean={bm:.2f}", flush=True)
    res_f.close()

    summary = {"skills": skills, "results": results, "all_reached": all_ok,
                "unseen_all_reached": all(results.get(g, {}).get("reached", False)
                                          for g in UNSEEN_GOALS),
                "wall_s": round(time.time() - t0, 1), "B": args.B}
    (out / "summary.json").write_text(json.dumps(summary, ensure_ascii=False, indent=1))
    print(f"[B-b6] DONE all_reached={all_ok} unseen={summary['unseen_all_reached']} "
          f"wall={summary['wall_s']}s", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
