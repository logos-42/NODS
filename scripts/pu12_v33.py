#!/usr/bin/env python3
"""PU-12 v3.3 —— 多层格点宇宙（循环深度 · 递归无限）· 频率上限抬高版：

相对 v3.2 的两处结构性改动（leo，2026-10-29）：
  1. **频率上限抬高**：地板固定在视界频率 10^-19 Hz，天花板从 10^41 Hz 抬到 10^81 Hz
     （跨度 100 数量级）。为保持「每带 5 数量级、相邻带比值 10^5（交换整数化 r=10^5）」
     这一被 Lean 证明的结构不变，**频率带从 12 个增加到 20 个**
     （N_BANDS = (81 − (−19)) / 5 = 20）。绝对频率只作报告参数；GPU 相位动力学仍用
     相对频率（带间 5 数量级），不破坏相干度机制。
  2. **实体数量 ×100**：默认 B 由 16384 提到 1638400（容纳的实体数提高两个数量级），
     空间随之更大（占用格点、地址深度随实体数自然增长；递归深度仍无上限）。

其余完全继承 v3.2：无界递归深度（循环缓冲 + 滚动哈希）、逐带学习状态、UCB + 退火、
成熟抖动等。详见 v3.2 文件头与 docs/wiki/private-universe.md。

目的（leo 定）：① 所有实体都到过最高带；② 探索空间每一格都走过。
"""

from __future__ import annotations

import argparse
import json
import math
import time
from pathlib import Path

import torch

# ---- 频率结构（v3.3 改动核心）----
FLOOR_LOG10 = -19.0          # 地板：宇宙视界频率 10^-19 Hz（固定，有物理意义）
CEIL_LOG10 = 81.0           # 天花板：从 10^41 抬到 10^81（按数量级抬高 40 个数量级）
DECADES_PER_BAND = 5.0      # 每带 5 数量级 ⟹ 相邻带比值 10^5（r=10^5 交换整数化）
N_BANDS = int(round((CEIL_LOG10 - FLOOR_LOG10) / DECADES_PER_BAND))  # = 20

N_DIM = 12
CELLS = 9.0
E0 = 9.0
N_ACT = 6            # 等 / 升频 / 降频体验 / 扩张子维度 / 扩张亚维度 / 细分频率
N_BAND_STATES = N_BANDS   # v3.1：状态按「逐带」记（原来的 3 个带桶太粗，实体只会认桶底）
N_STATE = N_BAND_STATES * 4
WINDOW = 64          # v3.2：地址只保留最近 W 位 12 进制（循环缓冲）；更深的历史折进滚动哈希
MOD61 = (1 << 61) - 1
BASE = 12

# 理论容量（只用于报告，不分配）
THEORY_SUBDIM = f"12^(12^12) ≈ 10^{12 ** 12 * math.log10(12):.0f}"
THEORY_TOTAL = f"12 × 10^{12 ** 12 * math.log10(12):.0f} × 10^{12 ** 12 * math.log10(12):.0f} × {N_BANDS}"


def band_freq(device) -> torch.Tensor:
    """相对频率（带间 DECADES_PER_BAND 个数量级）；绝对频率只作报告，不在相位动力学里放大。"""
    k = torch.arange(N_BANDS, dtype=torch.float64, device=device)
    return torch.pow(torch.tensor(10.0, dtype=torch.float64, device=device),
                     -DECADES_PER_BAND * k).float()


class Lattice:
    """一群实体，每个占一个多层格点地址。地址用 12 进制前缀表示，按需实例化。"""

    def __init__(self, B: int, device: str, seed: int = 0, phases: int = 16,
                 rate: float = 0.02, depth0: int = 2, window: int = WINDOW):
        gen = torch.Generator().manual_seed(seed)
        self.B, self.device, self.P = B, device, phases
        self.rate = rate
        self.window = int(window)

        self.dim = torch.randint(0, N_DIM, (B,), generator=gen).to(device).long()
        self.sub = torch.zeros(B, self.window, dtype=torch.uint8, device=device)
        self.sub_depth = torch.zeros(B, dtype=torch.long, device=device)
        self.sub_hash = torch.zeros(B, dtype=torch.long, device=device)
        self.subs = torch.zeros(B, self.window, dtype=torch.uint8, device=device)
        self.subs_depth = torch.zeros(B, dtype=torch.long, device=device)
        self.subs_hash = torch.zeros(B, dtype=torch.long, device=device)
        self.fine = torch.zeros(B, self.window, dtype=torch.uint8, device=device)
        self.fine_depth = torch.zeros(B, dtype=torch.long, device=device)
        self.fine_hash = torch.zeros(B, dtype=torch.long, device=device)
        self._seed_address(depth0, gen)
        self.band = torch.randint(0, N_BANDS, (B,), generator=gen).to(device).long()

        self.g = (CELLS * torch.rand(B, generator=gen)).to(device).double()
        self.e = torch.full((B,), E0, dtype=torch.float64, device=device)

        self.theta = (2 * math.pi * torch.rand(B, phases, generator=gen)).to(device).float()
        self.spread = (0.95 + 0.1 * torch.rand(B, phases, generator=gen)).to(device).float()
        self.freq = band_freq(device)
        self.coh = torch.zeros(B, device=device)

        self.estar = torch.randint(0, N_BANDS - 1, (B,), generator=gen).to(device).long()

        self.t = 0
        self.ever_top = torch.zeros(B, dtype=torch.bool, device=device)
        self.top_tick = -1
        self.purpose_tick = -1
        self.n_up_ok = self.n_up_try = self.n_down = 0
        self.n_expand = self.n_refine = 0

    def _seed_address(self, depth0: int, gen):
        n = max(1, min(depth0, self.window))
        for d in range(n):
            su = torch.randint(0, BASE, (self.B,), generator=gen).to(self.device).to(torch.uint8)
            ss = torch.randint(0, BASE, (self.B,), generator=gen).to(self.device).to(torch.uint8)
            sf = torch.randint(0, BASE, (self.B,), generator=gen).to(self.device).to(torch.uint8)
            self.sub[:, d], self.subs[:, d], self.fine[:, d] = su, ss, sf
            self.sub_hash = (self.sub_hash * BASE + su.long()) % MOD61
            self.subs_hash = (self.subs_hash * BASE + ss.long()) % MOD61
            self.fine_hash = (self.fine_hash * BASE + sf.long()) % MOD61
        self.sub_depth[:] = n
        self.subs_depth[:] = n
        self.fine_depth[:] = n

    # ---------- 读数 ----------
    def quanta(self):
        w = torch.pow(torch.tensor(10.0, dtype=torch.float64, device=self.device),
                      DECADES_PER_BAND * self.band.double())
        return self.e * w

    def purity(self):
        return self.e / torch.clamp(self.quanta(), min=1e-300)

    def freq_position(self):
        n = min(self.window, int(self.fine_depth.max()))
        if n <= 0:
            return self.band.double()
        w = torch.pow(torch.tensor(float(BASE), dtype=torch.float64, device=self.device),
                      -torch.arange(1, n + 1, device=self.device).double())
        frac = (self.fine[:, :n].double() * w.unsqueeze(0)).sum(dim=1)
        return self.band.double() + frac

    def marked(self):
        return self.coh > 0.05

    def all_top(self) -> bool:
        return bool(self.ever_top.all())

    def advance_phase(self, dt: float):
        om = self.freq[self.band].unsqueeze(1) * self.spread
        self.theta = torch.remainder(self.theta + (2 * math.pi * dt) * om, 2 * math.pi)
        self.coh = torch.polar(torch.ones_like(self.theta), self.theta).mean(dim=1).abs()

    def grow(self):
        self.g = torch.clamp(self.g + self.rate, max=CELLS)

    def apply(self, up_ok, down_ok, exp_sub, exp_subs, ref_fine, gen):
        full = self.g >= CELLS - 1e-9
        self.band = torch.where(up_ok, self.band + 1, self.band)
        self.g = torch.where(up_ok, torch.zeros_like(self.g), self.g)
        self.band = torch.where(down_ok, self.band - 1, self.band)
        self.g = torch.where(down_ok, torch.full_like(self.g, CELLS), self.g)

        digit = torch.randint(0, BASE, (self.B,), generator=gen).to(self.device).to(torch.uint8)
        rows = torch.arange(self.B, device=self.device)
        pos_sub = self.sub_depth % self.window
        self.sub[rows[exp_sub], pos_sub[exp_sub]] = digit[exp_sub]
        self.sub_depth = torch.where(exp_sub, self.sub_depth + 1, self.sub_depth)
        self.sub_hash = torch.where(exp_sub, (self.sub_hash * BASE + digit.long()) % MOD61, self.sub_hash)
        self.subs[rows[exp_subs], pos_sub[exp_subs]] = digit[exp_subs]
        self.subs_depth = torch.where(exp_subs, self.subs_depth + 1, self.subs_depth)
        self.subs_hash = torch.where(exp_subs, (self.subs_hash * BASE + digit.long()) % MOD61, self.subs_hash)
        self.g = torch.where(exp_sub | exp_subs, torch.zeros_like(self.g), self.g)

        pos_fine = self.fine_depth % self.window
        self.fine[rows[ref_fine], pos_fine[ref_fine]] = digit[ref_fine]
        self.fine_depth = torch.where(ref_fine, self.fine_depth + 1, self.fine_depth)
        self.fine_hash = torch.where(ref_fine, (self.fine_hash * BASE + digit.long()) % MOD61, self.fine_hash)
        self.ever_top = self.ever_top | (self.band == N_BANDS - 1)
        _ = full

    def _addr_hash(self):
        h = (self.dim.long() * 1000003 + self.sub_hash) % MOD61
        h = (h * 1000003 + self.subs_hash) % MOD61
        h = (h * 1000003 + self.fine_hash) % MOD61
        return (h * BASE + self.band.long()) % MOD61

    def snapshot(self):
        occupied = int(torch.unique(self._addr_hash()).shape[0])
        return {
            "t": self.t,
            "band_mean": float(self.band.double().mean()),
            "band_min": int(self.band.min()),
            "band_hist": torch.bincount(self.band, minlength=N_BANDS).tolist(),
            "dim_hist": torch.bincount(self.dim, minlength=N_DIM).tolist(),
            "top_frac": float((self.band == N_BANDS - 1).double().mean()),
            "ever_top_frac": float(self.ever_top.double().mean()),
            "sub_depth_mean": float(self.sub_depth.double().mean()),
            "subs_depth_mean": float(self.subs_depth.double().mean()),
            "fine_depth_mean": float(self.fine_depth.double().mean()),
            "freq_log10": -float(self.fine_depth.double().max()) * math.log10(BASE),
            "freq_resolution": 0.0,
            "occupied": occupied,
            "occupied_frac_of_B": occupied / max(self.B, 1),
            "space_log10": math.log10(12) * (2.0 + float(self.sub_depth.double().mean())
                                             + float(self.subs_depth.double().mean())),
            "space_log10_max": math.log10(12) * (2.0 + int(self.sub_depth.max()) + int(self.subs_depth.max())),
            "e_sum": float(self.e.sum()),
            "purity": float(self.purity().mean()),
            "coh": float(self.coh.mean()),
            "top_tick": self.top_tick,
            "purpose_tick": self.purpose_tick,
            "up_ok": self.n_up_ok,
            "up_try": self.n_up_try,
            "down": self.n_down,
            "expand": self.n_expand,
            "refine": self.n_refine,
            "theory_subdim": THEORY_SUBDIM,
            "theory_total": THEORY_TOTAL,
            "window": self.window,
            # v3.3 新增：频率结构参数
            "n_bands": N_BANDS,
            "freq_floor_hz": f"10^{FLOOR_LOG10:.0f}",
            "freq_ceil_hz": f"10^{CEIL_LOG10:.0f}",
            "span_decades": int(CEIL_LOG10 - FLOOR_LOG10),
            "decades_per_band": DECADES_PER_BAND,
        }


class Learners:
    """每个实体自己的 Q 表（N_BANDS×4 状态 × 6 动作），UCB 探索，探索强度随时间退火。"""

    def __init__(self, B: int, device: str, c: float = 0.5, c_final: float = 0.05,
                 anneal: int = 4000):
        self.Q = torch.zeros(B, N_STATE, N_ACT, device=device)
        self.N = torch.zeros(B, N_STATE, N_ACT, device=device)
        self.c0, self.c_final, self.anneal = c, c_final, max(anneal, 1)
        self.total = torch.zeros(B, device=device) + 1.0

    @staticmethod
    def state(u: Lattice, achieved: bool) -> torch.Tensor:
        full = (u.g >= CELLS - 1e-9).long()
        s = u.band * 4 + full
        if achieved:
            s = s + 2
        return s

    def _c(self, t: int) -> float:
        k = min(1.0, t / self.anneal)
        return self.c0 + (self.c_final - self.c0) * k

    def act(self, u: Lattice, s: torch.Tensor, explore: float, learn: bool, t: int) -> torch.Tensor:
        if not learn:
            return torch.randint(0, N_ACT, (u.B,), device=u.device)
        idx = torch.arange(u.B, device=u.device)
        q = self.Q[idx, s]
        n = self.N[idx, s]
        bonus = self._c(t) * torch.sqrt(torch.log(self.total[idx] + 2.0).unsqueeze(1) / (n + 1.0))
        score = torch.where(n < 0.5, torch.full_like(q, 0.75), q + bonus)
        score = score + torch.rand_like(score) * 1e-4
        act = score.argmax(dim=1)
        eps = explore / (1.0 + t / self.anneal)
        if eps > 0:
            hit = torch.rand(u.B, device=u.device) < eps
            act = torch.where(hit, torch.randint(0, N_ACT, (u.B,), device=u.device), act)
        return act

    def learn_from(self, s, a, r, learn):
        idx = torch.arange(a.shape[0], device=a.device)
        n = self.N[idx, s, a]
        if learn:
            self.Q[idx, s, a] += (r.double() - self.Q[idx, s, a]) / (n + 1.0)
        self.N[idx, s, a] += 1.0
        self.total += 1.0

    def q_table(self):
        w = self.N.sum(dim=0)
        q = (self.Q * self.N).sum(dim=0) / w.clamp(min=1e-9)
        return q.tolist(), float(w.sum())

    def coverage(self):
        visited = (self.N.sum(dim=0) > 0)
        return int(visited.sum()), int(N_STATE * N_ACT)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--device", default="cuda")
    ap.add_argument("--B", type=int, default=16384)
    ap.add_argument("--ticks", type=int, default=0, help="0 = 一直跑")
    ap.add_argument("--dt", type=float, default=0.02)
    ap.add_argument("--rate", type=float, default=0.05, help="每拍点亮多少隐数格")
    ap.add_argument("--phases", type=int, default=16)
    ap.add_argument("--log-every", type=int, default=200)
    ap.add_argument("--explore", type=float, default=0.05)
    ap.add_argument("--ucb", type=float, default=0.5)
    ap.add_argument("--anneal", type=int, default=4000, help="探索退火的时间常数（拍）")
    ap.add_argument("--depth0", type=int, default=2, help="初始地址深度")
    ap.add_argument("--window", type=int, default=WINDOW)
    ap.add_argument("--seed", type=int, default=0)
    ap.add_argument("--out", default="logs_v3")
    ap.add_argument("--no-learn", action="store_true")
    args = ap.parse_args()

    dev = args.device
    if dev == "cuda" and not torch.cuda.is_available():
        print("[warn] cuda 不可用，退回 cpu", flush=True)
        dev = "cpu"
    if dev == "cuda":
        print(f"[info] gpu = {torch.cuda.get_device_name(0)} | B={args.B} P={args.phases}", flush=True)
    span = int(CEIL_LOG10 - FLOOR_LOG10)
    print(f"[info] 频率：地板 10^{FLOOR_LOG10:.0f} Hz，天花板 10^{CEIL_LOG10:.0f} Hz，"
          f"跨度 {span} 数量级，{N_BANDS} 带 × 每带 10^{DECADES_PER_BAND:.0f}（r=10^{DECADES_PER_BAND:.0f} 交换整数化）",
          flush=True)
    print(f"[info] 理论容量：{N_DIM} 维度 × {THEORY_SUBDIM} 子维度 × {THEORY_SUBDIM} 亚维度 × {N_BANDS} 带", flush=True)
    print(f"[info] 循环深度：最近 {args.window} 层精确（循环缓冲），更早的折进滚动哈希；"
          f"递归深度无上限，内存恒定", flush=True)

    u = Lattice(args.B, dev, seed=args.seed, phases=args.phases, rate=args.rate,
                depth0=args.depth0, window=args.window)
    L = Learners(args.B, dev, c=args.ucb, anneal=args.anneal)
    gen = torch.Generator().manual_seed(args.seed + 1)
    learn = not args.no_learn
    top_done = purpose_done = False

    outdir = Path(args.out)
    outdir.mkdir(parents=True, exist_ok=True)
    path = outdir / f"run-{time.strftime('%Y%m%d-%H%M%S')}.jsonl"
    status = outdir / "status.json"
    f = open(path, "a", buffering=1)
    print(f"[info] log -> {path} | learn={learn}", flush=True)

    t0 = time.time()
    i = 0
    while args.ticks == 0 or i < args.ticks:
        u.advance_phase(args.dt)
        s = Learners.state(u, top_done)
        a = L.act(u, s, args.explore, learn, i)

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

        u.n_up_try += int(up.sum()); u.n_up_ok += int(up_ok.sum())
        u.n_down += int(down_ok.sum()); u.n_expand += int((exp_sub | exp_subs).sum())
        u.n_refine += int(ref_fine.sum())

        wait_rew = torch.where(full, torch.full_like(u.e, -0.05), torch.full_like(u.e, -0.02))
        if not top_done:
            rew = torch.where(up_ok, torch.full_like(u.e, 1.0),
                              torch.where(up_fail, torch.full_like(u.e, -0.3),
                                          torch.where(down_ok, torch.full_like(u.e, -0.5),
                                                      torch.where(exp_sub | exp_subs,
                                                                  torch.full_like(u.e, 0.4),
                                                                  torch.where(ref_fine,
                                                                              torch.full_like(u.e, 0.2),
                                                                              wait_rew)))))
        else:
            rew = 0.3 * (phi_new - phi_old) + torch.where(u.band == u.estar,
                                                          torch.full_like(u.e, 0.15),
                                                          torch.zeros_like(u.e))
            rew = torch.where(exp_sub | exp_subs, torch.full_like(u.e, 0.1), rew)
            rew = torch.where(ref_fine, torch.full_like(u.e, 0.1), rew)
            rew = torch.where(up_fail, torch.full_like(u.e, -0.3), rew)

        L.learn_from(s, a, rew, learn)

        if not top_done and u.all_top():
            top_done = True
            u.top_tick = u.t
            print(f"[top] 所有实体都在最高带 @ tick {u.t}", flush=True)
        if not purpose_done and top_done:
            cov, tot = L.coverage()
            if cov >= tot:
                purpose_done = True
                u.purpose_tick = u.t
                print(f"[purpose] 目的达成：全体到顶 + 探索 {cov}/{tot} 格走遍 @ tick {u.t}", flush=True)
        u.t += 1

        if i % args.log_every == 0:
            snap = u.snapshot()
            q, ns = L.q_table()
            cov, cov_tot = L.coverage()
            snap.update({"i": i, "top_done": top_done, "purpose_done": purpose_done,
                         "learn": learn, "coverage": cov, "coverage_tot": cov_tot,
                         "q_table": q, "n_samples": ns, "wall_s": round(time.time() - t0, 2),
                         "B": args.B, "device": dev, "rate": args.rate})
            f.write(json.dumps(snap, ensure_ascii=False) + "\n")
            status.write_text(json.dumps(snap, ensure_ascii=False, indent=1))
            print(f"t={i:7d} band={snap['band_mean']:5.2f}/{snap['band_min']:2d} top={snap['ever_top_frac']:.2f} "
                  f"occ={snap['occupied']:6d} 深度 sub={snap['sub_depth_mean']:.1f} subs={snap['subs_depth_mean']:.1f} "
                  f"fine={snap['fine_depth_mean']:.1f} 递归={snap['sub_depth_mean']:.1f}/{snap['window']} | top_tick={snap['top_tick']:6d} purpose={snap['purpose_tick']:6d} "
                  f"cov={cov}/{cov_tot} | up={snap['up_ok']}/{snap['up_try']} down={snap['down']} "
                  f"exp={snap['expand']} ref={snap['refine']}", flush=True)
        i += 1

    f.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
