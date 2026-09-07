#!/usr/bin/env python3
"""
root_vs_power.py — 幂 vs 开方 的示意图：为什么"挠 μₙ"必然出现（中英双语版）

左图：幂 p₄ : z ↦ z⁴ 是"折叠"——4 个不同的点被压成同一个像。
      所以逆过来（开方）一个值有 4 个候选 → 开方不可能是单值函数。
右图：这 4 个候选不是孤立的，它们排成一个正方形 = μ₄（4 次单位根群）。
      候选之间只差一个 μ₄ 因子（×i 旋转 90°）——这就是"挠"。
      若 μ₄ = {1}（如 ℝ₊ 无挠）：折叠不存在，开方 = 幂的逆，回到旧图景。

输出：docs/figures/root_vs_power.png （中文版）
      docs/figures/root_vs_power_en.png （英文版）
"""
import math
import os

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Circle

# 中文字体（macOS 常见 CJK 字体）；英文版字体不依赖 CJK
plt.rcParams["font.sans-serif"] = [
    "PingFang HK", "PingFang SC", "Heiti TC", "Arial Unicode MS", "Hiragino Sans GB"]
plt.rcParams["axes.unicode_minus"] = False

T = {
    "zh": {
        "out": "root_vs_power.png",
        "tL": r"幂 $p_4: z \mapsto z^4$ —— 折叠：4 个点 → 1 个点",
        "tgt": r"$x_0^4 = p_4(x_0)$" "\n" r"（唯一的像）",
        "bL": r"4 个不同原像 → 同一个像 $\Rightarrow$ $p_4$ 不单射"
              r" $\Rightarrow$ 逆（开方）有 4 个候选",
        "tR": r"$\mu_4$：$z^4=1$ 的解 = 正方形"
              r" —— 候选之间只差一个 $\mu_4$ 因子",
        "bR": r"$\mu_4$ = 循环群（4 阶）：乘法 ×i 把候选转成候选" "\n"
              r"（同一纤维里任意两点恰差一个 $\mu_4$ 元素 = torsor）",
        "sup": r"为什么「开方 ≠ 分数次幂」必然带出挠 $\mu_n$（这里是 $\mu_4$）",
        "foot": (r"旧图景（$\mathbb{R}_{+}$ 无挠）：纤维只有 1 点，"
                 r"开方 = 幂的逆，$x^{1/n}$ = 分数次幂成立。  "
                 r"有 $\mu_n \neq \{1\}$ 时：幂是 n 对 1 的折叠，"
                 r"开方 = 在 $x\cdot\mu_n$ 里选一个分支。"),
    },
    "en": {
        "out": "root_vs_power_en.png",
        "tL": r"Power $p_4: z \mapsto z^4$ — folding: 4 points → 1 point",
        "tgt": r"$x_0^4 = p_4(x_0)$" "\n" r"(the unique image)",
        "bL": r"4 distinct preimages → one image $\Rightarrow$ $p_4$ not injective"
              r" $\Rightarrow$ inverse (root) has 4 candidates",
        "tR": r"$\mu_4$: solutions of $z^4=1$ form the square"
              r" — candidates differ by a $\mu_4$ factor",
        "bR": r"$\mu_4$ = cyclic group (order 4): ×i cycles through the candidates"
              "\n" r"(any two points of one fiber differ by a $\mu_4$ element = torsor)",
        "sup": r"Why “root ≠ fractional power” forces torsion $\mu_n$ (here $\mu_4$)",
        "foot": (r"Old picture ($\mathbb{R}_{+}$ torsion-free): one point per fiber, "
                 r"root = inverse of the power, $x^{1/n}$ = fractional power.  "
                 r"When $\mu_n \neq \{1\}$: the power is an n-to-1 fold; "
                 r"the root = choosing a branch inside $x\cdot\mu_n$."),
    },
}

FIG_DIR = os.path.join(os.path.dirname(__file__), "..", "docs", "figures")

# ---- 几何设定：n = 4, x₀ = 1.3·e^{0.6i} ----
n = 4
r0, th0 = 1.3, 0.6
X0 = (r0 * math.cos(th0), r0 * math.sin(th0))

def rot(p, k):
    # 乘 i^k：逆时针转 90°k
    a = math.atan2(p[1], p[0]) + k * math.pi / 2
    r = math.hypot(*p)
    return (r * math.cos(a), r * math.sin(a))

verts = [rot(X0, k) for k in range(n)]          # x₀·μ₄：四个候选（一个纤维）
tgt_r, tgt_th = r0 ** n, (n * th0) % (2 * math.pi)
TGT = (tgt_r * math.cos(tgt_th), tgt_r * math.sin(tgt_th))   # x₀⁴

names_zh = ["x₀", "i·x₀", "−x₀", "−i·x₀"]
names_en = [r"$x_0$", r"$i\,x_0$", r"$-x_0$", r"$-i\,x_0$"]


def draw(lang):
    t = T[lang]
    names = names_zh if lang == "zh" else names_en
    fig, (axL, axR) = plt.subplots(1, 2, figsize=(13.2, 6.0))

    # ============ 左图：幂 = 折叠 ============
    axL.set_title(t["tL"], fontsize=13, pad=10)
    axL.axhline(0, color="0.8", lw=0.7); axL.axvline(0, color="0.8", lw=0.7)
    c1 = Circle((0, 0), r0, fill=False, ls=":", color="0.55", lw=1.0)
    c2 = Circle((0, 0), tgt_r, fill=False, ls=":", color="0.75", lw=0.8)
    axL.add_patch(c1); axL.add_patch(c2)
    for (px, py), nm in zip(verts, names):
        axL.plot(px, py, "o", ms=9, color="#1f77b4", zorder=5)
        axL.annotate(nm, (px, py), textcoords="offset points", xytext=(8, 6),
                     fontsize=12, color="#1f77b4")
        axL.annotate("", xy=TGT, xytext=(px, py),
                     arrowprops=dict(arrowstyle="-|>", color="0.55", lw=1.1,
                                     connectionstyle="arc3,rad=0.15"))
    axL.plot(*TGT, "*", ms=26, color="#d62728", zorder=6)
    axL.annotate(t["tgt"], TGT, textcoords="offset points",
                 xytext=(14, -6), fontsize=13, color="#d62728")
    axL.set_xlim(-3.5, 3.6); axL.set_ylim(-3.4, 3.4)
    axL.set_aspect("equal")
    axL.text(0, -3.15, t["bL"], ha="center", fontsize=12)

    # ============ 右图：μ₄ = 核（候选之间的关系） ============
    axR.set_title(t["tR"], fontsize=13, pad=10)
    axR.axhline(0, color="0.8", lw=0.7); axR.axvline(0, color="0.8", lw=0.7)
    unit = Circle((0, 0), 1, fill=False, color="0.45", lw=1.2)
    axR.add_patch(unit)
    pts = [(1, 0), (0, 1), (-1, 0), (0, -1)]
    lab = ["1", "i", "−1", "−i"]
    sqx = [p[0] for p in pts] + [1]
    sqy = [p[1] for p in pts] + [0]
    axR.plot(sqx, sqy, color="#d62728", lw=1.4, zorder=3)
    for (px, py), nm in zip(pts, lab):
        axR.plot(px, py, "o", ms=10, color="#d62728", zorder=5)
        ox = 10 if px >= 0 else -16
        axR.annotate(nm, (px, py), textcoords="offset points", xytext=(ox, 2),
                     fontsize=14, color="#d62728", fontweight="bold")
    for k in range(n):
        (ax_, ay_) = pts[k]; (bx_, by_) = pts[(k + 1) % n]
        axR.annotate("", xy=(bx_, by_), xytext=(ax_, ay_),
                     arrowprops=dict(arrowstyle="-|>", color="0.35", lw=1.3,
                                     connectionstyle="arc3,rad=0.28"))
        mx, my = (ax_ + bx_) / 2, (ay_ + by_) / 2
        axR.annotate("×i", (mx, my), textcoords="offset points",
                     xytext=(8, 12), fontsize=12, color="0.2")
    axR.set_xlim(-1.9, 1.9); axR.set_ylim(-1.9, 1.9)
    axR.set_aspect("equal")
    axR.text(0, -1.68, t["bR"], ha="center", fontsize=12)

    fig.suptitle(t["sup"], fontsize=15, y=1.00)
    fig.text(0.5, -0.02, t["foot"], ha="center", fontsize=11.5, color="#555555")

    out = os.path.join(FIG_DIR, t["out"])
    os.makedirs(FIG_DIR, exist_ok=True)
    fig.tight_layout(rect=(0, 0.02, 1, 0.97))
    fig.savefig(out, dpi=160, bbox_inches="tight")
    plt.close(fig)
    print("saved:", os.path.abspath(out))


if __name__ == "__main__":
    draw("zh")
    draw("en")
