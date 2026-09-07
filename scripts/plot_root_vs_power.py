#!/usr/bin/env python3
"""
root_vs_power.py — 幂 vs 开方 的示意图：为什么"挠 μₙ"必然出现

左图：幂 p₄ : z ↦ z⁴ 是"折叠"——4 个不同的点被压成同一个像。
      所以逆过来（开方）一个值有 4 个候选 → 开方不可能是单值函数。
右图：这 4 个候选不是孤立的，它们排成一个正方形 = μ₄（4 次单位根群）。
      候选之间只差一个 μ₄ 因子（×i 旋转 90°）——这就是"挠"。
      若 μ₄ = {1}（如 ℝ₊ 无挠）：折叠不存在，开方 = 幂的逆，回到旧图景。

输出：docs/figures/root_vs_power.png
"""
import math
import os

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Circle

# 中文字体（macOS 常见 CJK 字体）
plt.rcParams["font.sans-serif"] = [
    "PingFang HK", "PingFang SC", "Heiti TC", "Arial Unicode MS", "Hiragino Sans GB"]
plt.rcParams["axes.unicode_minus"] = False

OUT = os.path.join(os.path.dirname(__file__), "..", "docs", "figures", "root_vs_power.png")

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

names = ["x₀", "i·x₀", "−x₀", "−i·x₀"]

fig, (axL, axR) = plt.subplots(1, 2, figsize=(13.2, 6.0))

# ============ 左图：幂 = 折叠 ============
axL.set_title("幂 $p_4: z \\mapsto z^4$ —— 折叠：4 个点 → 1 个点", fontsize=13, pad=10)
axL.axhline(0, color="0.8", lw=0.7); axL.axvline(0, color="0.8", lw=0.7)
# 纤维所在的圆（半径 |x₀|）与目标所在圆（半径 |x₀|⁴），淡化显示
c1 = Circle((0, 0), r0, fill=False, ls=":", color="0.55", lw=1.0)
c2 = Circle((0, 0), tgt_r, fill=False, ls=":", color="0.75", lw=0.8)
axL.add_patch(c1); axL.add_patch(c2)
# 四个候选（蓝色）折叠进同一个像（红色）
for (px, py), nm in zip(verts, names):
    axL.plot(px, py, "o", ms=9, color="#1f77b4", zorder=5)
    axL.annotate(nm, (px, py), textcoords="offset points", xytext=(8, 6),
                 fontsize=12, color="#1f77b4")
    axL.annotate("", xy=TGT, xytext=(px, py),
                 arrowprops=dict(arrowstyle="-|>", color="0.55", lw=1.1,
                                 connectionstyle="arc3,rad=0.15"))
axL.plot(*TGT, "*", ms=26, color="#d62728", zorder=6)
axL.annotate("$x_0^4 = p_4(x_0)$\n（唯一的像）", TGT, textcoords="offset points",
             xytext=(14, -6), fontsize=13, color="#d62728")
axL.set_xlim(-3.5, 3.6); axL.set_ylim(-3.4, 3.4)
axL.set_aspect("equal")
axL.text(0, -3.15,
         "4 个不同原像 → 同一个像 $\\Rightarrow$ $p_4$ 不单射 $\\Rightarrow$ 逆（开方）有 4 个候选",
         ha="center", fontsize=12)

# ============ 右图：μ₄ = 核（候选之间的关系） ============
axR.set_title("$\\mu_4$：$z^4=1$ 的解 = 正方形 —— 候选之间只差一个 $\\mu_4$ 因子",
              fontsize=13, pad=10)
axR.axhline(0, color="0.8", lw=0.7); axR.axvline(0, color="0.8", lw=0.7)
unit = Circle((0, 0), 1, fill=False, color="0.45", lw=1.2)
axR.add_patch(unit)
pts = [(1, 0), (0, 1), (-1, 0), (0, -1)]
lab = ["1", "i", "−1", "−i"]
# 正方形四条边
sqx = [p[0] for p in pts] + [1]
sqy = [p[1] for p in pts] + [0]
axR.plot(sqx, sqy, color="#d62728", lw=1.4, zorder=3)
for (px, py), nm in zip(pts, lab):
    axR.plot(px, py, "o", ms=10, color="#d62728", zorder=5)
    ox = 10 if px >= 0 else -16
    axR.annotate(nm, (px, py), textcoords="offset points", xytext=(ox, 2),
                 fontsize=14, color="#d62728", fontweight="bold")
# ×i 的循环作用：1 → i → −1 → −i → 1
for k in range(n):
    (ax_, ay_) = pts[k]; (bx_, by_) = pts[(k + 1) % n]
    axR.annotate("", xy=(bx_, by_), xytext=(ax_, ay_),
                 arrowprops=dict(arrowstyle="-|>", color="0.35", lw=1.3,
                                 connectionstyle="arc3,rad=0.28"))
    mx, my = (ax_ + bx_) / 2, (ay_ + by_) / 2
    axR.annotate("×i" if k == 0 else "×i", (mx, my),
                 textcoords="offset points", xytext=(8, 12), fontsize=12,
                 color="0.2")
axR.set_xlim(-1.9, 1.9); axR.set_ylim(-1.9, 1.9)
axR.set_aspect("equal")
axR.text(0, -1.68, "$\\mu_4$ = 循环群（4 阶）：乘法 ×i 把候选转成候选\n"
                  "（同一纤维里任意两点恰差一个 $\\mu_4$ 元素 = torsor）",
         ha="center", fontsize=12)

fig.suptitle("为什么「开方 ≠ 分数次幂」必然带出挠 $\\mu_n$（这里是 $\\mu_4$）",
             fontsize=15, y=1.00)
fig.text(0.5, -0.02,
         "旧图景（$\\mathbb{R}_{+}$ 无挠）：纤维只有 1 点，开方 = 幂的逆，$x^{1/n}$ = 分数次幂成立。  "
         "有 $\\mu_n \\neq \\{1\\}$ 时：幂是 n 对 1 的折叠，开方 = 在 $x\\cdot\\mu_n$ 里选一个分支。",
         ha="center", fontsize=11.5, color="#555555")

os.makedirs(os.path.dirname(OUT), exist_ok=True)
fig.tight_layout(rect=(0, 0.02, 1, 0.97))
fig.savefig(OUT, dpi=160, bbox_inches="tight")
print("saved:", os.path.abspath(OUT))
