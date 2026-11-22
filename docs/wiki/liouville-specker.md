---
title: 刘维尔–Specker 组合数 — 把停机判定写进稀疏位置
source: session
created: 2026-11-22
last_confirmed: 2026-11-22
schema_version: 2
audience: internal
stage: draft
confidence: low
entity_type: concept
tags: [liouville, specker, halting, transcendental, computable, nods]
compiled_from: [src-session-2026-11-22]
---

## 一句话

把**刘维尔数的稀疏骨架**与**Specker 序列的停机位**放在互不相交的位置集上，得到一个**既是超越数、又编码停机判定**的实数——这就是用户要的"主动构造超越数的同时把停机判定写进去"。

## 搜索到的依据（2026-11-22）

1. **Specker 序列（E. Specker, 1949）**：有界、递增、可计算的有理数列，上确界不可计算。nLab 例：\(S_n=\sum_{i+j=n}2^{-i}\{i\}_j\)，\(\lim S_n=\sum_i 2^{-i}\{i\}\)，其中 \(\{i\}_j\in\{0,1\}\) 是第 \(i\) 台图灵机在 \(j\) 步内是否停机。HandWiki 例：极限第 \(n\) 位是 4 当且仅当 \(\{n\}(n)\) 停机，否则 3。
2. **Ω 是 Specker 序列的极限**：\(\Omega_n=\sum_{p\text{ halts within }n}2^{-|p|}\) 递增、可计算逼近、极限不可计算（arXiv 2503.18774）。
3. **MathOverflow（"transcendental \\ computable transcendental"）**："one can construct compressible non-definables by modifying digits on a fixed computable sparse set of positions to impose simple structure" —— 在固定的可计算稀疏位置集上改数字以施加结构，是合法构造模式。
4. **刘维尔数**：\(L=\sum_{n\ge1}10^{-n!}=0.1100010\ldots\)，1844 年首个显式构造的超越数；位置 \(n!\) 超指数稀疏。
5. **可计算超越数**：\(e,\pi\)、Champernowne 常数 \(0.1234567891011\ldots\) 都是可计算超越数（Sources: 科普中国 / Wikipedia / Bohrium），但**不可计算数才是编码停机的那一类**（Ω 不可计算，否则停机可判定）。

## 两个组合构造

### (A) 稀疏位置交替（推荐）

\[
x \;=\; \sum_{n\ \text{偶}}10^{-n!}\;+\;\sum_{n\ \text{奇}}10^{-n!}\cdot h_{\,n/2}
\]

- \(h_i\in\{0,1\}\) = 第 \(i\) 台图灵机是否停机（外部输入，不可计算）；
- 偶数 \(n!\) 位 = 1（刘维尔骨架），奇数 \(n!\) 位 = \(h_i\)（停机位）；
- 位置序列仍是 \(n!\)，超指数稀疏 ⟹ 任意精度有理逼近 ⟹ **刘维尔数 ⟹ 超越**；
- 前 \((2N+1)!\) 位 ⟺ 前 \(N\) 台图灵机停机信息 ⟹ **不可计算**；
- 停机位可在有限步发现并置 1 ⟹ **左-c.e.**（Specker 型极限）。

### (B) 简单叠加

\(x=L+y\)，\(L\) 刘维尔数（可计算超越），\(y\) Specker 极限（不可计算）。
若 \(x\) 代数 ⟹ \(x\) 可计算 ⟹ \(y=x-L\) 可计算，矛盾 ⟹ \(x\) **超越且不可计算**。
（注意：两个超越数的和可以是代数数，如 \(\pi+(1-\pi)=1\)，所以必须用上述反证，不能直接断言。）

## 为什么"可计算超越数不能编码停机"（硬约束）

1. 若 \(x\) 可计算，则存在算法输出任意前 \(n\) 位；
2. 若 \(x\) 的前 \(n\) 位还能读出停机信息 ⟹ 停机问题可判定；
3. 与 Turing 1936 矛盾 ⟹ 任何可计算超越数（\(e,\pi,L,C_{10}\)）都不含通用停机信息。

故组合的关键不是"超越数"这个性质，而是**在稀疏位置上叠加不可计算的停机位**——超越性由骨架保证，不可计算性由停机位保证。

## 与哥德尔/NODS 的关系

- 这是对 `godel-boundary-plan.md` P1 的新实例：**超越数是射程边界的标记物**——可计算的那一侧（\(e,\pi,L\)）不含停机；含停机的那一侧（\(\Omega\)、刘维尔–Specker 数）不可计算。
- NODS 定位：`DigitStream`（0/1 流）+ 稀疏位置映射 + 可计算性谓词（外部输入）。组合数不是"发现的新对象"，而是**把两个已知机制放到不冲突的位置上**的结构定理。
- 诚实边界：图灵机枚举与停机不可判定性不形式化；代码只证结构层面的组合定理。

## 判定标准（编码层，用户口径：说人话版）

不构造完整超越数（不逐位写出 π），只给**一个入口、两个判定**：

> `DecideStandard(P, d, i)` → `(超越性判定, 停机判定)`
> - 第一分量：`d` 的骨架位是否恒为 1（刘维尔型稀疏模式）→ 判超越；
> - 第二分量：`d` 在第 `i` 个奇数位的值 → 判第 `i` 台机器停机否。

**可靠性**：作用在组合流上，`DecideStandard(P, combine P h, i) = (true, h i)`——两个判定同时判对。这就是"同时判定"的机器版本，**不要求程序能跑，只要求编码层成立**。

## Lean 骨架（`Nods/Theories/LiouvilleSpecker.lean`，已接主链）

| 定理 | 内容 | 公理依赖 |
|---|---|---|
| `extract_combine` | `extract P (combine P h) = h`——骨架位与停机位不撞车，抽取可精确还原 | 标准三项 |
| `skeleton_criterion` | 骨架位 `combine P h (pos 2j)` 恒为 1，与 `h` 无关 | 标准三项 |
| **`decideStandard_sound`** | **`DecideStandard P (combine P h) i = (true, h i)`——判定标准可靠性，两个判定同时成立** | **标准三项，无外部假设、无 sorry** |
| `combine_incomputable` | 停机位不可计算 ⟹ 组合流不可计算（逆否：可计算性对抽取封闭） | 标准三项 **+ 外部假设 `NODS.extract_computable`** |

**诚实记账**：`extract_computable`（可计算性对抽取封闭）是显式 `axiom`，留成外部输入；只有 `combine_incomputable` 依赖它。**判定标准本身（`decideStandard_sound`）不依赖它**——判定标准证的是"读出的 = 真实停机位"，这是纯结构事实。

`lake build Nods` 全绿（9073 jobs）。

## 状态台账

| 项 | 状态 |
|---|---|
| 搜索证据 | ✅ 已记录（Specker/nLab、Ω、MO、刘维尔、可计算超越数） |
| 组合构造 (A)(B) | 手工论证 |
| Lean 骨架 | ✅ 已实现（结构定理 + 显式外部假设） |
| 哥德尔定理改动 | 未发生（延续 `dead` 裁决） |
