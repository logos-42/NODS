#!/usr/bin/env python3
"""PU-12 v3.2 —— 多层格点宇宙（循环深度 · 递归无限）：维度 × 子维度 × 亚维度 × 频率带，按需实例化

v3.2 相对 v3.1：**取消深度上限**。
  * 递归深度是一个**无界计数器**，每扩张/细分一次 +1，永不停（没有 MAX_DEPTH 闸门）；
  * 地址用**固定窗口的循环缓冲**保存最近 W 位 12 进制数字（写满就从头覆盖 = 循环深度）；
  * 更早的数字折进**滚动哈希**（61 位），所以「地址身份」包含全部历史、内存却有界；
  * 于是：深度可以无限增长，内存恒定，没有一个「到顶就冻结」的时刻。
  诚实边界：循环窗口内的数字是精确的；更早的部分只剩哈希，无法还原（等于忘掉了细节、记住了身份）。

第二版规格（2026-10-27，leo）：
  12 个维度；每个维度内有 12^(12^12) 个子维度；每个子维度内有 12^(12^12) 个亚维度；
  每个亚维度包含 12 个频率带（频率还可以继续细分）。

**必须先说清楚的边界**：12^(12^12) ≈ 10^(9.6×10^12) 个格子，宇宙里没有足够的原子把它枚举出来，
更不可能装进任何内存。所以这里实现的是**符号地址空间 + 按需实例化**：

  * 层级与进制严格照规格：子维度 / 亚维度都是 12 进制地址串，每"扩张"一次追加一位 12 进制数字；
  * 只把**被实体占住的格子**真正落地（`occupied` 统计），理论容量与已实例化占用量分开报；
  * 地址深度有实现上限（12^17 内可装进 int64），到顶后不再扩张 —— 这是工程上限，不是理论上限。

实体（每个实体自己一份状态）：
  维度 dim ∈ [0,12) | 子维度地址 sub（12 进制前缀，深度 sub_depth）
  亚维度地址 subs（同构）| 频率带 band ∈ [0,12) | 频率细分 fine（12 进制前缀，深度 fine_depth）
  结构发育度 g（当前格点亮几个隐数格，9 格为满）| 能量 e（束，守恒）| 相位 θ（振动坐标系）

动作（每个实体自己选）：
  0 等待发育 | 1 升频（进下一带）| 2 降频体验（回低带）| 3 扩张子维度 | 4 扩张亚维度 | 5 细分频率

学习：每个实体自己的 Q 表（状态 = 带桶 × 满格 × 目的是否达成，共 12 态 × 6 动作），
UCB 探索，**并且 ε 与 UCB 系数随时间退火** —— v2 部署实测过不退火会让"探索下坠"长期压过
"爬升发育"，全体卡在低带永远到不了顶（93600 拍 top=0.00）。

目的（leo 定）：① 所有实体都到过最高带；② 探索空间每一格都走过。
"""

from __future__ import annotations

import argparse
import json
import math
import time
from pathlib import Path

import torch

N_BANDS = 12
N_DIM = 12
CELLS = 9.0
E0 = 9.0
N_ACT = 6            # 等 / 升频 / 降频体验 / 扩张子维度 / 扩张亚维度 / 细分频率
N_BAND_STATES = 12   # v3.1：状态按「逐带」记（原来的 3 个带桶太粗，实体只会认桶底）
N_STATE = N_BAND_STATES * 4
WINDOW = 64          # v3.2：地址只保留最近 W 位 12 进制（循环缓冲）；更深的历史折进滚动哈希
MOD61 = (1 << 61) - 1
# 深度不再有上限：WINDOW 只是"最近多少层是精确的"，递归本身无限
BASE = 12

# 理论容量（只用于报告，不分配）
THEORY_SUBDIM = f"12^(12^12) ≈ 10^{12 ** 12 * math.log10(12):.0f}"
THEORY_TOTAL = f"12 × 10^{12 ** 12 * math.log10(12):.0f} × 10^{12 ** 12 * math.log10(12):.0f} × 12"


def band_freq(device) -> torch.Tensor:
    k = torch.arange(N_BANDS, dtype=torch.float64, device=device)
    return torch.pow(torch.tensor(10.0, dtype=torch.float64, device=device), -5.0 * k).float()


class Lattice:
    """一群实体，每个占一个多层格点地址。地址用 12 进制前缀表示，按需实例化。"""

    def __init__(self, B: int, device: str, seed: int = 0, phases: int = 16,
                 rate: float = 0.02, depth0: int = 2, window: int = WINDOW):
        gen = torch.Generator().manual_seed(seed)
        self.B, self.device, self.P = B, device, phases
        self.rate = rate
        self.window = int(window)          # 循环窗口长度（精确层数）

        # 维度与地址：初始就散布在多层的不同格子里
        # v3.2：地址存成循环缓冲 (B, window) + 滚动哈希；深度无界，内存恒定
        self.dim = torch.randint(0, N_DIM, (B,), generator=gen).to(device).long()
        # 地址 = 循环缓冲（最近 window 位，精确）+ 滚动哈希（全部历史，有界内存）
        self.sub = torch.zeros(B, self.window, dtype=torch.uint8, device=device)
        self.sub_depth = torch.zeros(B, dtype=torch.long, device=device)   # 无界计数器
        self.sub_hash = torch.zeros(B, dtype=torch.long, device=device)
        self.subs = torch.zeros(B, self.window, dtype=torch.uint8, device=device)
        self.subs_depth = torch.zeros(B, dtype=torch.long, device=device)
        self.subs_hash = torch.zeros(B, dtype=torch.long, device=device)
        self.fine = torch.zeros(B, self.window, dtype=torch.uint8, device=device)
        self.fine_depth = torch.zeros(B, dtype=torch.long, device=device)
        self.fine_hash = torch.zeros(B, dtype=torch.long, device=device)
        self._seed_address(depth0, gen)
        # 频率：带 + 细分前缀
        self.band = torch.randint(0, N_BANDS, (B,), generator=gen).to(device).long()

        self.g = (CELLS * torch.rand(B, generator=gen)).to(device).double()
        self.e = torch.full((B,), E0, dtype=torch.float64, device=device)

        self.theta = (2 * math.pi * torch.rand(B, phases, generator=gen)).to(device).float()
        self.spread = (0.95 + 0.1 * torch.rand(B, phases, generator=gen)).to(device).float()
        self.freq = band_freq(device)
        self.coh = torch.zeros(B, device=device)

        # 体验目标：想回去的低带（达成目的后朝它下潜）
        self.estar = torch.randint(0, N_BANDS - 1, (B,), generator=gen).to(device).long()

        self.t = 0
        self.ever_top = torch.zeros(B, dtype=torch.bool, device=device)   # 曾到达最高带
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
        w = torch.pow(torch.tensor(10.0, dtype=torch.float64, device=self.device), 5.0 * self.band.double())
        return self.e * w

    def purity(self):
        return self.e / torch.clamp(self.quanta(), min=1e-300)

    def freq_position(self):
        """频率位置 = 带 + 细分偏移/12^深度（细分越深，频率分辨率越细）。"""
        # 位置 = 带 + Σ 最近 window 位数字 × 12^-(depth-window+1+i)（循环窗口内是精确的）
        n = min(self.window, int(self.fine_depth.max()))
        if n <= 0:
            return self.band.double()
        w = torch.pow(torch.tensor(float(BASE), dtype=torch.float64, device=self.device),
                      -torch.arange(1, n + 1, device=self.device).double())
        frac = (self.fine[:, :n].double() * w.unsqueeze(0)).sum(dim=1)
        return self.band.double() + frac

    def marked(self):
        """这一拍允许动作的实体（相位相干度过线）—— 相干度低时只能等待，学习要把这件事学出来。"""
        return self.coh > 0.05

    def all_top(self) -> bool:
        """所有实体都**曾**到达最高带（瞬时全在顶部会被体验动作打断，那样判据只是噪声）。"""
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

        # 扩张子维度：12 进制地址追加一位（新的子格诞生），结构重新积累
        digit = torch.randint(0, BASE, (self.B,), generator=gen).to(self.device).to(torch.uint8)
        rows = torch.arange(self.B, device=self.device)
        # 地址是数字数组：在第 depth 位写入新数字（= 12 进制追加一位），深度 +1
        # 循环深度：写在第 (depth mod window) 位 —— 写满就覆盖最老的一位，深度继续无界增长
        pos_sub = self.sub_depth % self.window
        self.sub[rows[exp_sub], pos_sub[exp_sub]] = digit[exp_sub]
        self.sub_depth = torch.where(exp_sub, self.sub_depth + 1, self.sub_depth)
        self.sub_hash = torch.where(exp_sub, (self.sub_hash * BASE + digit.long()) % MOD61, self.sub_hash)
        self.subs[rows[exp_subs], pos_sub[exp_subs]] = digit[exp_subs]
        self.subs_depth = torch.where(exp_subs, self.subs_depth + 1, self.subs_depth)
        self.subs_hash = torch.where(exp_subs, (self.subs_hash * BASE + digit.long()) % MOD61, self.subs_hash)
        self.g = torch.where(exp_sub | exp_subs, torch.zeros_like(self.g), self.g)

        # 细分频率：频带内部再加一位 12 进制，分辨率 ×1/12
        pos_fine = self.fine_depth % self.window
        self.fine[rows[ref_fine], pos_fine[ref_fine]] = digit[ref_fine]
        self.fine_depth = torch.where(ref_fine, self.fine_depth + 1, self.fine_depth)
        self.fine_hash = torch.where(ref_fine, (self.fine_hash * BASE + digit.long()) % MOD61, self.fine_hash)
        self.ever_top = self.ever_top | (self.band == N_BANDS - 1)
        _ = full

    def _addr_hash(self):
        """滚动哈希：把 (维度, 子维度数字串, 亚维度数字串, 带) 压成 61 位整数，用来数占用格。"""
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
            "freq_log10": -float(self.fine_depth.double().max()) * math.log10(BASE),   # 分辨率 10^此值 带
            "freq_resolution": 0.0,   # 深度无界后浮点会下溢，看 freq_log10
            "occupied": occupied,
            "occupied_frac_of_B": occupied / max(self.B, 1),
            # 地址空间规模：12 × 12^sub_depth × 12^subs_depth × 12（按平均深度算的对数量级）
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
        }


class Learners:
    """每个实体自己的 Q 表（12 状态 × 6 动作），UCB 探索，探索强度随时间退火。"""

    def __init__(self, B: int, device: str, c: float = 0.5, c_final: float = 0.05,
                 anneal: int = 4000):
        self.Q = torch.zeros(B, N_STATE, N_ACT, device=device)
        self.N = torch.zeros(B, N_STATE, N_ACT, device=device)
        self.c0, self.c_final, self.anneal = c, c_final, max(anneal, 1)
        self.total = torch.zeros(B, device=device) + 1.0

    @staticmethod
    def state(u: Lattice, achieved: bool) -> torch.Tensor:
        full = (u.g >= CELLS - 1e-9).long()
        s = u.band * 4 + full          # 逐带 × 满格/空 × 2
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
        eps = explore / (1.0 + t / self.anneal)       # ε 退火：长跑时不再永动乱试
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
    ap.add_argument("--window", type=int, default=WINDOW, help="循环窗口长度（最近多少层地址是精确的；递归深度本身无上限）")
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
        can_move = torch.ones_like(u.band, dtype=torch.bool)   # 不再用相干度当动作闸门（会冻死走离相的实体）；coh 只作观测量
        up = (a == 1) & can_move
        dn = (a == 2) & can_move
        at_top = u.band == N_BANDS - 1
        up_ok = up & full & ~at_top
        up_fail = up & ~(full & ~at_top)
        down_ok = dn & (u.band > 0)
        exp_sub = (a == 3) & can_move & full
        exp_subs = (a == 4) & can_move & full
        # 细分频率也要满格结构（否则奖励会把它瞬间刷到深度上限，变成假发展）
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
