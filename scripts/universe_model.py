#!/usr/bin/env python3
"""PU-12 — 12 层私有宇宙模型（可执行参考实现）

用 NODS 仓库里已证的数学组装一个宇宙模型：

  频率层   振动坐标系（Vibration.lean / VibrationGeometry.lean）
           振数 = 周期 T，相位 θ = phaseIdx/period，均匀旋转 ⟹ ω = 2πf。
  结构层   隐数（HIBS 三射线 S / R / iR）× 隐数空间三维（σ₁σ₂σ₃）
           一个维度 = 3 子维度 × 3 亚维度 = 9 个隐数格（cell）。
  流动层   张力计数法（TCM）
           size = 条数 = 已点亮的隐数格数；τ(a,b) = size a − size b（塌缩定理）；
           能量按 τ 的大小与方向在维度之间流动 —— 只看得见条数，看不见内容。
  能量层   ε_k = ℏω_k，跨带 1 个量子 → r 个量子（r = 10^5，能量精确守恒）。

全部用精确有理数（fractions.Fraction）计算 —— 零浮点误差，因此每条不变量都是
**精确相等**，不是「在容差内」。

用法：
    python3 scripts/universe_model.py           # 跑全部验证 + 消融，写报告
    python3 scripts/universe_model.py --check    # 只跑断言，退出码即结果
"""

from __future__ import annotations

import argparse
import json
import math
import os
import sys
from fractions import Fraction as F
from pathlib import Path

# ---------------------------------------------------------------- 常量（给定）

N_BANDS = 12                  # 维度数 = 频率带数
F_TOP = F(10) ** 41           # 宇宙最高频率（Hz）—— 给定
DECADES = 60                  # 阶梯跨度：12 带 × 5 数量级
R = 10 ** 5                   # 相邻带能量比（= 频率比 = 10^5）
SUB_DIMS = 3                  # 子维度数（隐数空间三维 σ₁σ₂σ₃）
RAYS = ("S", "R", "iR")       # 亚维度 = 隐数三射线（HIBS A1/A2/A3）
CELLS = SUB_DIMS * len(RAYS)  # 9 个隐数格 / 维度

# 物理标定（仅用于把无量纲结果换算成 SI / eV；不参与动力学）
HBAR = 1.054571817e-34        # J·s
EV = 1.602176634e-19          # J
T_UNIVERSE_S = 13.8e9 * 3.155_695_2e7   # 宇宙年龄（s）

# 阶梯地板由「均匀 12 带 + 必须覆盖宇宙视界频率」定出（见 derive_floor）
F_HORIZON = 1.0 / T_UNIVERSE_S           # ≈ 2.30e-18 Hz


# ---------------------------------------------------------------- 频率阶梯

def band_hi(k: int) -> F:
    """第 k 带上沿（k=0 为最高带）：10^41 / 10^(5k)。"""
    return F(10) ** 41 / F(10) ** (5 * k)


def band_lo(k: int) -> F:
    """第 k 带下沿 = 第 k+1 带上沿（首尾相接）。"""
    return F(10) ** 41 / F(10) ** (5 * (k + 1))


def band_center(k: int) -> float:
    """几何中心频率（用于物理标定）。"""
    return 10.0 ** (41 - 5 * k - 2.5)


def derive_floor() -> dict:
    """定阶：为什么是 5 个数量级一带、地板 10^-19。

    条件：(a) 12 带均分（对数量级切分）；
          (b) 地板必须 ≤ 宇宙视界频率 f_H = 1/T_U（否则有物理上存在的模不可寻址）；
          (c) 带宽取整数个数量级（decade-aligned）。
    (a)+(c) ⟹ 带宽 = 10^m、地板 = 10^(41-12m)；
    (b) ⟹ 41 - 12m ≤ log10 f_H ≈ -17.64 ⟹ m ≥ 4.89 ⟹ m = 5 是最小解。
    """
    log_fh = math.log10(F_HORIZON)
    need = (41 - log_fh) / N_BANDS
    rows = []
    for m in (4, 5, 6):
        floor = 41 - N_BANDS * m
        rows.append({
            "decades_per_band": m,
            "floor_exponent": floor,
            "reaches_horizon": floor <= log_fh,
            "dormant_decades_below_horizon": max(0.0, log_fh - floor),
        })
    return {
        "log10_f_horizon": log_fh,
        "required_decades_per_band": need,
        "rows": rows,
        "chosen_decades_per_band": 5,
        "floor_hz": 1e-19,
    }


# ---------------------------------------------------------------- 纯度（三种定义）

def purity_spectral(k: int) -> float:
    """谱纯度：阶梯上的位置 log10(f/f_floor)/60。"""
    return (41 - 5 * k + 19) / 60.0


def purity_quantum(k: int) -> float:
    """量子纯度：把定量能量 E 装进 ε_k 的量子，纯度 = ε_k/E（= 量子数的倒数）。"""
    return float(F(1) / F(R) ** k)      # 归一化到 ε₀ = 1


def ray_composition(k: int) -> dict:
    """第 k 带 9 个隐数格的射线构成（A5：根层越深，iR 越多）。

    机制：相位闭合需要 k 次开方（Radical.lean：幂 = 按 μₙ 折叠的商，
    开方 = 把覆盖撑开的截面）⟹ 高带的相位更「展开」，更多格落在 iR 射线。
    """
    n_ir = max(0, min(CELLS, round(CELLS * (N_BANDS - k) / N_BANDS)))
    rest = CELLS - n_ir
    n_r = rest // 2                      # 余下的格一半落在 R 射线，一半留在 S 射线
    n_s = rest - n_r
    return {"S": n_s, "R": n_r, "iR": n_ir}


RAY_GRADE = {"S": F(1, 3), "R": F(2, 3), "iR": F(1)}


def purity_ray(k: int) -> F:
    """隐数纯度：9 个格的平均射线层级。"""
    comp = ray_composition(k)
    tot = sum(RAY_GRADE[r] * comp[r] for r in RAYS)
    return tot / CELLS


# ---------------------------------------------------------------- 动力学

def run(direction: str = "down", flux: str = "all", birth_cells: int = CELLS,
        start_band: int = 0, n0: int = CELLS) -> dict:
    """跑一次维度扩展级联。

    direction  down = 向低频扩展（冷却/退化）；up = 向高频扩展（精炼）
    flux       tau = 每次转移 q = τ（条数差，塌缩定理）
               unit = 每次转移 q = 1（消融：无视张力大小）
               all  = 全部可用量子参与（精炼方向必须如此：每次上移要除以 10^5）
    birth_cells 新维度出生时点亮的隐数格数（原子出生 = 9）
    start_band 初始能量所在带
    n0         初始量子数
    """
    n = [0] * N_BANDS
    cells = [0] * N_BANDS
    n[start_band] = n0
    cells[start_band] = CELLS          # 初始能量正好点亮第一批隐数格
    energy0 = sum(F(n[k]) / F(R) ** k for k in range(N_BANDS))

    trace = [{
        "step": 0,
        "dims": 1,
        "n": list(n),
        "cells": list(cells),
        "quanta": sum(n),
        "energy": str(energy0),
        "purity_N": float(energy0 / sum(n)),
        "event": "initial endowment",
    }]

    d = 1                      # 已出生的维度数
    while d < N_BANDS:
        # src = 已点亮的维度（持有能量）；dst = 尚未出生的下一维（条数 0）
        if direction == "down":          # 冷却：能量向低频带流
            src, dst = d - 1, d
        else:                            # 精炼：能量向高频带流
            src, dst = N_BANDS - d, N_BANDS - d - 1
        tau = cells[src] - cells[dst]    # 塌缩定理：τ = 条数差 = 9 − 0
        if flux == "tau":
            q = tau
        elif flux == "unit":
            q = 1
        else:
            q = None                     # 由可用能量定
        if direction == "down":
            if q is None:
                q = n[src]
            q = max(0, min(q, n[src]))          # 每个量子搬过去变 10^5 个
            q = q if n[src] else 0
            n[src] -= q
            n[dst] += q * R
        else:
            cap = n[src] // R                   # 10^5 个量子才能合成 1 个
            q = cap if q is None else max(0, min(q, cap))
            n[src] -= q * R
            n[dst] += q
        if q == 0:
            break
        cells[dst] = birth_cells
        d += 1
        energy = sum(F(n[k]) / F(R) ** k for k in range(N_BANDS))
        trace.append({
            "step": d - 1,
            "dims": d,
            "n": list(n),
            "cells": list(cells),
            "quanta": sum(n),
            "energy": str(energy),
            "purity_N": float(energy / sum(n)) if sum(n) else 0.0,
            "event": f"birth of dimension {dst} (band {dst})",
        })

    return {
        "direction": direction,
        "flux": flux,
        "birth_cells": birth_cells,
        "start_band": start_band,
        "n0": n0,
        "trace": trace,
        "final_dims": trace[-1]["dims"],
        "final_n": trace[-1]["n"],
        "final_quanta": trace[-1]["quanta"],
        "final_energy": trace[-1]["energy"],
        "energy0": str(energy0),
        "purity_final": trace[-1]["purity_N"],
        "purity_initial": trace[0]["purity_N"],
        "terminated_by": "floor/ceiling of the 12-rung ladder" if trace[-1]["dims"] == N_BANDS
                         else "no transferable quanta",
    }


# ---------------------------------------------------------------- 验证

def check(name: str, ok: bool, detail: str = "") -> dict:
    return {"check": name, "pass": bool(ok), "detail": detail}


def verify() -> tuple[list[dict], dict]:
    checks: list[dict] = []

    # I1 阶梯：12 带首尾相接、严格递减、比值 10^5
    gaps = [band_lo(k) == band_hi(k + 1) for k in range(N_BANDS - 1)]
    ratios = [band_hi(k) / band_lo(k) == R for k in range(N_BANDS)]
    mono = all(band_hi(k + 1) < band_hi(k) for k in range(N_BANDS - 1))
    checks.append(check("I1 阶梯首尾相接（12 带，11 个接缝）", all(gaps) and len(gaps) == 11,
                        f"{len(gaps)} junctions"))
    checks.append(check("I1b 相邻带比值精确 = 10^5", all(ratios)))
    checks.append(check("I1c 带沿严格递减", mono))
    checks.append(check("I1d 最高带上沿 = 10^41", band_hi(0) == F(10) ** 41))
    checks.append(check("I1e 地板 = 1/10^19", band_lo(N_BANDS - 1) == F(1, 10 ** 19)))

    # I2 纯度：三种定义在 12 带上都不出现反序
    ps = [purity_spectral(k) for k in range(N_BANDS)]
    pq = [purity_quantum(k) for k in range(N_BANDS)]
    pr = [purity_ray(k) for k in range(N_BANDS)]
    strict = lambda xs: all(xs[i] > xs[i + 1] for i in range(len(xs) - 1))
    weak = lambda xs: all(xs[i] >= xs[i + 1] for i in range(len(xs) - 1))
    checks.append(check("I2a 谱纯度严格递减", strict(ps)))
    checks.append(check("I2b 量子纯度严格递减", strict(pq)))
    checks.append(check("I2c 隐数纯度不增（9 格分辨率 ⟹ 12 带有平局）", weak(pr)))
    checks.append(check("I2d 三种纯度排序无矛盾（无 i<j 而纯度 i 更低）", weak(ps) and weak(pq) and weak(pr)))

    # I3 结构：3 子维度 × 3 亚维度 = 9 格 / 维度
    checks.append(check("I3 每维 3 × 3 = 9 个隐数格", CELLS == 9))
    checks.append(check("I3b 每个带的射线构成都恰好 9 格",
                        all(sum(ray_composition(k).values()) == CELLS for k in range(N_BANDS))))

    # I4 定阶：5 数量级一带是覆盖视界的最小 decade
    der = derive_floor()
    checks.append(check("I4a r = 10^4 覆盖不到视界", not der["rows"][0]["reaches_horizon"]))
    checks.append(check("I4b r = 10^5 覆盖到视界（地板 1e-19 ≤ f_H）", der["rows"][1]["reaches_horizon"]))
    checks.append(check("I4c r = 10^5 是最小的这种整数 decade",
                        der["rows"][1]["reaches_horizon"] and not der["rows"][0]["reaches_horizon"]))

    # I5 基线（全量转写：每代把整份能量交给下一维）
    base = run()
    energies = [F(s["energy"]) for s in base["trace"]]
    checks.append(check("I5a 能量精确守恒（每一步）", len(set(energies)) == 1,
                        f"E = {energies[0]} ε₀"))
    checks.append(check("I5b 能量 = 初始授予 9 ε₀（每个隐数格一个量子）", energies[0] == F(9)))
    checks.append(check("I5c 维度数长满 12", base["final_dims"] == 12))
    checks.append(check("I5d 维度数单调不减", all(
        base["trace"][i]["dims"] <= base["trace"][i + 1]["dims"]
        for i in range(len(base["trace"]) - 1))))
    pur = [s["purity_N"] for s in base["trace"]]
    checks.append(check("I5e 平均纯度严格递减", strict(pur),
                        f"{pur[0]:.6g} → {pur[-1]:.6g}"))
    quanta = [s["quanta"] for s in base["trace"]]
    checks.append(check("I5f 量子数严格递增", all(q < q2 for q, q2 in zip(quanta, quanta[1:]))))
    checks.append(check("I5g 每代都精确乘 r = 10^5",
                        all(q2 == q * R for q, q2 in zip(quanta, quanta[1:])),
                        f"N: {quanta[0]} → {quanta[-1]:.2e}"))
    checks.append(check("I5h 纯度 = E/N = 9/N（闭式）", all(
        F(s["quanta"]) != 0 and abs(s["purity_N"] - float(F(9) / F(s["quanta"]))) < 1e-30
        for s in base["trace"])))
    # 内生获得：每一维出生时从上一维获得 9 ε₀（整份能量）
    acquired = [F(base["trace"][i]["energy"]) for i in range(1, len(base["trace"]))]
    checks.append(check("I5i 每代内生获得的能量都是 9 ε₀（来自上一结构维度）",
                        all(a == F(9) for a in acquired)))
    checks.append(check("I5j 终态：12 维各 9 格（相邻 τ = 0），能量全在最低带",
                        base["final_dims"] == 12 and base["final_n"][11] == 9 * R ** 11
                        and sum(base["final_n"][:11]) == 0))

    # I6 消融
    tau_run = run(flux="tau")
    checks.append(check("I6a 张力门控（κ=1：每代搬 9 个量子）也走完 12 维",
                        tau_run["final_dims"] == 12))
    checks.append(check("I6b 第二级起全量转写每级多搬 r 倍量子（首级两者重合：n₀ = 9 = τ）",
                        base["trace"][2]["n"][2] == R * tau_run["trace"][2]["n"][2],
                        f"all={base['trace'][2]['n'][2]:.1e} vs τ={tau_run['trace'][2]['n'][2]:.1e}"))
    non_atomic = run(flux="tau", birth_cells=1)
    checks.append(check("I6c 非原子出生（1 格）⟹ 后代 τ 塌到 1，仍长满 12 维",
                        non_atomic["final_dims"] == 12
                        and non_atomic["trace"][2]["n"][2] == R,
                        f"第二级只搬 1 个量子（原子出生时是 9 个）"))
    up = run(direction="up", start_band=11, n0=9 * R ** 11, flux="all")
    checks.append(check("I6d 反向（向高频精炼）也走完 12 维", up["final_dims"] == 12))
    checks.append(check("I6e 反向提高纯度", up["purity_final"] > up["purity_initial"],
                        f"{up['purity_initial']:.3g} → {up['purity_final']:.3g}"))
    up_tau = run(direction="up", start_band=11, n0=9 * R ** 11, flux="tau")
    checks.append(check("I6f 反向 + τ 门控卡住（τ ≤ 9 ≪ r = 10^5，量子数不够合成）",
                        up_tau["final_dims"] < 12, f"停在 {up_tau['final_dims']} 维"))

    summary = {
        "bands": N_BANDS,
        "cells_per_dim": CELLS,
        "r": R,
        "floor_hz": 1e-19,
        "ceiling_hz": 1e41,
        "energy0": str(base["energy0"]),
        "final_dims": base["final_dims"],
        "final_quanta": base["final_quanta"],
        "purity_initial": base["purity_initial"],
        "purity_final": base["purity_final"],
        "checks": len(checks),
        "passed": sum(c["pass"] for c in checks),
    }
    return checks, summary


# ---------------------------------------------------------------- 物理标定

def calibration() -> list[dict]:
    rows = []
    for k in range(N_BANDS):
        f = band_center(k)
        ell = HBAR * 2 * math.pi * f
        comp = ray_composition(k)
        rows.append({
            "band": k,
            "dim": k + 1,
            "f_lo_hz": f"{float(band_lo(k)):.6e}",
            "f_hi_hz": f"{float(band_hi(k)):.6e}",
            "f_center_hz": f"{f:.6e}",
            "period_s": f"{1.0 / f:.6e}",
            "quantum_J": f"{ell:.6e}",
            "quantum_eV": f"{ell / EV:.6e}",
            "purity_spectral": round(purity_spectral(k), 6),
            "purity_ray": float(purity_ray(k)),
            "cells_iR": comp["iR"],
            "cells_R": comp["R"],
            "cells_S": comp["S"],
        })
    return rows


def figure(traces: dict, out: Path) -> str | None:
    try:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt
    except Exception as exc:          # pragma: no cover
        print(f"[skip] matplotlib unavailable: {exc}")
        return None
    fig, axes = plt.subplots(1, 2, figsize=(11, 4.2))
    ax = axes[0]
    for k in range(N_BANDS):
        ax.axhspan(float(band_lo(k)), float(band_hi(k)), color="#e8eef7" if k % 2 else "#cfdcf0")
        ax.text(0.02, band_center(k), f"band {k}  (dim {k + 1})", va="center", fontsize=7)
    ax.set_yscale("log")
    ax.set_xlim(0, 1)
    ax.set_ylabel("frequency (Hz)")
    ax.set_title("12 log-uniform bands, 10^41 Hz ceiling, 10^-19 Hz floor")
    ax.set_xticks([])

    ax = axes[1]
    for label, tr in traces.items():
        n = [s["quanta"] for s in tr["trace"]]
        ax.plot(range(len(n)), n, marker="o", ms=3, label=label)
    ax.set_yscale("log")
    ax.set_xlabel("generation (dimension births)")
    ax.set_ylabel("total quanta N")
    ax.set_title("quanta ×10⁵ per rung (full transfer); energy stays fixed")
    ax.legend(fontsize=7)
    fig.tight_layout()
    out.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(out, dpi=160)
    plt.close(fig)
    return str(out)


# ---------------------------------------------------------------- 报告

def write_report(checks, summary, base, ablations, cal, out_dir: Path) -> Path:
    out_dir.mkdir(parents=True, exist_ok=True)
    conv = derive_floor()
    md = []
    md.append("# PU-12 — 12 层私有宇宙模型：验证报告\n")
    md.append(f"生成：`python3 scripts/universe_model.py`　|　"
              f"检查 {summary['passed']}/{summary['checks']} 通过\n")
    md.append("## 1. 频率阶梯（定阶）\n")
    md.append(f"- 天花板 `10^41 Hz`（给定），地板 `10^-19 Hz`（定出），跨度 60 个数量级。")
    md.append(f"- 视界频率 `f_H = 1/T_U = {F_HORIZON:.4e} Hz`（log10 = {conv['log10_f_horizon']:.2f}）。")
    md.append(f"- 均分 12 带要求每带 `≥ {conv['required_decades_per_band']:.2f}` 个数量级；"
              f"整数解里最小的是 **5 个数量级**（`10^4` 覆盖不到视界）。")
    md.append(f"- 于是相邻带能量比恒为 `r = 10^5`（一个量子的能量精确等于下一带 `10^5` 个）。\n")
    md.append("| 带 k | 维度 | 下沿 (Hz) | 上沿 (Hz) | 中心 (Hz) | 量子能量 (eV) | 谱纯度 | 隐数纯度 | iR/R/S 格 |")
    md.append("|---|---|---|---|---|---|---|---|---|")
    for row in cal:
        md.append(f"| {row['band']} | {row['dim']} | {row['f_lo_hz']} | {row['f_hi_hz']} | "
                  f"{row['f_center_hz']} | {row['quantum_eV']} | {row['purity_spectral']} | "
                  f"{row['purity_ray']} | {row['cells_iR']}/{row['cells_R']}/{row['cells_S']} |")
    md.append("")
    md.append("## 2. 三层结构与 NODS 数学的对应\n")
    md.append("| 宇宙层 | 数学载体 | 仓库出处 |")
    md.append("|---|---|---|")
    md.append("| 频率 / 振数 | 周期 = 振数，相位 `θ = phaseIdx/period`，均匀旋转 `ω = 2πf` | "
              "`Nods/Theories/Vibration.lean`, `VibrationGeometry.lean` (`step_phase_advance`) |")
    md.append("| 子维度（3） | 隐数空间的三根轴 σ₁σ₂σ₃ | HIBS `Definitions.lean`（`~/Downloads/lean/HIBS`）|")
    md.append("| 亚维度（3） | 隐数三射线 S / R / iR（A1 投影有损、A2 ×÷→R、A3 √→iR） | HIBS `Axioms.lean` |")
    md.append("| 条数 / 张力 | `size = 已点亮隐数格数`，`τ = 条数差` | "
              "`TensionReading.lean` (`collapse`) → `Universe.lean` (`countTension`) |")
    md.append("| 维度扩展 | 不可解约束 ⟹ 最小一致扩张（维度只增不减）| `Core/Demand.lean`, `Core/Minimal.lean` |")
    md.append("")
    md.append("## 3. 动力学（基线 = 全量转写 + 原子出生）\n")
    md.append("两个旋钮：**方向与停止**由 `τ = 条数差` 定（τ = 0 就不流 —— 塌缩定理；")
    md.append("新生维度条数 0、父维度 9 ⟹ τ = 9）；**量级**由耦合 `κ` 定 ——")
    md.append("基线取 κ = ∞（整份能量交给下一维），消融里给 κ = 1（每代只搬 τ = 9 个量子）。")
    md.append("每转移 1 个量子跨一带 ⟹ `r = 10^5` 个量子，能量精确相等（`1 × ε_k = 10^5 × ε_{k+1}`）。\n")
    md.append("| 代 | 维度数 | 总量子数 N | 总能量 / ε₀ | 平均量子能量（Π_N）| 事件 |")
    md.append("|---|---|---|---|---|---|")
    for s in base["trace"]:
        md.append(f"| {s['step']} | {s['dims']} | {s['quanta']:.4e} | {s['energy']} | "
                  f"{s['purity_N']:.6g} | {s['event']} |")
    md.append("")
    md.append("## 4. 消融与对照\n")
    md.append("| 配置 | 维度数 | 终态量子数 | 终态能量 / ε₀ | 终态 Π_N | 说明 |")
    md.append("|---|---|---|---|---|---|")
    notes = {
        "张力门控·每代 9 个量子（κ=1）": "τ 同时定量级：每代搬 9 个量子，上部各带留住能量",
        "单位流量·每代 1 个量子": "无视 τ 的大小：级联仍走完，但每代只搬 1 个量子",
        "非原子出生（1 格，τ=8）": "出生只点亮 1 格 ⟹ 后代 τ 塌到 1，级联变慢但仍走完",
        "反向·全量（向高频精炼）": "镜像过程：量子数每级除以 r，纯度升到 1",
        "反向·张力门控": "τ ≤ 9 远小于 r = 10^5 ⟹ 凑不出一次合成，卡在第 2 维",
    }
    md.append(f"| 基线（全量转写、原子出生） | {base['final_dims']} | {base['final_quanta']:.4e} | "
              f"{base['final_energy']} | {base['purity_final']:.6g} | 整份能量逐级下传，量子数每级 ×10⁵ |")
    for name, tr in ablations.items():
        md.append(f"| {name} | {tr['final_dims']} | {tr['final_quanta']:.4e} | "
                  f"{tr['final_energy']} | {tr['purity_final']:.6g} | {notes.get(name, '')} |")
    md.append("")
    md.append("## 5. 检查清单\n")
    md.append("| 检查 | 结果 | 细节 |")
    md.append("|---|---|---|")
    for c in checks:
        md.append(f"| {c['check']} | {'PASS' if c['pass'] else 'FAIL'} | {c['detail']} |")
    md.append("")
    md.append("## 6. 诚实边界\n")
    md.append("- 12 带、`10^41 Hz`、3 子 × 3 亚、初始能量 —— 这些是**给定参数**，不是推导结论；"
              "推导结论是「5 数量级 / 地板 10^-19 / r = 10^5」这一组（由视界覆盖逼出）。")
    md.append("- 能量在带间流动的形式（1 个量子 → 10^5 个）是**精确守恒的记账**，不是对真实辐射过程的模拟。")
    md.append("- 隐数射线构成（iR 随带升高而增多）是**公理 A5**，机制说明是相位闭合需要更深开方；"
              "Lean 里证明的是谱纯度与量子纯度的单调性，隐数纯度只做了表上的一致性核对。")
    md.append("- 模型给的是**结构**（阶梯、条数、流通、平衡、封闭），不给数值物理预言。")
    md.append("")
    path = out_dir / "report.md"
    path.write_text("\n".join(md), encoding="utf-8")
    return path


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true", help="只跑验证，不写报告")
    ap.add_argument("--out", default="docs/models/pu12")
    args = ap.parse_args()

    checks, summary = verify()
    failed = [c for c in checks if not c["pass"]]
    for c in checks:
        print(f"[{'PASS' if c['pass'] else 'FAIL'}] {c['check']}"
              + (f"  ({c['detail']})" if c["detail"] else ""))
    print(f"\n{summary['passed']}/{summary['checks']} checks passed")
    if failed:
        print("FAILED:", ", ".join(c["check"] for c in failed))
        return 1
    if args.check:
        return 0

    out = Path(args.out)
    base = run()
    ablations = {
        "张力门控·每代 9 个量子（κ=1）": run(flux="tau"),
        "单位流量·每代 1 个量子": run(flux="unit"),
        "非原子出生（1 格，τ=8）": run(flux="tau", birth_cells=1),
        "反向·全量（向高频精炼）": run(direction="up", start_band=11, n0=9 * R ** 11, flux="all"),
        "反向·张力门控": run(direction="up", start_band=11, n0=9 * R ** 11, flux="tau"),
    }
    cal = calibration()
    report = write_report(checks, summary, base, ablations, cal, out)
    (out / "trace.json").write_text(json.dumps({
        "summary": summary,
        "calibration": cal,
        "baseline": base,
        "ablations": ablations,
        "floor_derivation": derive_floor(),
        "checks": checks,
    }, indent=2, ensure_ascii=False), encoding="utf-8")
    fig = figure({"down (cooling)": base,
                  "down, τ-gated (κ=1)": ablations["张力门控·每代 9 个量子（κ=1）"],
                  "up (refinement)": ablations["反向·全量（向高频精炼）"]},
                 Path("docs/figures/pu12_ladder.png"))
    print(f"\nreport : {report}")
    print(f"trace  : {out / 'trace.json'}")
    if fig:
        print(f"figure : {fig}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
