---
title: 双增长率判定准则 — 用增长速率判停机
source: session
created: 2026-11-22
last_confirmed: 2026-11-22
schema_version: 2
audience: internal
stage: draft
confidence: low
entity_type: concept
tags: [growth, halting, specker, busy-beaver, criterion, nods]
compiled_from: [src-session-2026-11-22]
---

## 一句话

用户方案：构造两种不同速率增长的判定准则，在超越数内构造哥德尔式判定命题（把词翻译成命题），再通过增长判定停机。**在编码层可完成**——mathlib 的 `evaln` 提供了现成机制。

## 搜索依据（2026-11-22）

- **Specker 序列的收敛模数（增长率）编码停机**：文献原话 "the failure is one of predictability rather than speed: the terms approach the limit, but no algorithm can certify how close the sequence currently is"。知道模数即可判停机；模数不可计算。
- **Busy Beaver \(BB(n)\)**：Radó 定理——\(BB\) 不可计算且最终支配所有可计算函数；知道 \(BB(n)\) 就能判 n 状态机器停不停（跑 \(BB(n)\) 步还没停 = 永不停），证明是从停机问题归约。

## 两种增长率的对位

| 增长 | 对应物 | 可计算 | 角色 |
|---|---|---|---|
| 慢增长率 | `SlowRate := ℕ → ℕ`，实例 `slowRate c = 2^(c+1)`；`evaln k` 的步数界 k | 是 | 超越数骨架 / 可预测 |
| 快增长率 | `IsHaltingModulus rate`：每台停机机器在 `rate c` 步内有 `evaln` 结果 | **否**（否则停机可判定） | 停机位 / BB 型 |

## 哥德尔翻译 + 增长判定（编码层）

- **翻译词 → 命题**：`Denumerable.ofNat Code c` 把编号 c 翻译成部分递归程序（Gödel numbering 的现成实现）。
- **增长判定准则**：`growthCriterion rate c := (evaln (rate c) (ofNat Code c) 0).isSome`——用增长率作步数界跑有界求值，出结果 = 判停机。

## Lean 定理（`Nods/Theories/GrowthCriterion.lean`，已接主链）

| 定理 | 内容 | 公理 |
|---|---|---|
| `growthCriterion_halts_of_true` | 准则判 true ⟹ 真停机（用 `evaln_sound`） | 标准三项，无 sorry |
| `growthCriterion_true_of_halts` | rate 是模数 + 真停机 ⟹ 准则判 true（用 `evaln_complete` 方向的模数定义） | 标准三项，无 sorry |
| **`growthCriterion_correct`** | **rate 是停机模数 ⟹ 准则精确判定停机（双向）** | **标准三项，无外部假设、无 sorry** |

`lake build Nods` 全绿（9074 jobs）。

## 诚实边界

- **没有构造停机模数**：`rate` 是外部输入；`IsHaltingModulus` 定义成"存在界"而非函数，不假装能算。
- **不存在可计算的停机模数**：mathlib `ComputablePred.halting_problem` 的推论——若 rate 可计算且是模数，则由 `growthCriterion_correct` 可计算地判定停机，矛盾。本文件以注释注明，不写带 sorry 的假定理。
- **未接到超越数骨架**：本文件只做"增长率 → 停机判定"这一半；与 `liouville-specker.md` 的组合（骨架位 + 停机位）接口是下一步。

## 状态台账

| 项 | 状态 |
|---|---|
| 搜索证据 | ✅ Specker 模数 / BB |
| 双增长率对位 | ✅ 手工 |
| 增长判定准则 + 可靠性 | ✅ Lean 已证，0 sorry |
| 接到超越数骨架 | 待做 |
| 可计算停机模数 | 外部事实：不存在（mathlib halting_problem） |
