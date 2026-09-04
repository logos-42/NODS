---
title: NODS — New Object Discovery System 当前状态
source: session
created: 2026-09-04
last_confirmed: 2026-09-04
schema_version: 2
audience: internal
stage: current
confidence: medium
entity_type: meta
tags: [status, nods]
compiled_from: [src-code-core-001, src-code-instances-001, src-code-theories-001]
---

## 已形式化（编译产物）

### 核心层 `Nods/Core/`（6 层）

| 层 | 文件 | 职责 | 关键定理/判断 |
|----|------|------|--------------|
| 1 | `Framework.lean` | 理论 · 模型 · 语架 · 理论强化 | `Theory`/`Model`/`Framework`/`Refinement`/`Biframed`; id/comp 结合律与单位元 |
| 2 | `Demand.lean` | 需求 · 扩张 · 扩张同态 | `Demand T T'`: Refinement / Extra / Axiom 三机制统一; 证明 `IsMinimal` 与 `IsCutGenerated` 分离 |
| 3 | `Verdict.lean` | 失败判定 · 失败空间 | 三分判定 `solved` / `dead` / `gap`; 区分"缺对象"与"需求自相矛盾" |
| 4 | `Minimal.lean` | 极小扩张的唯一性 | `IsMinimal.carrierEquiv`（唯一同构）+ `IsMinimal.rigid`（无平凡自同态）——这是"发现对象"而非"编符号"的依据 |
| 5 | `Score.lean` | 生成力评分 · 目标函数 | `generativity`（加权和，用于排序）vs `objective`（乘积，用于闸门）; `objective_eq_zero_of_*` |
| 6 | `Engine.lean` | 发现引擎 | 把四个困难函数诚实地留成**证明义务**，引擎负责周围一切可证结构 |

### 实例层 `Nods/Instances/`

| 扩张 | 文件 | 失败形式 | 状态 |
|------|------|---------|------|
| N → Z | `NatToInt.lean` | 减法闭包失败（`2 - 3` 无解） | ✅ 已实现 |
| Z → Q | `IntToRat.lean` | 除法闭包失败（`2x = 1`） | ✅ 已实现 |
| Q → R | `RatToReal.lean` | 完备性（`Rat.castHom` 需 `CharZero`） | ✅ 已实现 |
| R → C | `RealToComplex.lean` | `j² = -1` | ⚠️ **空文件 — 未实现** |

### 理论层 `Nods/Theories/Algebraic.lean`

`CS ⊇ CR ⊇ FL ⊇ LOF`（CommSemiring → CommRing → Field → LinearOrderedField）。

## 构建状态（2026-09-04 · lake build v4.21.0）

> ⚠️ **当前 `lake build` 失败。** 失败集中在 3 个模块：
> `Nods.Core.Demand`、`Nods.Core.Minimal`、`Nods.Theories.Algebraic`。
> 根因在 `Nods/Theories/Algebraic.lean:87/90/93` 的 `Refinement` 实例：
> `forgetStr := fun {α} s => (s : Field α)` 这类**直接用类型 cast 做忘却**，Lean 找不到对应的自动实例路径，报 `type mismatch`（LOF→Field、FL→CommRing、CR→CommSemiring 均如此）。

这正是 [sources-and-data / project-overview] 里强调的技术要点：`α →+* β` 把 `NonAssocSemiring` 实例当类型参数携带，忘却后同态类型必须仍为同一类型。**修法**大概率不是显式 cast，而是沿 `SemiringLike` 强化路径委托（stronger 委托给 weaker），让 coercion 可由类型类自动合成。

> 其余模块（Framework / Verdict / Score / Engine / NatToInt / IntToRat / RatToReal / Probe）在本次构建中未报错，但**整体仍因上述 3 个模块失败而未通过构建**（lake 需全绿）。

## 未支持 / 待做

- **`RealToComplex.lean` 为空**：R→C 是四项经典扩张中唯一未形式化的。该实例是"添常元"型（Extra + Axiom `j² = -1`），且有真正的初始性，是验证 `IsMinimal`（非 `IsCutGenerated`）路径的最佳测试。
- 自动化约束生成（Automated Constraint Generator）：v0.1 之后阶段，尚无代码。

## 在线/风险

_（构建状态以 `lake build` 输出为准，见下方注记验证。）_

- 核心层定理的表述依赖构造注释中强调的`simp` 属性（`Framework.id_apply` / `comp_apply`）。
- `RealToComplex.lean` 的空白是本项目下一步最值得做的单点。
- 若后续补 R→C，请同步更新本页状态矩阵与 `supersedes` 链（如有旧表述被替代）。

## 最近风险

- 理论层 `Algebraic.lean` 的技术要点：`α →+* β` 把 `NonAssocSemiring` 实例当作类型参数携带，忘却结构后同态类型必须在定义上仍是同一类型，否则 `Biframed.forgetHom` 连恒等函数都写不出——写新理论/新实例时最容易卡住的地方。
