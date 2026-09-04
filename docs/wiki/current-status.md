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
| R → C | `RealToComplex.lean` | `j² = -1` | ✅ 已实现 |

### 理论层 `Nods/Theories/Algebraic.lean`

`CS ⊇ CR ⊇ FL ⊇ LOF`（CommSemiring → CommRing → Field → 有序域 `LOF`）。

> 注：mathlib 已弃用捆绑类 `LinearOrderedField`，故 `LOF` 改为自定义结构
> （`Field` + `LinearOrder` + `IsStrictOrderedRing` 三字段），见 `Nods/Theories/Algebraic.lean`。

## 构建状态（2026-09-04 · lake build v4.21.0）

> ✅ **`lake build` 全绿。** 6 个核心层 + 4 个实例（N→Z、Z→Q、Q→R、R→C）全部编译通过。
> 修复路线：(1) `LOF` 从弃用的 `LinearOrderedField` 重建成自定义结构
> （`Field` + `LinearOrder` + `IsStrictOrderedRing`）；(2) 三个 `*_gap` 定理统一改为用
> `HasSolution` 的 `hstr`（结构匹配约束）转移等式，删除 `no_commRing_on_nat` /
> `no_field_on_int` 这类**假命题**——可数等势（ℕ≃ℤ、ℤ≃ℚ）可沿双射搬运环/域结构，
> 所以"ℕ/ℤ 上没有某种结构"根本证不出；真正的 gap 在 `hstr` 这条匹配约束上。

## 未支持 / 待做

- **义务 O1**：`real_initiality_obligation`（R 在"完备 Archimedean 有序域 + 嵌入 Q"中的初始性）仍是 `axiom`——需要"唯一有序域同态 R → K"的构造（Dedekind 切割显式搬运，约 80 行分析），v0.2 应替换为 `IsMinimal` 证明。原义务 O2（ℚ 有序域结构唯一）已在本 session 证成定理 `lofLinearOrder_eq_rat`。
- 自动化约束生成（Automated Constraint Generator）：v0.1 之后阶段，尚无代码。

## 在线/风险

_（构建状态以 `lake build` 输出为准。）_

- 核心层定理的表述依赖构造注释中强调的`simp` 属性（`Framework.id_apply` / `comp_apply`）。
- 本页早先记录的"构建失败"与"R→C 空文件"已过时：本 session 已修通全链并使构建全绿，R→C 已实现（`realToComplex` / `realToComplex_minimal` / `complex_rigid`）。

## 最近风险

- 理论层 `Algebraic.lean` 的技术要点：`α →+* β` 把 `NonAssocSemiring` 实例当作类型参数携带，忘却结构后同态类型必须在定义上仍是同一类型，否则 `Biframed.forgetHom` 连恒等函数都写不出——写新理论/新实例时最容易卡住的地方。
