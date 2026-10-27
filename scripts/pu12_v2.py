#!/usr/bin/env python3
"""PU-12 v2 —— 实体宇宙：频率 × 维度 × 能量 的自主学习进化

与 v1 (`pu12_gpu.py`) 的差别（2026-10-27 第二版需求）：

  ① 实体分布在**所有**带（频率）与维度上 —— 不是"一个宇宙一条生命史"，而是系综里到处都有实体；
  ② 每个实体按自己的（维 d、频 k、能量 e）自行发育：在当前带点亮 9 个隐数格，才有资格升频；
  ③ 升频 = 频率升高 ⟹ 维度升高（d = 到过的最高维）；量子数 ×10^5（`band_ratio`），束数（能量）守恒；
  ④ **走的过程靠实体学习**：{等待, 升频, 降频体验} 由每个实体自己的经验计数决定
     （Thompson 采样，Beta 后验；成功 = 该动作带来正奖励）。`--no-learn` = 均匀随机动作，作对照；
  ⑤ 高维实体可**屏蔽自己的能力**回到低带体验：k -= 1，低带结构现成（g 立即满格），d 保留
     ⟹ "带着记忆降频"，随时能再升回去；
  ⑥ **宇宙目的**：所有实体都曾到达最高带（d = 12）⟹ 记 `purpose_tick`。达成后进入体验期
     （降频奖励转正），于是出现持续的上升—下降往返流（回流率可观测）。

能量语义沿用 v1（与 Lean `band_ratio` / `energy_exch` 一致）：
  能量单位是「束」，1 束在任意带都是 ε₀ ⟹ 束数守恒即能量守恒；
  量子数 N = e·10^(5k)，纯度 Π = e/N（带越高 Π 越小）。

为什么用 Thompson 采样而不是策略梯度：一次 REINFORCE 试验（共享 MLP + logp·advantage）
在 t=1000 就塌缩到熵 0，且"满格"探针仍输出"等待" —— 那是假的"学习"。
换成**每个实体自己的 Beta 经验计数**后：无梯度、无超参爆炸，学到的偏好可以逐格打印核验
（`logs_v2/status.json` 里的 `q_table`），并且每个实体学的快慢不同，符合"实体自己发育"。

诚实边界：
  * 12 带 / 10^41 天花板 / 9 格结构 / 发育速率 `--rate` 是**给定参数**；
  * 奖励结构（升频 +1、失败 −0.3、满格还等 −0.05、未达成时降频 −0.5、达成后降频 +0.5）是我设定的
    **训练信号**，它编码了"目的 = 全体升到最高带"这条需求，本身不是物理；
  * 唯一被物理卡死的是：升频必须结构满格、束数守恒、量子数按 10^5 跳。
"""

from __future__ import annotations

import argparse
import json
import math
import time
from pathlib import Path

import torch

N_BANDS = 12
CELLS = 9.0          # 每带隐数格数（3 子维度 × 3 亚维度）
E0 = 9.0             # 初始授予 = 9 束 = 每格一束
N_ACT = 3            # 0 等待发育 / 1 升频进化 / 2 降频体验
N_BUCKET = 3         # 带位置分桶：低(0-3) / 中(4-7) / 高(8-11)
N_STATE = N_BUCKET * 4   # 桶 × (未满格|满格) × (目的未达成|已达成)


def band_freq(device) -> torch.Tensor:
    """归一化角速度基准：带 0 = 1，带 11 = 10^-55（频率越高转得越快）。"""
    k = torch.arange(N_BANDS, dtype=torch.float64, device=device)
    return torch.pow(torch.tensor(10.0, dtype=torch.float64, device=device), -5.0 * k).float()


class Universe:
    """一群实体，每个有 (带 k, 维 d, 结构 g, 能量 e, 相位 θ)。"""

    def __init__(self, B: int, device: str, seed: int = 0, phases: int = 16,
                 rate: float = 0.02, k0_lo: int = 0, k0_hi: int = N_BANDS - 1):
        gen = torch.Generator().manual_seed(seed)
        self.B, self.device, self.P = B, device, phases
        self.rate = rate

        # ① 初始：各带都有实体（"不同维度和频率里面都有实体"），结构发育程度也各不相同
        self.k = torch.randint(k0_lo, k0_hi + 1, (B,), generator=gen).to(device).long()
        self.d = (self.k + 1).clone()                                     # 维度 = 到过的最高带 + 1
        self.g = (CELLS * torch.rand(B, generator=gen)).to(device).double()   # 当前带点亮格数
        self.e = torch.full((B,), E0, dtype=torch.float64, device=device)  # 束数（守恒）

        # 相位振子（振动坐标系）：频率由所在带决定
        self.theta = (2 * math.pi * torch.rand(B, phases, generator=gen)).to(device).float()
        self.spread = (0.95 + 0.1 * torch.rand(B, phases, generator=gen)).to(device).float()
        self.freq = band_freq(device)
        self.coh = torch.zeros(B, device=device)

        # ⑤ "自己想去的低维频率"：每个实体有一个体验目标带（达成目的后朝它下潜）
        self.estar = torch.randint(0, N_BANDS - 1, (B,), generator=gen).to(device).long()

        self.t = 0
        self.top_tick = -1              # 首次「所有实体都曾到达最高带」的时刻
        self.purpose_tick = -1          # 首次「到顶 + 探索空间走遍」的时刻
        self.n_up_try = 0
        self.n_up_ok = 0
        self.n_down = 0

    # ---------- 读数 ----------
    def quanta(self):
        w = torch.pow(torch.tensor(10.0, dtype=torch.float64, device=self.device), 5.0 * self.k.double())
        return self.e * w

    def purity(self):
        return self.e / torch.clamp(self.quanta(), min=1e-300)

    def all_top(self) -> bool:
        """目的达成：**所有实体都曾到达最高带**（d = 12）。

        用"曾到达"而不是"此刻都在顶部"，是因为体验期允许高维实体临时降频——
        瞬时全在顶部会被体验动作打断，那样判据就成了噪声。
        """
        return bool((self.d >= N_BANDS).all())

    # ---------- 环境一步 ----------
    def advance_phase(self, dt: float):
        om = self.freq[self.k].unsqueeze(1) * self.spread
        self.theta = torch.remainder(self.theta + (2 * math.pi * dt) * om, 2 * math.pi)
        self.coh = torch.polar(torch.ones_like(self.theta), self.theta).mean(dim=1).abs()

    def grow(self):
        """结构发育：每拍点亮 `rate` 个隐数格（rate=0.02 ⟹ 450 拍点亮一带的 9 格）。"""
        self.g = torch.clamp(self.g + self.rate, max=CELLS)

    def apply(self, up_ok: torch.Tensor, down: torch.Tensor):
        # 升频：进入下一带，结构从零重建（成本），能量（束数）不动 ⟹ 量子数 ×10^5
        self.k = torch.where(up_ok, self.k + 1, self.k)
        self.g = torch.where(up_ok, torch.zeros_like(self.g), self.g)
        # 降频体验（屏蔽能力）：退回低带，低带结构现成，维度记忆 d 保留
        self.k = torch.where(down, self.k - 1, self.k)
        self.g = torch.where(down, torch.full_like(self.g, CELLS), self.g)
        self.d = torch.maximum(self.d, self.k + 1)

    # ---------- 快照 ----------
    def snapshot(self):
        return {
            "t": self.t,
            "k_mean": float(self.k.double().mean()),
            "k_min": int(self.k.min()),
            "k_hist": torch.bincount(self.k, minlength=N_BANDS).tolist(),
            "d_mean": float(self.d.double().mean()),
            "d_max": int(self.d.max()),
            "top_frac": float((self.k == N_BANDS - 1).double().mean()),
            "reached_top": float((self.d >= N_BANDS).double().mean()),
            "e_sum": float(self.e.sum()),
            "e_min": float(self.e.min()),
            "e_max": float(self.e.max()),
            "purity": float(self.purity().mean()),
            "quanta": float(self.quanta().mean()),
            "coh": float(self.coh.mean()),
            "purpose_tick": self.purpose_tick,
            "top_tick": self.top_tick,
            "up_try": self.n_up_try,
            "up_ok": self.n_up_ok,
            "down": self.n_down,
        }


class Learners:
    """每个实体自己的经验表：state(4) × action(3) 的**均值奖赏 + UCB 探索**。

    为什么不是 Beta/Thompson：奖励是**分级**的（等待 −0.02、失败 −0.3、未达成降频 −0.5、
    升频成功 +1.0）。二元"成功/失败"会把 −0.02 和 −0.5 压成同一个信号 —— 实测导致
    空状态下三个动作全记成失败、实体乱降到带 0。均值估计保留幅度，学到的偏好才正确。

    Q 表可以整体打印（`q_table`），逐格核验"满格该升、空状态该等、达成后该降频体验"。
    """

    def __init__(self, B: int, device: str, c: float = 0.5):
        self.Q = torch.zeros(B, N_STATE, N_ACT, device=device)
        self.N = torch.zeros(B, N_STATE, N_ACT, device=device)
        self.c = c
        self.total = torch.zeros(B, device=device)

    @staticmethod
    def state(u: Universe, achieved: bool) -> torch.Tensor:
        """状态 = 带位置桶 × 结构是否满格 × 目的是否已达成。

        必须带位置桶：没有它，实体分不清"从高处降下来体验"和"在低处继续往下掉"，
        实测会集体坠到带 0 躺平。
        """
        b = torch.where(u.k <= 3, torch.zeros_like(u.k),
                        torch.where(u.k <= 7, torch.ones_like(u.k), torch.full_like(u.k, 2)))
        full = (u.g >= CELLS - 1e-9).long()
        s = b * 4 + full
        if achieved:
            s = s + 2
        return s

    def act(self, u: Universe, s: torch.Tensor, explore: float, learn: bool) -> torch.Tensor:
        if not learn:
            return torch.randint(0, N_ACT, (u.B,), device=u.device)
        idx = torch.arange(u.B, device=u.device)
        q = self.Q[idx, s]                      # (B,3)
        n = self.N[idx, s]
        bonus = self.c * torch.sqrt(torch.log(self.total[idx] + 2.0).unsqueeze(1) / (n + 1.0))
        # 没试过的动作给固定乐观分（鼓励各动作都被试一次），而不是永远选下标 0
        score = torch.where(n < 0.5, torch.full_like(q, 0.75), q + bonus)
        score = score + torch.rand_like(score) * 1e-4       # 破平局
        act = score.argmax(dim=1)
        if explore > 0:
            eps = torch.rand(u.B, device=u.device) < explore
            act = torch.where(eps, torch.randint(0, N_ACT, (u.B,), device=u.device), act)
        return act

    def learn_from(self, s: torch.Tensor, a: torch.Tensor, r: torch.Tensor, learn: bool):
        """记录一次经验。访问计数在两种模式下都记（探索覆盖是客观事实），
        只有 learn=True 时才更新 Q 值（`--no-learn` 只探索、不学）。"""
        idx = torch.arange(a.shape[0], device=a.device)
        n = self.N[idx, s, a]
        if learn:
            self.Q[idx, s, a] += (r.double() - self.Q[idx, s, a]) / (n + 1.0)
        self.N[idx, s, a] += 1.0
        self.total += 1.0

    def q_table(self):
        """汇总后的经验：每个状态各动作的平均奖赏（可正可负）。"""
        w = self.N.sum(dim=0)
        q = (self.Q * self.N).sum(dim=0) / w.clamp(min=1e-9)
        return q.tolist(), float(w.sum())

    def coverage(self) -> tuple[int, int]:
        """探索覆盖：有多少个 (状态, 动作) 格子被试过。

        "探索的可能性都走过"就以此为准 —— 学习器把世界抽象成 N_STATE×N_ACT 张表，
        每一格至少被试过一次，才算把可能性走遍。返回 (已走格数, 总格数)。
        """
        visited = (self.N.sum(dim=0) > 0)          # (N_STATE, N_ACT)
        return int(visited.sum()), int(N_STATE * N_ACT)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--device", default="cuda")
    ap.add_argument("--B", type=int, default=16384, help="实体数")
    ap.add_argument("--ticks", type=int, default=0, help="0 = 一直跑")
    ap.add_argument("--dt", type=float, default=0.02)
    ap.add_argument("--rate", type=float, default=0.02, help="每拍点亮多少隐数格（发育速率）")
    ap.add_argument("--phases", type=int, default=16)
    ap.add_argument("--log-every", type=int, default=200)
    ap.add_argument("--explore", type=float, default=0.02, help="ε 探索下限")
    ap.add_argument("--ucb", type=float, default=0.25, help="UCB 探索系数（越大越爱试新动作）")
    ap.add_argument("--seed", type=int, default=0)
    ap.add_argument("--out", default="logs_v2")
    ap.add_argument("--no-learn", action="store_true", help="对照：均匀随机动作，不学习")
    args = ap.parse_args()

    dev = args.device
    if dev == "cuda" and not torch.cuda.is_available():
        print("[warn] cuda 不可用，退回 cpu", flush=True)
        dev = "cpu"
    if dev == "cuda":
        print(f"[info] gpu = {torch.cuda.get_device_name(0)} | B={args.B} P={args.phases}", flush=True)

    u = Universe(args.B, dev, seed=args.seed, phases=args.phases, rate=args.rate)
    L = Learners(args.B, dev, c=args.ucb)
    learn = not args.no_learn
    top_done = False        # 所有实体都曾到达最高带
    purpose_done = False    # 再加：探索空间（state×action）每一格都走过
    top_tick = -1

    outdir = Path(args.out)
    outdir.mkdir(parents=True, exist_ok=True)
    path = outdir / f"run-{time.strftime('%Y%m%d-%H%M%S')}.jsonl"
    status = outdir / "status.json"
    f = open(path, "a", buffering=1)
    print(f"[info] log -> {path} | learn={learn}", flush=True)

    t0 = time.time()
    n_wait = n_up = n_dn = 0
    i = 0
    while args.ticks == 0 or i < args.ticks:
        u.advance_phase(args.dt)

        s = Learners.state(u, top_done)
        a = L.act(u, s, args.explore, learn)

        # ---- 环境判定（物理约束在这里，不在学习器里）----
        up = a == 1
        dn = a == 2
        full = u.g >= CELLS - 1e-9
        at_top = u.k == N_BANDS - 1
        up_ok = up & full & ~at_top
        up_fail = up & ~(full & ~at_top)
        dn_ok = dn & (u.k > 0)
        dn_fail = dn & (u.k == 0)

        phi_old = -(u.k - u.estar).abs().double()      # 到"想去的带"的距离（负数）
        u.apply(up_ok, dn_ok)
        u.grow()
        phi_new = -(u.k - u.estar).abs().double()

        # ---- 奖励 ----
        wait_rew = torch.where(full, torch.full_like(u.e, -0.05), torch.full_like(u.e, -0.02))
        if not top_done:
            # 目的未达成：升频（真的升上去了）是唯一正回报；降频 = 拖延
            rew = torch.where(up_ok, torch.full_like(u.e, 1.0),
                              torch.where(up_fail, torch.full_like(u.e, -0.3),
                                          torch.where(dn_ok, torch.full_like(u.e, -0.5),
                                                      torch.where(dn_fail, torch.full_like(u.e, -0.1),
                                                                  wait_rew))))
        else:
            # 体验期：朝"自己想去的带"靠近有回报，到了目的地再加一笔；走错方向与非法动作扣分
            rew = 0.3 * (phi_new - phi_old) + torch.where(u.k == u.estar,
                                                          torch.full_like(u.e, 0.15),
                                                          torch.zeros_like(u.e))
            rew = torch.where(up_fail, torch.full_like(u.e, -0.3), rew)
            rew = torch.where(dn_fail, torch.full_like(u.e, -0.1), rew)
            rew = torch.where((a == 0) & (u.k != u.estar), torch.full_like(u.e, -0.02), rew)

        u.n_up_try += int(up.sum())
        u.n_up_ok += int(up_ok.sum())
        u.n_down += int(dn_ok.sum())
        n_wait += int((a == 0).sum())
        n_up += int(up.sum())
        n_dn += int(dn.sum())

        L.learn_from(s, a, rew, learn)

        # ---- 目的判据：① 所有实体都曾到达最高带 ② 探索空间每一格都走过 ----
        if not top_done and u.all_top():
            top_done = True
            top_tick = u.t
            u.top_tick = top_tick
            print(f"[top] 所有实体都已到达最高带 @ tick {u.t}", flush=True)
        if not purpose_done and top_done:
            cov, cov_tot = L.coverage()
            if cov >= cov_tot:
                purpose_done = True
                u.purpose_tick = u.t
                print(f"[purpose] 目的达成：全体到顶 + 探索 {cov}/{cov_tot} 格走遍 @ tick {u.t}",
                      flush=True)

        u.t += 1

        if i % args.log_every == 0:
            snap = u.snapshot()
            q, n_samples = L.q_table()
            cov_now, cov_tot_now = L.coverage()
            S_MID_FULL = 1 * 4 + 1        # 未达成 · 中带 · 满格
            S_HI_FULL_ACC = 2 * 4 + 1 + 2  # 已达成 · 高带 · 满格
            S_LO_EMPTY_ACC = 0 * 4 + 0 + 2  # 已达成 · 低带 · 未满格
            snap.update({
                "i": i, "achieved": top_done, "purpose_done": purpose_done, "learn": learn,
                "coverage": cov_now, "coverage_tot": cov_tot_now,
                "act_wait": n_wait, "act_up": n_up, "act_down": n_dn,
                "q_table": q, "n_samples": n_samples,
                "wall_s": round(time.time() - t0, 2),
                "B": args.B, "device": dev, "rate": args.rate,
            })
            f.write(json.dumps(snap, ensure_ascii=False) + "\n")
            status.write_text(json.dumps(snap, ensure_ascii=False, indent=1))
            print(f"t={i:7d} k_mean={snap['k_mean']:5.2f} k_min={snap['k_min']:2d} "
                  f"d_mean={snap['d_mean']:5.2f} top={snap['top_frac']:.2f} "
                  f"top_tick={snap['top_tick']:6d} purpose={snap['purpose_tick']:6d} "
                  f"cov={cov_now}/{cov_tot_now} "
                  f"up={snap['up_ok']}/{snap['up_try']} down={snap['down']:6d} "
                  f"q中满={q[S_MID_FULL][0]:+.2f}/{q[S_MID_FULL][1]:+.2f}/{q[S_MID_FULL][2]:+.2f} "
                  f"q顶满={q[S_HI_FULL_ACC][0]:+.2f}/{q[S_HI_FULL_ACC][1]:+.2f}/{q[S_HI_FULL_ACC][2]:+.2f} "
                  f"q低空={q[S_LO_EMPTY_ACC][0]:+.2f}/{q[S_LO_EMPTY_ACC][1]:+.2f}/{q[S_LO_EMPTY_ACC][2]:+.2f}",
                  flush=True)
        i += 1

    f.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
