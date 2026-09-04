---
title: NODS — New Object Discovery System 项目概览
source: session
created: 2026-09-04
last_confirmed: 2026-09-04
schema_version: 2
audience: internal
stage: current
confidence: high
entity_type: meta
tags: [overview, nods]
compiled_from: [src-design-001, src-skill-001]
---

## 一句话定义

**NODS (New Object Discovery System)** 是一个用 **Lean 4 + mathlib** 形式化的"新数学对象发现系统"：它不猜符号，而是形式化地描述

> 发现新对象 = 发现当前结构中的不可满足约束 + 寻找最小一致扩张。

## 核心洞察

整个形式化最关键的一个判断，在 `Nods/Core/Framework.lean` 顶部说得很清楚：

> **"最小扩张"不是绝对概念。** 它只有相对于 (a) 一个背景理论 T'（扩张必须住在哪个范畴里）、(b) 一条从当前理论 T 到 T' 的忘却（refinement），才有意义。否则"最小"没有定义——你既可能取一个平凡扩张，也可能取一个混沌扩张。

由此区分出**两种迫使新对象出现的机制**：

- **Refinement（理论强化）**——换一个更强的理论（N→Z、Z→Q、Q→R）
- **Extra / Axiom（添常元）**——在同一理论里添新常元并加公理（R→C）

两者在 `Demand` 结构里统一。

另一个重要发现（`Demand.lean`）：**Axiom 不要求沿同态前向保持**。要求"前向保持"等价于要求该性质是语言里的等式公理——`j*j = -1` 属于这一类（所以 R→C 有真正的初始性），而 Dedekind 完备、Archimedean 不属于（所以 Q→R 没有初始性，R 只是"无真子完备扩张"意义下的极小）。因此 v0.1 把两类极小性分开：`IsMinimal`（初始性）与 `IsCutGenerated`（切割生成性）。

## 层次结构（编译产物）

- `Nods/Theories/Algebraic.lean` — 理论阶梯 `CS ⊇ CR ⊇ FL ⊇ LOF`
  （CommSemiring → CommRing → Field → LinearOrderedField）
- `Nods/Core/*.lean` — 6 个核心层，见 [current-status.md](./current-status.md)
- `Nods/Instances/*.lean` — 数系扩张实例 N→Z、Z→Q、Q→R、（R→C 待做）

## 交付边界

- 目标：重演经典扩张 N→Z→Q→R→C 并**解释"为什么每个对象必须出现"**，然后扩展到未知结构（Automated Constraint Generator 阶段）。
- 不在 v0.1 范围：不假装实现"困难函数"（`solve_in_structure` / `synthesize_new_object` / `minimality` / `consistent`），它们被诚实留成证明义务（输入）；引擎负责判定分支、唯一性、评分闸门、及"新世界确实更强"这些可证定理。
- 关键原则（`Score.lean`）：`Novelty × Consistency × Generativity × Compression` 乘积用作**闸门**——任何一项为 0 总分归 0，防止"新符号污染"。
