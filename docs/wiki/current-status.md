---
title: NODS — New Object Discovery System 当前状态
source: session
created: 2026-09-04
last_confirmed: 2026-09-08
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

### 理论层 `Nods/Theories/Radical.lean`（新方向）

「幂 vs 开方」的结构区分：**开方 ≠ 分数次幂**，区分在挠 μₙ——幂是「按 μₙ 折叠」的商（epi），开方是「把覆盖撑开」的截面（mono）。三条完整证明（0 sorry，`lake build Nods.Theories.Radical` 通过）：

| 定理 | 内容 |
|------|------|
| `powMap_ker_eq_nRoots` | 幂映射 `x ↦ xⁿ` 的核 = n 次单位根群 μₙ |
| `powMap_fiber_iff` | `zⁿ = xⁿ ⟺ ∃ζ, ζⁿ=1 ∧ z = x·ζ`（纤维 = 陪集） |
| `powMap_injective_iff_nRoots_trivial` | 幂单射 ⟺ μₙ 平凡（塌缩条件） |

同文件含**计算层 v0**（形式化地"解释一个数"，四条函数族给不同公式）：幂 `5²=25`、开方 `Nat.sqrt 25=5`（ℕ 可算）；`¬∃n:ℕ n²=2`、`¬∃q:ℚ (q:ℝ)²=2`（幂解释不了 2 → 逼出根式对象）；开方解可解公式 `φ=(1+√5)/2` 且机器验证 `φ²=φ+1`；指数/对数 `e^(ln 2)=2`、`e^(ln 3)=3`（超越路径，公式与根式不同）。

**计算层 v1（通用二次根式 solver）**：任意 `x²−bx−c=0`，判别式 ≥0 时根式公式 `(b±√(b²+4c))/2` 机器验证为解（`quadRootPlus_sq`/`quadRootMinus_sq`），多项式分解 `(x−r₊)(x−r₋)`（`quadFactor`，无其他根）；判别式 <0 证无实根（`quad_no_roots`）；可解判据 `quad_solvable_iff`。含精确计算示例 `quadRootPlus 2 3 = 3`、`quadRootMinus 2 3 = −1`（norm_num 真算 √16）。

**计算层 v2（三次 Cardano）**：任意 `x³+px+q=0`，判别式 `(q/2)²+(p/3)³ ≥ 0` 时构造性给出实根。先证实数立方满射 `cube_surj`（IVT，∛ 对所有实数存在），u 取 `u³ = −q/2+s`，v 定义为 `−(p/3)/u`（而非独立开方——否则 u·v 差一个三次单位根，又是挠），证书 `cardano_certificate`/`vcube` 机器验证 `u+v` 确为根。示例 `x³−3x+2=0` 有根。边界：五次及以上一般无根式解（Abel–Ruffini）。

**计算层 v3（任意次开方，三次 → 五次 → … → n 次）**：一条 ∀n 形式化覆盖所有次数——`nthrootR n x := e^{(ln x)/n}`（ℝ₊ 的 n 次开方）。三条定理：`nthrootR_pow`（(⁽ⁿ⁾√x)ⁿ = x）、`pow_inj_on_Rpos`（ℝ₊ 上 pₙ 对任意 n 单射 = 定理 3 无挠塌缩的 ∀n 形式）、`nthrootR_eq_of_pow`（a>0 ∧ aⁿ=x ⟹ a=⁽ⁿ⁾√x，开方是幂的单值逆）。示例同一形式化取 n=5（`(nthrootR 5 32)^5 = 32`、`nthrootR 5 (2^5) = 2`）、3（∛27）、2（√9）、7（a⁷=128 ⟹ a=⁷√128）。含义：**纯开方没有次数上限**——五次死掉的是混合根式塔（Abel–Ruffini），不是根式。

> ✅ 已接主链（`Nods.lean` 顶部 `import Nods.Theories.Radical`，随主构建全绿）；配套示意图 `docs/figures/root_vs_power.png`（src-fig-001，已登记 raw manifest）。

## 论文发表（2026-09-08）

- **aiXiv**: 英文版 `aixiv.260907.000001`（v1.0/v1.1 保留；**v1.2** = 顶刊标准扩写版，id 1461，Under Review）；中文版 `aixiv.260908.000008`（v1.0 保留；**v1.1** = 扩写版，id 1462，Under Review），标题《被逼出的真实结构：如何把幂与开方劈开》，署名 元杰 刘。英文标题 *The radical as a forced structure: how to split powers from radicals*（作者 Yuanjie Liu）。
- **以太坊 EAS 主网存证**（schema #405 —— **2026-09-08 起停用**，以下为历史记录）：
  - EN v1.1: UID `0xd808138983bda69edc418ee6d3dc30a0eb8f634b924a705eda89031d64a7ea68`，CID `QmVgDR916EHoNFb3rg3W4EdDNkmR1hRLDJarJqyhGZcLGj`，sha256 `04d61d07…dd28c`（v1.0: `0x5e52a5…d53e05d`，CID `QmVQDR2MT…ys7Ec`）
  - ZH v1.0: UID `0x042a1ee3a44f8e0aef91627b70db72b68781a515378bf4d4ca00381d686f2faa`，CID `QmRnfwEUo3LE7qpzu5AnAwvmLomdoUNpAvwocnrtzac3Ed`，sha256 `27a3a42f…9016c`
  - 验证: https://easscan.org/attestation/view/0xd808138983bda69edc418ee6d3dc30a0eb8f634b924a705eda89031d64a7ea68 与 https://easscan.org/attestation/view/0x042a1ee3a44f8e0aef91627b70db72b68781a515378bf4d4ca00381d686f2faa

## 构建状态（2026-09-07 · lake build v4.21.0）

> ✅ **`lake build` 全绿（0 警告 0 sorry）。** 6 个核心层 + 4 个实例（N→Z、Z→Q、Q→R、R→C）全部编译通过。
> 修复路线：(1) `LOF` 从弃用的 `LinearOrderedField` 重建成自定义结构
> （`Field` + `LinearOrder` + `IsStrictOrderedRing`）；(2) 三个 `*_gap` 定理统一改为用
> `HasSolution` 的 `hstr`（结构匹配约束）转移等式，删除 `no_commRing_on_nat` /
> `no_field_on_int` 这类**假命题**——可数等势（ℕ≃ℤ、ℤ≃ℚ）可沿双射搬运环/域结构，
> 所以"ℕ/ℤ 上没有某种结构"根本证不出；真正的 gap 在 `hstr` 这条匹配约束上。

## 未支持 / 待做

- **义务 O1**：`real_initiality_obligation`（R 在"完备 Archimedean 有序域 + 嵌入 Q"中的初始性）仍是 `axiom`——需要"唯一有序域同态 R → K"的构造（Dedekind 切割显式搬运，约 80 行分析），v0.2 应替换为 `IsMinimal` 证明。原义务 O2（ℚ 有序域结构唯一）已在本 session 证成定理 `lofLinearOrder_eq_rat`。
- **Radical 计算层 v3 已完成**：任意次开方（∀n，ℝ₊ 单值）已落码（`nthrootR` + 三条 ∀n 定理，见上）。未落码候选：带 x² 项的一般三次（平移化为缺项型）、四次 Ferrari、五次 Abel–Ruffini 断崖的精确形式化（Galois 群可解性）、复根分支（μₙ 全貌，Nat.card μₙ = n）。已接主链（`Nods.lean` import）。
- 自动化约束生成（Automated Constraint Generator）：v0.1 之后阶段，尚无代码。

## 在线/风险

_（构建状态以 `lake build` 输出为准。）_

- 核心层定理的表述依赖构造注释中强调的`simp` 属性（`Framework.id_apply` / `comp_apply`）。
- 本页早先记录的"构建失败"与"R→C 空文件"已过时：本 session 已修通全链并使构建全绿，R→C 已实现（`realToComplex` / `realToComplex_minimal` / `complex_rigid`）。

## 最近风险

- 理论层 `Algebraic.lean` 的技术要点：`α →+* β` 把 `NonAssocSemiring` 实例当作类型参数携带，忘却结构后同态类型必须在定义上仍是同一类型，否则 `Biframed.forgetHom` 连恒等函数都写不出——写新理论/新实例时最容易卡住的地方。
