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

对合只是「周期 2 的振动」这一个实例，**不是推导的起点**。

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
| 塌缩 | `vibration_collapse`：满足公理 ⇒ 振数差 | 🟢 0 sorry |
| 载体无关 | `Dynamics` 的 X 任意 | 🟢 结构签名 + 三实例 |
| 与已有体系 | 复用 `AtomicReading` + `collapse_four`，只加 1 条新公理 | 🟢 |
| 诚实边界 | 周期需要载体有限（无限载体需显式周期假设） | ⚠️ 标注 |

## 下一步

1. **振数 + 相位 = 完整坐标**：现在是「按周期分桶」，相位（轨道内位置）需要
   同轨道内的序 —— 但那是周期之上的额外结构，不应成为本次「从 0 推导」的前提。
2. **无限载体**：无限载体可能存在双向无限轨道；需要额外的「轨道有限」假设才能定义振数。
3. **多振子组合律**：两张面叠起来振数怎么算？`productDynamics` 给的是并；
   「独立振动叠加 = 振数相加还是相乘」取决于并还是积 —— 留给读数层决策。