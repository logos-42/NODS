---
title: 振数坐标系 — 从静态世界推导振动本体
source: session
created: 2026-10-17
last_confirmed: 2026-10-17
schema_version: 2
audience: internal
stage: current
confidence: medium
entity_type: concept
tags: [vibration, coord-system, new-object, tension, nods]
compiled_from: [src-code-vibration-001]
---

## 一句话定义

**振数坐标系（Vibration Coordinates）** 是从系统已有的**静态世界**（TCM 读数 + 张力 + 塌缩）出发，
**从 0 推导出来**的动力学坐标系：振动本体 = 一个**可逆自演化**，振数 = 被有限性逼出的周期，
张力 = 振数差。不是笛卡尔（位置），不是虚数（旋转），而是第三类：**往返 / 周期分解**。

## 为什么：弦理论的不对称（HBS 第 1–2 步）

弦理论把「弦」当载体、「弦的振动」当属性。leo 的滞涩点：**同一振动不依赖载体** ——
sin 函数振动时并没有一根弦；点可以振动、面可以振动（膜）、数可以振动。

不对称在于：标准理论**处处用**振动模式做事（简正坐标、傅里叶展开、弦的谱），
却从不把「振动」本身当作一个可推导的数学对象来公理化 —— 振动是「被使用的」，不是「被定义的」。

**方法纪律（leo 修正）**：不从对合、临界线、Re=1/2 这些**中间结构**出发；
只从系统架构（静态世界）出发，从 0 推导。

## 推导链（从 0 到振动本体）

### 第 0 步：静态世界（已有，不是振动）

```
AtomicReading X  (share / size)  +  AddTension 公理 (T6+T7+T4'+T3b)  +  塌缩 τ = size 差
```

### 第 1 步：动力学公理（唯一一条新公理）

```lean
structure Dynamics (X) where
  step : X ≃ X        -- 可逆自演化 = 时间反演对称
```

**振动的定义就是「一个对象如何随时间变化」，可逆 = 往返不损失信息（不是衰减）。**
载体 X 任意：点、线、面、数 —— 一切皆可振。

### 第 2 步：零张力动力学（定理，不是公理）

```lean
dynamics_tension_free : τ(x, step x) = 0
```

若演化保持条数（size 是轨道不变量），则每一步都与前一刻**张力为零**。
这是 TCM「内容不可见」（`size_only`）的动力学版：**内容在变、张力为零**。
—— 动力学性质自动出现，不需要任何新公理。

### 第 3 步：周期被逼出（定理，不是假设）

```lean
period_exists : 有限载体 ⟹ ∃ p > 0, step^[p] x = x
```

**鸽笼原理**：`x, σx, ..., σ^(card X) x` 共 `card X + 1` 个点落在 `card X` 个位置里，
必有重复 ⟹ （可逆性消去多余步数）⟹ 周期。**振数不是输入的，是被有限性逼出来的。**

### 第 4 步：振数坐标（组装 2+3）

```lean
vibrationReading V : AtomicReading X        -- size = period（振数），share = min（共同周期）
vibration_collapse : τ = period a − period b   -- 塌缩定理：张力 = 振数差
```

## 坐标系规范逐条验证

| 规范 | 内容 | 定理 |
|------|------|------|
| 原点 | 不动点（不振）振数 = 1 | `period_one_fixed` |
| 坐标 | 对象 x 的坐标 = 振数 `period x` | `vibCoord` / `vib_tension_is_coord_diff` |
| 距离/力 | 两个振动体的张力 = 坐标差（或反号） | `vibration_collapse` |
| 可加性 | T6 内建：张力对读数可加、线性 | 继承 `AddTension` |
| 动力学 | `step` 迭代 = 相位演化；不动点 = 不振 = 临界 | `Dynamics.phase_succ` / `fixed_point_balanced` |
| 周期 | 有限载体 ⟹ 每点周期（鸽笼，被逼出） | `period_exists` |

## 动力学：振动自带时间

- **时间 = 轨道脚步数**（`phase k x := step^k x`）
- **可逆 = 时间反演对称**（`step : X ≃ X`，走 a 步再退 a 步回到原位：`cancel_iter`）
- **不动点 = 不振**（`period = 1 ⟹ step x = x`）
- **临界 = 不振集**（不动点处张力为零：`fixed_point_balanced`）
- **周期 = 有限性逼出**（`period_of_repeat`：轨迹重复 ⟹ 周期；`period_exists`：鸽笼）

## 实例

| 载体 | 振动 | 周期 |
|------|------|------|
| 点 `Fin 2` | `0 ↔ 1` 交换 | 2（`point_period_exists`） |
| 线 `Fin 3` | `0 → 1 → 2 → 0` 循环 | 3（`line_period_exists`） |
| 面 `Fin 2 × Fin 3` | 两个方向各自振（`productDynamics`） | ≤ 6（`plane_period_exists`） |
| **数 `ℚ`（无限载体）** | `x ↦ 1 − x` 反转（`numPeriodicDynamics`） | 中心 `1/2` 振数 1，其余 2 |

前三个是有限载体 —— 周期由鸽笼（`period_exists`）**逼出**。**ℚ 是无限载体**：
周期不能靠鸽笼，改为**显式周期**（`period := if 1 − x = x then 1 else 2`）——
这就是「轨道有限假设」：每条轨道恰好 1 或 2 个点。对合只是「周期 2 的振动」
这一个实例，**不是推导的起点**。

**泛化**：`PeriodicDynamics` 不要求 `Fintype` —— `same_orbit_comm` 只需
`step_period` 就能补足轨道对称性（`p = period x`、`q·p ≥ k`），有限/无限载体共用
同一套读数与塌缩。中心 `1/2` 处张力为零（`num_center_balanced`）：不振 = 临界 =
`Re = 1/2` 的形状在振数坐标里的样子。

## 与弦理论的关系（诚实边界）

- **数学层**：振动本体 = 可逆自演化；张力 = 振数差；载体可以是点/线/面/数。
  这支持「振动优先于弦」的直觉：**弦只是众多载体之一，不是必需的**。
- **不声称**：「弦不存在」或「这是弦论的替代」。弦论的频率谱是哈密顿量对角化
  （动力学内容），本公理体系管不到；给的是**一切振动共享的计数骨架**。
- **推导路径的自觉**：没有借对合、临界线、Riemann 的形状 —— 全部从静态世界长出。

## 按 NODS 判定（诚实台账）

| 项 | 判据 | 结果 |
|----|------|------|
| 动力学公理 | `Dynamics`（可逆自演化）—— 唯一新公理 | 1 条 |
| 零张力 | `dynamics_tension_free`：`τ(x, step x) = 0`（定理） | 🟢 |
| 周期被逼出 | `period_exists`：有限 + 可逆 ⟹ 周期（鸽笼，定理） | 🟢 |
| 无限载体 | `numPeriodicDynamics`（ℚ 反转）：显式周期，轨道有限假设 | 🟢 实例 |
| 塌缩 | `vibration_collapse`：满足公理 ⇒ 振数差 | 🟢 0 sorry |
| 载体无关 | `Dynamics` 的 X 任意；`PeriodicDynamics` 不要求 `Fintype` | 🟢 结构签名 + 四实例 |
| 与已有体系 | 复用 `AtomicReading` + `collapse_four`，只加 1 条新公理 | 🟢 |
| 诚实边界 | 有限载体周期靠鸽笼逼出；无限载体需显式周期（轨道有限假设） | ⚠️ 标注 |
| 几何坐标化 | `VibrationGeometry.lean`：极坐标 + 均匀旋转 + 圆距离 + polarDist（已接主链） | 🟢 0 sorry |

## 几何坐标化（离散极坐标层，2026-10-18）

leo 要求「**使得可以几何坐标化**」⟹ 新文件 `Nods/Theories/VibrationGeometry.lean`
（0 sorry 0 warning，已接主链）。出路：`metric_not_nontrivial` 堵住的只是
「张力 = 距离的纯函数（零集 = 对角线）」这一**形态**，**不堵「给坐标配几何」**——
保留张力为力（TCM 塌缩不动），同时把振数坐标变成**真正的极坐标**。

| 几何件 | 定义 | 定理 |
|--------|------|------|
| 角度（相位分数） | `phaseFrac = phaseIdx / period` ∈ ℚ 模 1 | `phaseFrac_nonneg` / `_lt_one`（0 ≤ θ < 1）|
| 原点 | 自链 `PhaseLink_self`（k = 0） | `phaseFrac_self`：θ = 0 |
| 均匀旋转 | step 一步 = 角度推进 1/period | `step_phase_advance`（主定理）|
| 极坐标 | `polarCoord = (period y, phaseFrac)` = （半径, 角度） | —— |
| 可分辨性 | 同窗口内角度相同 ⟹ 同一点 | `phaseFrac_injective` / `polarCoord_injective` |
| 几何化桥 | \|张力\| = \|振数差\| = 径向距离 | `tension_abs_eq_radial_dist`（主定理）|
| 圆距离 | `circleDist = min(\|Δθ\|, 1−\|Δθ\|)` | 自零 / 对称 / 非负 / 分离 |
| 极坐标度量 | `polarDist = \|半径差\| + 圆距离` | 自零 / 对称 / 分离（`polarDist_eq_zero_iff`）|

实例数值：点 **(2, 1/2)**（对合 = 半圈）/ 线 **(3, 1/3)、(3, 2/3)**（正三角形两顶点）/
数中心 **(1, 0)**（周期 1 = 退化圆 = 不振 = 原点）；`line_phase_advance_example`
机器核对 1/3 → 2/3 的均匀推进。

**与 ħ 的连接**：`2π × phaseFrac` = 弧度 —— 相位分数的连续化极限就是
「每弧度角动量」的弧度。仍是非已证的共振点，需 ℝ / U(1) 连续化（v2）。

诚实边界：离散 ℚ 圆（正 N 边形）；连续弧度（ℝ、sin、U(1)）v2；
`polarDist` 三角不等式 v2（需 min 的 ℚ 引理集）。

## 与弦理论的关系（可行性分析，2026-10-18）

- **坐标系**：`metric_not_nontrivial` 堵住的只是「张力 = 距离的纯函数」形态，
  堵不了「给坐标配几何」—— **leo 修正后，几何坐标化已实现**
  （离散极坐标层，见上节）。早期「几何坐标被证堵死」的结论作废。
- **可构建的新空间 = 模空间（mode space）**：独立振子的乘积（`productDynamics`
  是种子），点 = 全振子状态组合，坐标 = 每振子 `(振数, 相位)`，维数 = 独立振子数。
  与弦的模展开 `X = Σ Xₙ e^{2πinσ}` 同构——弦论本来就住在模空间里，
  区别只是这里它是被振出来的，不是前提。
- **弦论推导不出**（三层）：能证「振动优先于弦」（载体任意）；推不出频率谱
  （哈密顿量对角化）、临界维数（量子化一致性）、相互作用、背景度量。
- **深层数学**：连续振动 = `ℝ → U(1)` 同态 = 频率（Pontryagin 对偶）——
  傅里叶分析就是振动的数学；频率谱不在计数里（与 RH 不在计数里同型）。

## 下一步

1. **组合律（候选缺口 ①，最近的逼出路径）**：叠加两个振子，总振数 = 和还是积？
   `productDynamics` 给的是并；若「叠加后仍是单振子且保塌缩」这个约束在同一载体
   上不可表达 ⟹ 逼出叠加运算 = 给模空间装上算术（坐标加法）。
2. **连续频率（候选缺口 ②，真 gap）**：周期现在是 ℕ。什么约束逼出 ℝ 值频率？
   候选：时间平移对称连续化 → U(1) 特征 → 频率。体系里现在没有任何东西逼出连续谱。
3. **相位 → 连续弧度（候选缺口 ③ 部分已实现）**：`phaseFrac`（模 1 的 ℚ 比例）
   已落码（几何坐标化的角度坐标）；剩余的是连续化 `2π·θ ∈ ℝ`（U(1)、sin）——
   **接 ħ = 每弧度角动量**（共振点，非已证）。
4. **无限载体已完成**：`ℚ` 反转（`numPeriodicDynamics`）直接用显式周期
   （轨道有限假设），与有限载体的鸽笼路径共用同一套读数/塌缩 ——
   `Re = 1/2` 作为数振动的不动点已回到视野（`num_center_balanced`），
   但那是实例性质，不是推导起点。