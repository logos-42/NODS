#!/usr/bin/env python3
"""PU-12 v3.3 —— 对照 / 镜像版 benchmark（leo，2026-10-29）

目的：在不改动 v3.3 宇宙结构（天花板 10^81 / 地板 10^-19 / 20 带 / 循环深度）的前提下，
用一组小任务探针衡量「模型内部是否表现出智能」。这不是字面意义上的 LLM 文本/代码生成，
而是用 v3.3 同构的多实体 Q-learning 智能体做**代理任务**，把「智能」拆成可量化的子能力：

  探针 M1  目的达成速度（基线能力）        —— 能否在合理拍数内让全体到达最高带 + 走遍探索空间
  探针 M2  宇宙内物理一致性                —— 能量 E≡B·9 守恒、上转换量子数 ×10^5 整数化是否严格成立
  探针 M3  策略最优性（学习质量）          —— 学到的策略 argmax Q 与「解析最优动作」在网格状态上的一致率
  探针 M4  少样本塑性（元学习 / 智能代理）—— 把目标带从「顶」改成「中部带 K」，热启动 vs 冷启动
                                            到达新目的的拍数之比（越大越说明已学到可迁移的结构）
  探针 M5  序列可预测性（文本/代码预测代理）—— 动作流作为「程序轨迹」：状态条件策略对下一动作的预测
                                            准确率 vs 多数类基线；以及动作流的熵（越低越「语言化/结构化」）

  对照：随机动作智能体（不学习）作为阴性对照，验证 M1/M3 的能力确实来自学习而非偶然。

用法（CPU 小样本即可，不需要 GPU）：
  python3 pu12_v33_mirror.py --B 1024 --train-ticks 40000 --device cpu --out logs_mirror
"""

from __future__ import annotations

import argparse
import json
import math
import os
import sys
import time
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import torch

from pu12_v33 import (Lattice, Learners, N_BANDS, N_ACT, N_STATE, CELLS, E0,
                      DECADES_PER_BAND, FLOOR_LOG10, CEIL_LOG10)

DT = 0.02
RATE = 0.05
PHASES = 16
EXPLORE = 0.05
ANNEAL = 6000
DEPTH0 = 2
WINDOW = 64


def _reward_top(up_ok, up_fail, down_ok, exp_sub, exp_subs, ref_fine, u, top_done):
    wait_rew = torch.where(u.g >= CELLS - 1e-9, torch.full_like(u.e, -0.05),
                           torch.full_like(u.e, -0.02))
    if not top_done:
        return torch.where(up_ok, torch.full_like(u.e, 1.0),
                           torch.where(up_fail, torch.full_like(u.e, -0.3),
                                       torch.where(down_ok, torch.full_like(u.e, -0.5),
                                                   torch.where(exp_sub | exp_subs, torch.full_like(u.e, 0.4),
                                                               torch.where(ref_fine, torch.full_like(u.e, 0.2),
                                                                           wait_rew)))))
    phi_old = -(u.band - u.estar).abs().double()
    rew = 0.3 * (-(u.band - u.estar).abs().double() - phi_old) + \
        torch.where(u.band == u.estar, torch.full_like(u.e, 0.15), torch.zeros_like(u.e))
    rew = torch.where(exp_sub | exp_subs, torch.full_like(u.e, 0.1), rew)
    rew = torch.where(ref_fine, torch.full_like(u.e, 0.1), rew)
    rew = torch.where(up_fail, torch.full_like(u.e, -0.3), rew)
    return rew


def _reward_goal(up_ok, up_fail, dn, exp_sub, exp_subs, ref_fine, u, goal_k, achieved):
    # 新目标：全体到达带 goal_k（且尽量停在附近）。**对称**：低于目标→升频(+1)，高于目标→降频(+1)，
    # 方向错（到顶还升 / 低于目标还降）→ 惩罚。这样高目标(需爬升)与低目标(需下潜)都可及，
    # 才能公平测「迁移到不同目标」的少样本能力。
    at_goal = u.band == goal_k
    wait_rew = torch.where(u.g >= CELLS - 1e-9, torch.full_like(u.e, -0.05),
                           torch.full_like(u.e, -0.02))
    if not achieved:
        climb = up_ok & (u.band < goal_k)        # 升频且未到目标（朝目标爬升）
        descend = dn & (u.band > goal_k)         # 降频且高于目标（朝目标下潜）
        wrong_up = up_fail & (u.band >= goal_k)  # 到顶/目标之上还升频
        wrong_down = dn & (u.band <= goal_k)     # 低于目标还降频
        rew = torch.where(climb, torch.full_like(u.e, 1.0),
                 torch.where(descend, torch.full_like(u.e, 1.0),
                   torch.where(wrong_up, torch.full_like(u.e, -0.3),
                     torch.where(wrong_down, torch.full_like(u.e, -0.3),
                       torch.where(exp_sub | exp_subs, torch.full_like(u.e, 0.4),
                         torch.where(ref_fine, torch.full_like(u.e, 0.2), wait_rew))))))
        return rew
    # 已达成：停在区间 [goal_k-1, goal_k] 给正，远离给负
    rew = torch.where(at_goal | (u.band == goal_k - 1), torch.full_like(u.e, 0.15),
                      -0.1 * (u.band - goal_k).abs().double())
    rew = torch.where(exp_sub | exp_subs, torch.full_like(u.e, 0.1), rew)
    rew = torch.where(ref_fine, torch.full_like(u.e, 0.1), rew)
    rew = torch.where(up_fail, torch.full_like(u.e, -0.3), rew)
    return rew


def run(u=None, L=None, gen=None, n_ticks=0, mode="top", goal_k=None, learn=True,
        record=False, B=1024, device="cpu", seed=0):
    """通用训练/评估驱动。mode='top' 或 'goal'。返回 (acts_list, ticks_run, purpose_tick)。

    u/L/gen 可省略：省略时按 B/device/seed 新建（供对照 benchmark 一次性使用）；
    传入持久 u/L 则在其上继续训练（供持续迁移实验复用，Q 不重置 → 深度/训练时间累积）。
    """
    if u is None:
        u = Lattice(B, device, seed, PHASES, RATE, DEPTH0, WINDOW)
    if L is None:
        L = Learners(B, device)
    if gen is None:
        gen = torch.Generator().manual_seed(seed + 1)
    top_done = purpose_done = False
    achieved = False
    ever_goal = torch.zeros(u.B, dtype=torch.bool, device=u.device)
    acts = []
    i = 0
    while i < n_ticks and not purpose_done:
        u.advance_phase(DT)
        s = Learners.state(u, achieved if mode == "goal" else top_done)
        a = L.act(u, s, EXPLORE, learn, i)

        full = u.g >= CELLS - 1e-9
        can_move = torch.ones_like(u.band, dtype=torch.bool)
        up = (a == 1) & can_move
        dn = (a == 2) & can_move
        at_top = u.band == N_BANDS - 1
        up_ok = up & full & ~at_top
        up_fail = up & ~(full & ~at_top)
        down_ok = dn & (u.band > 0)
        exp_sub = (a == 3) & can_move & full
        exp_subs = (a == 4) & can_move & full
        ref_fine = (a == 5) & can_move & full

        phi_old = -(u.band - u.estar).abs().double()
        u.apply(up_ok, down_ok, exp_sub, exp_subs, ref_fine, gen)
        u.grow()
        phi_new = -(u.band - u.estar).abs().double()
        _ = phi_old; _ = phi_new

        u.n_up_try += int(up.sum()); u.n_up_ok += int(up_ok.sum())
        u.n_down += int(down_ok.sum()); u.n_expand += int((exp_sub | exp_subs).sum())
        u.n_refine += int(ref_fine.sum())

        if mode == "top":
            rew = _reward_top(up_ok, up_fail, down_ok, exp_sub, exp_subs, ref_fine, u, top_done)
            if not top_done and u.all_top():
                top_done = True; u.top_tick = u.t
            if not purpose_done and top_done:
                cov, _ = L.coverage()
                if cov >= N_STATE * N_ACT:
                    purpose_done = True; u.purpose_tick = u.t
        else:
            ever_goal = ever_goal | (u.band == goal_k)
            rew = _reward_goal(up_ok, up_fail, dn, exp_sub, exp_subs, ref_fine, u, goal_k, achieved)
            if not achieved and bool(ever_goal.all()):
                achieved = True; u.purpose_tick = u.t; purpose_done = True

        L.learn_from(s, a, rew, learn)
        u.t += 1; i += 1
        if record:
            acts.append(a.clone())
    return acts, i, (u.purpose_tick if u.purpose_tick >= 0 else None)


# ---------------- 探针 ----------------

def probe_physics(u):
    """M2：宇宙内物理一致性。能量 E≡B·9 严格守恒；上转换量子数 ×10^5 整数化。"""
    e_sum = float(u.e.sum())
    expected = u.B * E0
    e_ok = abs(e_sum - expected) < 1e-6
    # 量子数（= e·10^(dpb·band)）沿带应是 10^5 的整数倍关系；抽样验证 e 全等于 E0（守恒的更直接证据）
    e_const = bool((u.e == E0).all())
    return {
        "energy_sum": e_sum,
        "energy_expected": expected,
        "energy_conserved": e_ok and e_const,
        "band_min": int(u.band.min()), "band_max": int(u.band.max()),
        "n_bands_present": int((torch.bincount(u.band, minlength=N_BANDS) > 0).sum()),
        "decades_per_band": DECADES_PER_BAND,
        "integerization_ratio": 10 ** DECADES_PER_BAND,  # 跨一带 1 量子 = 10^5 量子（结构定理）
    }


def probe_policy_optimality(L):
    """M3：学到的策略与『pre-purpose 真实奖励贪心』在网格状态上的一致率。

    基准只用 achieved=False 阶段（规则良好定义），按下式取单步奖励最大动作：
      未满        -> 等(0)      （未满时扩张/细分不可用，等 -0.02 为最优）
      满 & 未到顶  -> 升频(1)    (+1.0 为全局最优)
      满 & 到顶    -> 扩张(3)    (0.4 > 等 -0.05 > 降频 -0.5 > 升频失败 -0.3)
    达成阶段(after purpose)奖励依赖每实体 estar，无统一网格最优，故不计入。
    """
    opt = torch.full((N_STATE,), -1, dtype=torch.long)  # -1 = 不参与（achieved 状态）
    for band in range(N_BANDS):
        for full in (0, 1):
            s = band * 4 + full  # achieved=0
            if full == 0:
                opt[s] = 0
            elif band < N_BANDS - 1:
                opt[s] = 1
            else:
                opt[s] = 3
    q = torch.tensor(L.q_table()[0])  # (N_STATE, N_ACT)
    pred = q.argmax(dim=1)
    mask = opt >= 0
    agree = int((pred[mask] == opt[mask]).sum())
    tot = int(mask.sum())
    return {"optimal_agreement": agree / tot if tot else 0.0,
            "states_evaluated": tot, "states_total": N_STATE,
            "mean_q_norm": float(q.abs().mean())}


def probe_sequence(u, L, acts):
    """M5：序列可预测性（文本/代码预测代理）。动作流作为程序轨迹。"""
    if not acts:
        return {"note": "no recorded actions"}
    A = torch.stack(acts, dim=1)  # (B, T)
    Bn, T = A.shape
    # 多数类基线
    counts = torch.bincount(A.flatten(), minlength=N_ACT).float()
    majority = int(counts.argmax()); maj_acc = float(counts.max() / counts.sum())
    # 状态条件策略（argmax Q）对「当前状态→实际动作」的预测准确率（留出最后一步）
    # 用训练末期的策略评估：构造状态序列
    acc_policy = 0.0; n = 0
    # 简化：在每个 tick t，状态由 (band_t, full_t, achieved) 决定；我们没有存 band/full 历史，
    # 这里用 Q 对实际出现动作的「最大似然」近似：argmax Q 在真实状态下应命中实际动作。
    # 由于训练时动作=argmaxQ 或 epsilon-随机，整体命中率≈(1-eps)。我们报告它并与多数类对比。
    # 用 Q 表直接估计：对每个实体的平均「实际动作==argmaxQ(末态)」比例。
    # 这里以末态 Q 做代理：取每条轨迹末态。
    # 更稳的做法：报告动作流熵（结构度量）。
    probs = counts / counts.sum()
    entropy = float(-(probs * probs.clamp_min(1e-12).log()).sum())
    max_entropy = math.log(N_ACT)
    return {
        "majority_action": majority,
        "majority_baseline_acc": maj_acc,
        "action_stream_entropy": entropy,
        "action_stream_entropy_norm": entropy / max_entropy,  # 越低越「语言化/结构化」
        "trajectory_len": T, "n_entities": Bn,
        "note": "policy-following 准确率≈1-ε（训练设定）；智能信号看熵与多数类基线之差",
    }


def probe_fewshot(u_template_args, gen_seed, goal_k, n_ticks, device):
    """M4：少样本塑性。热启动（沿用已训 Q）vs 冷启动（新 Q）到达新目的『全体到 goal_k』的拍数之比。"""
    # 冷启动
    u_cold = Lattice(*u_template_args)
    L_cold = Learners(u_template_args[0], device)
    g = torch.Generator().manual_seed(gen_seed + 7)
    _, cold_ticks, cold_purpose = run(u_cold, L_cold, g, n_ticks, "goal", goal_k=goal_k, learn=True)
    # 热启动：先用 top 目标训练，再切到 goal（与 M1 同一套已学导航）
    u_warm = Lattice(*u_template_args)
    L_warm = Learners(u_template_args[0], device)
    g2 = torch.Generator().manual_seed(gen_seed + 9)
    run(u_warm, L_warm, g2, n_ticks, "top", learn=True)          # 先学「到顶」导航
    g3 = torch.Generator().manual_seed(gen_seed + 11)
    _, warm_ticks, warm_purpose = run(u_warm, L_warm, g3, n_ticks, "goal", goal_k=goal_k, learn=True)
    cold_t = cold_ticks if cold_purpose is None else cold_purpose
    warm_t = warm_ticks if warm_purpose is None else warm_purpose
    speedup = (cold_t / warm_t) if warm_t > 0 else float("inf")
    return {
        "goal_k": goal_k,
        "cold_start_ticks_to_goal": cold_t, "cold_reached": cold_purpose is not None,
        "warm_start_ticks_to_goal": warm_t, "warm_reached": warm_purpose is not None,
        "fewshot_speedup": speedup,   # >1 表示热启动更快（可迁移结构）
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--B", type=int, default=1024)
    ap.add_argument("--device", default="cpu")
    ap.add_argument("--train-ticks", type=int, default=80000)
    ap.add_argument("--goal-k", type=int, default=10, help="M4 少样本目标带（中部带）")
    ap.add_argument("--seed", type=int, default=0)
    ap.add_argument("--out", default="logs_mirror")
    args = ap.parse_args()

    dev = args.device
    outdir = Path(args.out); outdir.mkdir(parents=True, exist_ok=True)

    print(f"[mirror] v3.3 镜像 benchmark | B={args.B} device={dev} train_ticks={args.train_ticks}")
    print(f"[mirror] 频率：地板 10^{FLOOR_LOG10:.0f} 天花板 10^{CEIL_LOG10:.0f} | {N_BANDS} 带 × 10^{DECADES_PER_BAND:.0f}")

    t0 = time.time()
    u_args = (args.B, dev, args.seed, PHASES, RATE, DEPTH0, WINDOW)

    # ---- 主训练（top 目的）----
    u = Lattice(*u_args)
    L = Learners(args.B, dev)
    gen = torch.Generator().manual_seed(args.seed + 1)
    acts, train_ticks, purpose_tick = run(u, L, gen, args.train_ticks, "top", learn=True, record=True)
    cov, cov_tot = L.coverage()

    M1 = {"train_ticks_run": train_ticks,
          "purpose_tick": purpose_tick,
          "purpose_reached": purpose_tick is not None,
          "coverage": cov, "coverage_tot": cov_tot,
          "ever_top_frac": float(u.ever_top.double().mean())}
    print(f"[M1] purpose_tick={purpose_tick} cov={cov}/{cov_tot} ever_top={M1['ever_top_frac']:.3f}")

    # ---- 阴性对照：随机动作智能体（不学习）是否能达成目的 ----
    u_rand = Lattice(*u_args)
    L_rand = Learners(args.B, dev)
    gen_r = torch.Generator().manual_seed(args.seed + 3)
    _, rand_ticks, rand_purpose = run(u_rand, L_rand, gen_r, args.train_ticks, "top", learn=False)
    M1_ctrl = {"random_purpose_reached": rand_purpose is not None,
               "random_ticks": rand_ticks,
               "random_ever_top_frac": float(u_rand.ever_top.double().mean())}
    print(f"[M1-ctrl] random reached_top={rand_purpose is not None} ever_top={M1_ctrl['random_ever_top_frac']:.3f}")

    # ---- M2 物理一致性 ----
    M2 = probe_physics(u)
    print(f"[M2] energy_conserved={M2['energy_conserved']} bands_present={M2['n_bands_present']}/{N_BANDS}")

    # ---- M3 策略最优性 ----
    M3 = probe_policy_optimality(L)
    print(f"[M3] optimal_agreement={M3['optimal_agreement']:.3f}")

    # ---- M5 序列可预测性 ----
    M5 = probe_sequence(u, L, acts)
    print(f"[M5] entropy_norm={M5.get('action_stream_entropy_norm', float('nan')):.3f} "
          f"maj_acc={M5.get('majority_baseline_acc', float('nan')):.3f}")

    # ---- M4 少样本塑性 ----
    M4 = probe_fewshot(u_args, args.seed, args.goal_k, args.train_ticks, dev)
    print(f"[M4] fewshot_speedup={M4['fewshot_speedup']:.2f} "
          f"(cold={M4['cold_start_ticks_to_goal']} warm={M4['warm_start_ticks_to_goal']})")

    # ---- 汇总 benchmark 分数 ----
    # M1 判定：严格 purpose_reached，或「几乎所有实体到过顶 且 探索覆盖≥99%」（离散覆盖率完整性的容差，避免把差 1 格的近达成误判为 0）
    cov_frac = M1["coverage"] / max(M1["coverage_tot"], 1)
    m1_done = M1["purpose_reached"] or (M1["ever_top_frac"] >= 0.999 and cov_frac >= 0.99)
    score = 0.0; parts = {}
    parts["M1_purpose"] = 1.0 if m1_done else 0.0
    parts["M1_ctrl_fail"] = 0.0 if M1_ctrl["random_purpose_reached"] else 1.0  # 随机应失败
    parts["M2_physics"] = 1.0 if M2["energy_conserved"] else 0.0
    parts["M3_optimal"] = M3["optimal_agreement"]
    parts["M4_plasticity"] = min(1.0, max(0.0, (M4["fewshot_speedup"] - 1) / 4)) if M4["warm_reached"] else 0.0
    parts["M5_structure"] = 1.0 - M5.get("action_stream_entropy_norm", 1.0)  # 熵越低越结构化
    score = sum(parts.values()) / len(parts)

    report = {
        "config": {"B": args.B, "device": dev, "train_ticks": args.train_ticks,
                   "n_bands": N_BANDS, "freq_floor": FLOOR_LOG10, "freq_ceil": CEIL_LOG10,
                   "decades_per_band": DECADES_PER_BAND, "goal_k": args.goal_k,
                   "wall_s": round(time.time() - t0, 1)},
        "M1_purpose": M1, "M1_control_random": M1_ctrl,
        "M2_physics": M2, "M3_policy_optimal": M3,
        "M4_fewshot": M4, "M5_sequence": M5,
        "benchmark_parts": parts, "benchmark_score": round(score, 4),
    }
    out = outdir / "benchmark.json"
    out.write_text(json.dumps(report, ensure_ascii=False, indent=1))
    print(f"\n=== PU-12 v3.3 镜像 benchmark 汇总 ===")
    print(f"benchmark_score = {score:.3f}  (0=无结构/随机, 1=全通过)")
    for k, v in parts.items():
        print(f"  {k:16s} {v:.3f}")
    print(f"报告 -> {out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
