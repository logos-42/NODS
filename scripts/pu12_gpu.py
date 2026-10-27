#!/usr/bin/env python3
"""PU-12 连续宇宙模拟（GPU / torch）

把 `Nods/Theories/Universe.lean` + `scripts/universe_model.py` 的模型搬到 GPU 上**连续**演化，
用来观察「发展情况」：

  12 频率带：5 个数量级一带，天花板 10^41 Hz，地板 10^-19 Hz（视界逼出，见 wiki）
  12 维度：每维 3 子维度（σ₁σ₂σ₃）× 3 亚维度（隐数 S/R/iR）= 9 个隐数格
  能量单位 = 隐数「束」：1 束在任意带上都是 ε₀ ⟹ 能量 = 束数（精确守恒）
  量子数 N = Σ b_k·10^(5k) ⟹ 逐级转写时量子数 ×10^5、纯度 ÷10^5
  流动：τ = 条数差（TCM 塌缩定理），通量由 τ > 0 与「成熟时间」门控
  维度扩展：满格并成熟 `--mature` 拍后，能量按 κ 交给下一维（内生获得），该维原子出生
  相位：每带 P 个振子 θ += 2π f_k dt（振动坐标系），带内频率略有离散 ⟹ 走离相
  提案网：3 维隐数码 → 12 带打分，与规则 frontier 对账（接受率 = 学到规则的程度，不参与物理）

每 `--log-every` 拍写一行 JSONL + 覆盖 status.json，另有 stdout 摘要。
`--ticks 0` 一直跑；生命史循环（`--respawn`）让系综长期保持「各阶段都有宇宙」。

用法：
    python3 pu12_gpu.py --device cuda --B 4096 --ticks 0 --mature 3000 --log-every 200
    python3 pu12_gpu.py --device cpu  --B 64 --ticks 400 --mature 20   # 冒烟测试
"""

from __future__ import annotations

import argparse
import json
import math
import time
from pathlib import Path

import torch

N_BANDS = 12
R = 10 ** 5            # 相邻带量子数/能量比
CELLS = 9              # 3 子维度 × 3 亚维度
E0 = 9.0               # 初始授予 = 9 束 = 每个隐数格一束


def band_omega():
    """归一化角速度（带 0 = 1，带 11 = 10^-55）：高频转得快。"""
    k = torch.arange(N_BANDS, dtype=torch.float64)
    return torch.pow(torch.tensor(10.0, dtype=torch.float64), -5.0 * k)


class PU12:
    def __init__(self, B: int, device: str, seed: int = 0, phases: int = 64,
                 inject: float = 0.0, mature: int = 1, respawn: bool = True,
                 dwell: int = 500, kappa_lo: float = 0.2, kappa_hi: float = 0.8,
                 mature_jitter: float = 0.0):
        g = torch.Generator().manual_seed(seed)
        self.B, self.device, self.P = B, device, phases
        self.mature, self.dwell, self.respawn = mature, dwell, respawn
        self.inject = inject

        self.b = torch.zeros(B, N_BANDS, dtype=torch.float64, device=device)
        self.b[:, 0] = E0                                   # 初始授予
        self.born = torch.zeros(B, N_BANDS, dtype=torch.bool, device=device)
        self.born[:, 0] = True
        self.hold = torch.zeros(B, N_BANDS, dtype=torch.long, device=device)
        self.age = torch.zeros(B, dtype=torch.long, device=device)
        self.cycle = torch.zeros(B, dtype=torch.long, device=device)
        self.injected = torch.zeros(B, dtype=torch.float64, device=device)
        self.n_respawn = 0
        self.t = 0

        # 每个宇宙的耦合 κ（异质 ⟹ 发展速度不同，系综才有分布）
        self.kappa = (kappa_lo + (kappa_hi - kappa_lo) * torch.rand(B, generator=g)).to(device).double()

        # 每个宇宙的成熟阈值（jitter=0 时退化为全局常数 mature，与原模型逐位一致）
        if mature_jitter > 0:
            j = 1.0 + mature_jitter * (2 * torch.rand(B, generator=g) - 1)
            self.mature_i = torch.clamp((mature * j).round(), min=1).to(device).long()
        else:
            self.mature_i = torch.full((B,), int(mature), dtype=torch.long, device=device)

        # 相位振子：θ[b,k,p]，带内频率有微小离散（走离相）
        self.theta = (2 * math.pi * torch.rand(B, N_BANDS, phases, generator=g)).to(device).float()
        spread = (0.95 + 0.1 * torch.rand(B, N_BANDS, phases, generator=g)).to(device).float()
        self.omega = band_omega().float().to(device).view(1, N_BANDS, 1) * spread

    # ---------------- 结构读数 ----------------
    def cells(self):
        """条数：原子出生的维恒为 9 格；未出生的维 0。"""
        return torch.where(self.born, torch.full_like(self.b, float(CELLS)), torch.zeros_like(self.b))

    def tau(self):
        """τ = 条数差（上带满格、下带未出生 ⟹ τ = 9）。"""
        a = self.cells()
        return torch.clamp(a[:, :-1] - a[:, 1:], min=0.0)

    def quanta(self):
        r = torch.pow(torch.tensor(float(R), dtype=torch.float64, device=self.device),
                      torch.arange(N_BANDS, device=self.device).double())
        return (self.b * r).sum(dim=1)

    def purity(self):
        """平均量子能量 Π = E/N（带 0 的量子 Π = 1）。"""
        return self.b.sum(dim=1) / torch.clamp(self.quanta(), min=1e-300)

    def coherence(self):
        """Kuramoto 序参量：每带相位锁的程度，按能量加权。"""
        z = torch.polar(torch.ones_like(self.theta), self.theta).mean(dim=2).abs()
        w = self.b / torch.clamp(self.b.sum(dim=1, keepdim=True), min=1e-300)
        return (z * w).sum(dim=1), z

    def frontier(self):
        """规则要求的下一维：某带满格、下一带未出生。没有则 -1。"""
        a = self.cells()
        unborn_next = torch.cat([~self.born[:, 1:],
                                 torch.zeros(self.B, 1, dtype=torch.bool, device=self.device)], dim=1)
        cand = (a >= CELLS) & unborn_next
        idx = torch.argmax(cand.double(), dim=1)
        return torch.where(cand.any(dim=1), idx, torch.full_like(idx, -1))

    def dims(self):
        return self.born.sum(dim=1)

    # ---------------- 一步演化 ----------------
    def step(self, dt: float, lock: float = 0.25):
        # 0) 结构场注入（默认 0：与 Lean 模型一致的「一次性授予」）
        if self.inject > 0:
            add = self.inject * dt
            self.b = self.b.clone()
            self.b[:, 0] += add
            self.injected += add

        # 1) 成熟计时 + 维度出生（能量按 κ 交给下一维 = 内生获得）
        unborn_next = torch.cat([~self.born[:, 1:],
                                 torch.zeros(self.B, 1, dtype=torch.bool, device=self.device)], dim=1)
        ready = (self.cells() >= CELLS) & unborn_next          # (B, 12) 逐格的「可生」掩码
        self.hold = torch.where(ready, self.hold + 1, torch.zeros_like(self.hold))
        matured = ready & (self.hold >= self.mature_i.unsqueeze(1))
        fr = torch.argmax((matured).double(), dim=1)
        fr = torch.where(matured.any(dim=1), fr, torch.full_like(fr, -1))
        if bool(matured.any()):
            for k in range(N_BANDS - 1):
                sel = matured[:, k]
                if bool(sel.any()):
                    moved = self.b[sel, k] * self.kappa[sel]
                    self.b[sel, k + 1] += moved          # 能量精确守恒（束数不变）
                    self.b[sel, k] -= moved
                    self.born[sel, k + 1] = True
                    self.hold[sel, k] = 0

        # 2) 相位演化（振动坐标）+ 微弱锁相
        self.theta = torch.remainder(self.theta + (2 * math.pi * dt) * self.omega, 2 * math.pi)
        z = torch.polar(torch.ones_like(self.theta), self.theta).mean(dim=2, keepdim=True)
        psi = torch.angle(z)
        pull = lock * torch.sin(psi - self.theta) * 0.02
        self.theta = torch.remainder(self.theta + pull, 2 * math.pi)

        # 3) 生命史：长满 12 维并停留 dwell 拍后重生
        self.age += 1
        if self.respawn:
            due = (self.dims() >= N_BANDS) & (self.age >= self.dwell)
            if bool(due.any()):
                idx = due.nonzero(as_tuple=True)[0]
                n = int(len(idx))
                self.b[idx] = 0.0
                self.b[idx, 0] = E0
                self.born[idx] = False
                self.born[idx, 0] = True
                self.hold[idx] = 0
                self.theta[idx] = (2 * math.pi * torch.rand(n, N_BANDS, self.P, device=self.device))
                self.injected[idx] = 0.0
                self.age[idx] = 0
                self.cycle[idx] += 1
                self.n_respawn += n
        self.t += 1

    # ---------------- 快照 ----------------
    def snapshot(self):
        coh, _ = self.coherence()
        n = self.quanta()
        err = float((self.b.sum(dim=1) - (E0 + self.injected)).abs().max())
        return {
            "t": self.t,
            "cycles": self.n_respawn,
            "dims_mean": float(self.dims().double().mean()),
            "dims_hist": torch.bincount(self.dims(), minlength=N_BANDS + 1).tolist(),
            "energy": float(self.b.sum()),
            "energy_err": err,
            "quanta": float(n.mean()),
            "purity": float(self.purity().mean()),
            "coherence": float(coh.mean()),
            "tau_mean": float(self.tau().mean()),
            "pending": int((self.frontier() >= 0).sum()),
        }


class Proposal(torch.nn.Module):
    """生长提案网：12 带 × 4 特征 → 64 → 3 维隐数码（σ₁σ₂σ₃）→ 12 带打分。

    只「猜」下一维长在哪里；规则（满格 + 成熟）负责接受。接受率是学习曲线，不参与物理。
    """

    def __init__(self):
        super().__init__()
        self.inp = torch.nn.Linear(N_BANDS * 4, 64)
        self.hidden3 = torch.nn.Linear(64, 3)     # 隐数空间三维（σ₁σ₂σ₃）
        self.out = torch.nn.Linear(3, N_BANDS)
        self.skip = torch.nn.Linear(N_BANDS * 2, N_BANDS)   # 直连：τ + born（让规则可学）

    def forward(self, feats):
        h = torch.relu(self.inp(feats))
        h3 = torch.tanh(self.hidden3(h))
        skip = feats[:, 2 * N_BANDS:4 * N_BANDS]          # (τ, born)
        return self.out(h3) + self.skip(skip)


def features(u: PU12):
    a = u.cells().double() / CELLS
    tau = torch.cat([u.tau(), torch.zeros(u.B, 1, dtype=torch.float64, device=u.device)], dim=1)
    lb = torch.log1p(torch.clamp(u.b, min=0)) / 10.0
    return torch.cat([lb, a, tau, u.born.double()], dim=1).float()


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--device", default="cuda")
    ap.add_argument("--B", type=int, default=4096)
    ap.add_argument("--ticks", type=int, default=0, help="0 = 一直跑")
    ap.add_argument("--dt", type=float, default=0.05)
    ap.add_argument("--mature", type=int, default=3000, help="满格后多少拍才允许生下一维")
    ap.add_argument("--mature-jitter", type=float, default=0.0,
                    help="每个宇宙成熟阈值的相对抖动 (±j)；0 = 原模型（全系综同步）")
    ap.add_argument("--dwell", type=int, default=500)
    ap.add_argument("--inject", type=float, default=0.0)
    ap.add_argument("--phases", type=int, default=64)
    ap.add_argument("--log-every", type=int, default=200)
    ap.add_argument("--seed", type=int, default=0)
    ap.add_argument("--out", default="logs")
    ap.add_argument("--no-respawn", action="store_true")
    ap.add_argument("--no-net", action="store_true")
    args = ap.parse_args()

    dev = args.device
    if dev == "cuda" and not torch.cuda.is_available():
        print("[warn] cuda 不可用，退回 cpu", flush=True)
        dev = "cpu"
    if dev == "cuda":
        print(f"[info] gpu = {torch.cuda.get_device_name(0)} | B={args.B} P={args.phases}", flush=True)

    u = PU12(args.B, dev, seed=args.seed, phases=args.phases, inject=args.inject,
             mature=args.mature, respawn=not args.no_respawn, dwell=args.dwell,
             mature_jitter=args.mature_jitter)
    net = Proposal().to(dev)
    opt = torch.optim.Adam(net.parameters(), lr=1e-3)
    ce = torch.nn.CrossEntropyLoss()

    outdir = Path(args.out)
    outdir.mkdir(parents=True, exist_ok=True)
    path = outdir / f"run-{time.strftime('%Y%m%d-%H%M%S')}.jsonl"
    status = outdir / "status.json"
    f = open(path, "a", buffering=1)
    print(f"[info] log -> {path}", flush=True)

    t0, i = time.time(), 0
    while args.ticks == 0 or i < args.ticks:
        u.step(args.dt)

        loss_val = acc = None
        if not args.no_net:
            fr = u.frontier()
            mask = fr >= 0
            if int(mask.sum()) >= 8:
                logits = net(features(u)[mask])
                tgt = fr[mask]
                loss = ce(logits, tgt)
                opt.zero_grad()
                loss.backward()
                opt.step()
                loss_val = float(loss.detach())
                acc = float((logits.detach().argmax(dim=1) == tgt).float().mean())

        if i % args.log_every == 0:
            snap = u.snapshot()
            snap.update({"i": i, "loss": loss_val, "accept": acc,
                         "wall_s": round(time.time() - t0, 2),
                         "mature": args.mature, "B": args.B, "device": dev})
            f.write(json.dumps(snap, ensure_ascii=False) + "\n")
            status.write_text(json.dumps(snap, ensure_ascii=False, indent=1))
            print(f"t={i:7d} dims={snap['dims_mean']:5.2f} cyc={snap['cycles']:5d} "
                  f"E={snap['energy']:.1f} err={snap['energy_err']:.1e} "
                  f"N={snap['quanta']:.2e} purity={snap['purity']:.2e} "
                  f"coh={snap['coherence']:.3f} tau={snap['tau_mean']:.2f} "
                  f"pend={snap['pending']:4d} "
                  f"loss={'%.3f' % loss_val if loss_val is not None else '   - '} "
                  f"acc={'%.2f' % acc if acc is not None else '  - '}", flush=True)
        i += 1
    f.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
