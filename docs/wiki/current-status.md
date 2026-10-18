---
title: NODS — New Object Discovery System 当前状态
source: session
created: 2026-09-04
last_confirmed: 2026-10-18
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

> ⚠️ **2026-10-18：工具链迁移中 → v4.35.0（最新稳定版），废弃 v4.21.0。**
> `lean-toolchain` 已切 `leanprover/lean4:v4.35.0`；本地物化依赖（mathlib 等 9 包）
> 将由 NavierStokesAndEuler 项目（同 rev `56a00585` = "bump to v4.35.0"）的
> 已编译物化替换后重新 `lake build` 验证。**本批构建状态 = 待验证**（迁移完成前
> 以下 v4.21.0 的"全绿"记录不代表 v4.35.0 状态）。

> ✅ **`lake build` 全绿（0 警告 0 sorry）。** 6 个核心层 + 4 个实例（N→Z、Z→Q、Q→R、R→C）全部编译通过。
> 修复路线：(1) `LOF` 从弃用的 `LinearOrderedField` 重建成自定义结构
> （`Field` + `LinearOrder` + `IsStrictOrderedRing`）；(2) 三个 `*_gap` 定理统一改为用
> `HasSolution` 的 `hstr`（结构匹配约束）转移等式，删除 `no_commRing_on_nat` /
> `no_field_on_int` 这类**假命题**——可数等势（ℕ≃ℤ、ℤ≃ℚ）可沿双射搬运环/域结构，
> 所以"ℕ/ℤ 上没有某种结构"根本证不出；真正的 gap 在 `hstr` 这条匹配约束上。

## 未支持 / 待做

- **张力计数法 TCM-0（新对象候选，candidate gap）**：`docs/wiki/tension-counting.md`（draft）。极简公理刻画「数字自身张力」的收敛 / 发散二分力 + 临界流形（T=0），四数域实例化（ℕ 素因子 / ℤ 符号 / ℝ 连分数 / ℂ 临界线）。**诚实结论：`O-TCM-gap`（ℕ）经 `HasSolution` 检查为 `solved` 而非 gap** —— 素因子 radical 张力在现有 ℕ 算术结构同一载体上已一阶可定义，故 ℕ 上是「设计选择 / 记号」而非被迫对象，不得宣称发现。真正可能升级为「发现」的缺口是 **`O-TCM-canon`（ℂ）**：要求张力由 ζ 结构强制、Re=1/2 为唯一最大收敛轨迹；裸 ℂ 域/拓扑不强制此性质。极小性 `IsMinimal`（ℕ 定义不唯一→失败）与闸门均待 `O-TCM-canon` 解决。**已落 Lean**：`Nods/Theories/Tension.lean`（7 条定理，`lake build Nods` 0 sorry 0 warning，已接主链）把上述判定机器化 —— `metric_not_nontrivial` 证「借来的结构（metric/序/整除）承载不了非平凡临界流形」，`radTension_violates_T5` 证「ℕ 实例违反公理 T5」，`crit_manifold_not_unique` 证「两个都合规的实例临界流形不同」⇒ `IsMinimal` 机器证伪。**TCM-1（判别公理）已补齐**：加 T6（计数=剖面可加）/ T7（单位=每素数至多一条）/ T4′（必须反号，把 T4 从「允许」升级为「必须」）+ T5 自零 + T3b 非全，`forced_unique` 机器证出 τ 唯一到取向 `|S∖T| − |T∖S|`，且读回数对正是 `dirTension`；T3a 降为定理（`nontrivialCrit_free`）、T5 证不可省（`T5_needed`）⇒ **τ 从「记号」变为「被迫对象」**（与 R→C 的 `(C,i)/(C,−i)` 同型）。**最小化审计已出**：分工定理 `form_up_to_scale`（形状被逼出，只留整数单位）/ `unit_fixes_scale`（T7 只管定单位）⇒ **T6 与 T7 不能合并**（管形状 vs 管刻度）；T3a 与 T5 的 grade 部分**冗余**；T3b / T4′ / T5-两力 / T6 **各有反模型**证明独立或不可省（`T3b_needed` / `T4'_independent` / `T5_needed` / `additivity_needed`）；T7 可由更自然的「计数界」（`0 ≤ K,L ≤ 总条数`）推出 ⇒ **公理表压到 6 条**。**收尾 + 严密性 + 其它逼出路线（§9）**：权威表已置于 `tension-counting.md` 页首（旧表标注取代）；形状逼出**不需要 T5**（`form_up_to_scale'`）；**核路**（直接把临界流形写进公理）也到同一 τ（`kernel_forces`）；无界时只剩整数刻度自由（`scale_free_without_bound`，`c=2` 反模型）；**刚性成立**（`two_solutions`：解恰两个 = τ / −τ，二者互为「反着读」⇒ `IsMinimal`）；**乘法性/Leibniz 路被否**（`not_leibniz`）。**数字层面为什么成立已写成文档**（`tension-counting.md`「为什么它成立：数字层面的直读」）：三句话（每个数=一捆素数条 / 每条素数只有三种身份 / 力必须有方向故共享出局）+ 一句话公式 `τ(a→b) = |S_a∖S_b| − |S_b∖S_a|` + 算例 `60 与 45` 得 `+1`，配四个对照（`(12,18)=0`、`(2,3)=0`、`(30,7)=+2`，要害是「量的不是像不像，是谁比谁多」），Lean §10 五个例子机器核对。**出关（载体抽象）已完成**：新文件 `Nods/Theories/TensionAbstract.lean`（已接主链）——`forced_carrier_agnostic` 证「**任何**载体 + **任何**原子分解 ⇒ 同一公式（唯一到取向）」，命题里 `X/A/supp` 全是自由变量，无 ℕ/素数/乘法/序；三实例 ℕ（素因子集）/ 任意有限集（`supp = id`，完全不是数）/ ℤ（一行套用不用重证）；`supp_intrinsic` 证分解内蕴（`p ∈ supp n ↔ p 素 ∧ p ∣ n`，唯一分解 ⇒ 无选择）⇒ **TCM 的载体不是「数」，是「原子集合」；数只是通过唯一分解供应原子集合的一种方式**，换载体只需给出该载体的内蕴 `supp`。**扩到实数 / 虚数 / 隐数已完成**（`Nods/Theories/TensionCarriers.lean`，已接主链）：接口 `AtomicDecomp` + `AtomicDecomp.forced`（给了原子分解，逼出定理直用）；实例 `natDecomp` / `intDecomp` / `ratDecomp` / **`gaussDecomp`（虚数 → ℤ[i] 高斯素数，**不是 ℂ**）/ **`hiddenDecomp`（隐数 `⟨val,tag⟩` → `val` 的素数 + 标签本身一条）**；障碍定理 `field_no_atoms` / `real_no_atoms` / `complex_no_atoms`。三条硬结论：① **「虚数」的正确落点是 ℤ[i] 不是 ℂ**（ℂ 是域无原子，ℤ[i] 是唯一分解环）；② **挡住实数的不是「是不是域」——ℚ 也是域但有 `num/den` 典范 ⇒ 有原子**，真判据是「有没有内蕴有限分解」；③ **ℝ 的缺口是结构性的**：域里没有原子 ⇒ 乘法路被堵死，借 ℤ/ℚ 会退化成它们、换连分数只给序列不是有限集（截断即破坏 T1）⇒ 要扩到实数须把抽象从 `Finset` 升级到「序列 / 自由幺半群」——**这是真缺口**。ℂ canonicity `O-TCM-canon` 暂缓（leo 定：先完成公理搭建，不直接走黎曼函数）。
- **张力计数法 TCM — 读数升级（从 `Finset` 到「序列 / 自由幺半群」）**：新文件 `Nods/Theories/TensionReading.lean`（已接主链，8 定理，0 sorry 0 warning）。把载体接口从「有限集分解」**降为读数** `AtomicReading = (share, size)`，只要求 `share` 对称 / `share ≤ size`（无集合、交并差、序、乘法）。**主结果塌缩定理 `collapse`：`τ(a,b) = size a − size b`** —— 共享项必须约掉（正是 T5 自零在做的事），张力只能是两边的**条数差**，「收敛力 / 发散力」只是条数差拆两半的记账。ℕ 上即 `dirTension_grade_eq_omega_diff`：**τ = `ω(a) − ω(b)`**（不同素数个数之差；数一数相减，与 §10 五个数值例子全部对上并机器核对）；早先「临界流形 = {|S∖T| = |T∖S|}」简化为 **{两边条数相同}**。三个后果：① 扩载体判据变干净 —— **扩到 X ⟺ 给 X 找一个内蕴的条数 `size`**（不必再找集合分解）；② 「共同点当收敛力」为何必然失败的正解（共享项被 T5 强制消去，是公理组的结构性后果，不是可修的 bug）；③ **内容不可见**（`size_only`：条数相同 ⇒ 张力为零，不论「是哪些条」）。实例 `ofFinset`（上一层接口 = 本层特例）/ **`listLCP`（序列 / 自由幺半群：共享 = 最长公共前缀 `lcpLen`）**，序列上的张力即长度差（`list_tension_is_length_diff`）；诚实说明：LCP 也属共享、照样被约掉，**任何读数都一样 —— 内容永远进不了张力**，故本层真收获是「张力只看得见有几条，看不见是哪些条」。对 ℝ：判据从「找有限集分解」简化为「找内蕴有限条数」，CF 项数只对有理性有限 ⇒ 能进的是**二次无理数**（Lagrange：前缀 + 周期有限），一般无理数仍进不来。**分叉点**：「内容不可见」是**计数性**的后果（T5 管的是「共享不计力」，两者分工不同）—— 想让「共有多」进场 ⟹ 放弃 T5；想让「是哪些条」进场 ⟹ 放弃计数性（让原子带重量）。
- **张力计数法 TCM — 塌缩的哲学含义 + 对合层（临界线的形状）**：新文件 `Nods/Theories/TensionDuality.lean`（13 定理，已接主链，0 sorry 0 warning）。**哲学**：塌缩定理 `τ = 条数差` 不是「太薄」，而是四条承诺（**计数** / **线性** / **是力不是距离** / **共享不计力**）的**精确外延，没有一丝余量** —— 名字写完了整个理论。三个读法：① 作为极简计数法是**好消息**（方法已不能再简，而且可证）；② 作为「新空间」是坏消息（`ω` 是 Hardy–Ramanujan 1934、其分布是 Erdős–Kác 1940，条数差不是新空间，新的只是「被逼出」），但**支持 leo 最初的直觉**：数字的临界现象**正是 ω 的分布**（Erdős–Kác 正态律 `ω(n) ≈ log log n`，涨落 `√(log log n)`），而它**完整地住在条数里** —— ζ 零点与 `Re = 1/2` **不在条数里**（那是 Dirichlet 级数的分析结构）⟹ 「RH 不在计数里」，`O-TCM-canon` 为什么难，答案的一半在此；③ 最要紧：**理论是关于「什么算一条」的，不是关于力的**（选原子 = 语义全在此；数条数 = 力被逼死），故「扩载体」与「内容进场」两难题同形，都卡在**原子分解那一侧**。**三个门（各有票价）**：放弃计数 ⟹ 原子带重量的加权版 `τ_w`；放弃线性 ⟹ 允许耦合（如 `share × (ownA − ownB)`）；放弃 T5 ⟹ 回到最初两力图景（代价：数与自身有张力）；放弃「是力」⟹ 得到距离（`metric_not_nontrivial` 已证到不了非平凡临界流形）。**对合层**：缺的件是「**对合 + 载体里的 `1/2`**」，已做成定理 —— `fixOf`（中心 = 对合的不动点集）、`fixOf_invariant`、**`selfdual_tension_zero`（中心处张力为零 —— 塌缩的直接后果）**、`revZ_involutive` / `revZ_fix_iff`（反转 `ι(x) = c − x` 是对合；不动点方程 `c − x = x ⟺ 2x = c`）、**`revZ_exists_fix_iff_even`（中心存在 ⟺ `c` 为偶 ⟹ 要中点，载体里必须有 `1/2`）**、**`revZ_one_no_center`（ℤ 上没有 `1/2` ⟹ 「`1 − x`」的对合无中心）**、`revQ_fix_iff`（ℚ 上中心恒存在 = `c/2`，因 `2` 可逆）、**`revQ_one_fix_iff_half`（`1 − x = x ⟺ x = 1/2`，即 `Re = 1/2` 的形状）**、`nat_reversal_not_involutive`（ℕ 上截断减法连对合都不是）。**诚实边界**：本层给的是**临界线的形状**，不是 **RH**（零点落在线上需真的 ζ：函数方程、解析延拓、零点计数）。**下一个真问题**：对合的**内蕴性** —— ℤ 的 `c − x` 是借加法结构的（与当初 metric 借结构同一毛病），ζ 的函数方程 `s ↦ 1 − s` 才是**内蕴**的；「临界线 = 对合不动点」要真正接上 Riemann 须走出计数公理体系、进解析结构 —— 这可能是 `O-TCM-canon` 的正确形式。
- **张力计数法 TCM — 公理优化（T5 出列）+ 扩到 ℝ/ℂ 的代数部分**（两个新文件，均接主链，0 sorry 0 warning）。**① 公理优化**（`Nods/Theories/TensionOptimal.lean`，11 定理）：证明 **T5（自零）不是公理而是定理** —— **`share_coeff_zero`：T4′ 反号自己就把共享项系数消掉**（全共享剖面上 `x = −x`，ℤ 里 `x = 0`），原来这一步靠 T5；`grade_eq_scale`（T6 + T4′ ⟹ 张力 = 刻度 × 条数差）；`scale_cases`（T7 ⟹ 刻度 ∈ {−1,0,1}）；**`forced_four`（T6 + T7 + T4′ + T3b ⟹ ±条数差；旧的 `forced_unique` 里 T5 是多余参数）**；`nonfull_iff_scale_ne_zero`（T3b ⟺ 刻度 ≠ 0 ⇒ 它是「去零力」不是结构公理）；读数版 `collapse_three` / `collapse_four`；读数接口新增**自共享** `share_self`（`onlyA_self` / `toProfile_self`：**自张力为零是读数的性质**）⇒ **权威表 6 → 4 条（T5 出列），分工变三层：T4′ 管形状 / T7 管刻度 / T3b 管去零**。**② 扩到 ℝ/ℂ**（`Nods/Theories/TensionAlgebraic.lean`，5 定理）：前一层证「域无乘法原子 ⇒ 乘法路堵死」，本层换路 —— **不数因子，数共轭**：对代数数 `x`（`IsIntegral ℚ x`），`size(x) := deg (minpoly ℚ x)`（**= 共轭个数 = 域扩张次数**），`share` = 极小多项式相同则全共享否则零；`algReading` 只要求 `L` 是 ℚ 的域扩张 ⟹ **ℝ 与 ℂ 共用同一个读数**（`algReadingR` / `algReadingC`）；`alg_tension_is_degree_diff`：**张力 = 次数差**（用优化后的四条表，**不需要 T5**）；`natDegree_minpoly_rat_real` / `_complex`：有理数条数 = 1（已机器核对）；`size_of_minpoly_X_pow_sub_C`：`Xⁿ − c` 型 ⟹ 条数 `n`（√2 与 i 都是这一型）。**三条边界**：① **超越数仍进不来**（无有限极小多项式）⟹ **修正早先结论**：「ℝ 的缺口是结构性的」应改为「**ℝ 的非代数部分**进不来」—— 代数部分有一条**内蕴的路（次数），而这条路不是乘法**；② **次数读数很粗**：有理数全是 1 条 ⟹ 有理数之间张力恒为零，共轭数全共享（读数的分辨率问题，不是公理问题）；③ `share` 取「极小多项式相同」而非「共同因子的次数」（gcd 版本需要多项式 gcd 归一化引理，且按塌缩定理对张力无影响）。**顺带一个结构性观察**：ℂ 现在有**两个**读数（ℤ[i] 数高斯素数 / 次数数共轭）⟹ **同一载体可以有多个读数，读数不同、张力不同**，但每个读数内部张力仍被逼死。
- **义务 O1**：`real_initiality_obligation`（R 在"完备 Archimedean 有序域 + 嵌入 Q"中的初始性）仍是 `axiom`——需要"唯一有序域同态 R → K"的构造（Dedekind 切割显式搬运，约 80 行分析），v0.2 应替换为 `IsMinimal` 证明。原义务 O2（ℚ 有序域结构唯一）已在本 session 证成定理 `lofLinearOrder_eq_rat`。
- **振数坐标系 — 无限载体（2026-10-17 追加）**：`PeriodicDynamics` 去掉 `[Fintype X]` 约束（`same_orbit_comm` 改用结构字段 `period x` + `step_period` 补足对称性，不依赖鸽笼）⟹ **有限与无限载体共用同一套读数与塌缩**；新实例 `numPeriodicDynamics`（ℚ 反转 `x ↦ 1 − x`，显式周期：中心 `1/2` 振数 1 其余 2），`num_center_balanced` 证中心 `1/2` 张力为零（不振 = 临界 = `Re=1/2` 形状以实例性质回到视野）。见上一条完整推导链条目。
- **振数坐标系（2026-10-17，修正版：从 0 推导）**：`Nods/Theories/Vibration.lean`（已接主链，`lake build Nods` 0 sorry 0 warning）。**leo 方向修正**：不从对合/临界线/`Re=1/2` 等中间结构出发，而从系统静态世界从 0 推导振动本体。推导链：**静态世界**（`AtomicReading` + 张力 + 塌缩，已有）→ **动力学公理（唯一新公理）** `Dynamics`（`step : X ≃ X` 可逆自演化 = 时间反演对称）→ **零张力动力学（定理）** `dynamics_tension_free`（保 size ⟹ `τ(x, step x) = 0`，TCM「内容不可见」的动力学版：内容在变、张力为零）→ **周期被逼出（定理）** `period_exists`（有限载体 + 鸽笼 ⟹ `∃ p > 0, step^[p] x = x`；振数不是输入，是被有限性逼出）→ **振数坐标** `vibrationReading`（size = period）+ **`vibration_collapse`（张力 = 振数差）** + `vibCoord`。实例：点（Fin 2）/ 线（Fin 3）/ 面（Fin 2×Fin 3），周期存在各被证出。对合降级为「周期 2 实例」，非推导起点。诚实边界：周期需要载体有限（鸽笼依附 `Fintype`）；无限载体需显式周期或轨道有限假设。详见 `docs/wiki/vibration-coords.md`。
- **振数坐标系 — 相位层（2026-10-18 追加）**：`Vibration.lean` 新增 §4.5 相位层（0 sorry 0 warning，已接主链）—— 振数坐标从一维升二维：`MinimalPeriod`（最小正周期公理）+ `period_invariant_minimal`（最小周期沿轨道不变）+ `PhaseLink`（周期窗口内可达）+ **`phase_position_unique`（主定理：最小周期 ⟹ 相位步数唯一）** + `phaseIdx`/`phaseCoord`（第二坐标 = 轨道内序，坐标对 `(period, phaseIdx)`）。§7 补齐载体：`pointPeriodicDynamics`（Fin 2，显式周期 2）/ `linePeriodicDynamics`（Fin 3，显式周期 3），三例最小周期证（`num_minimal`/`point_minimal`/`line_minimal`）+ 数值 `phaseIdx 0 1 = 1`、`phaseCoord 0 1 = (2,1)`。含义：**相位唯一性 = 最小周期**（否则窗口内多步可达同一 `y`）；对合仍只是周期 2 的实例。
- **振数坐标系 — 几何坐标化（2026-10-18 追加，leo 修正后实现）**：`Nods/Theories/VibrationGeometry.lean`（已接主链，`lake build Nods` 0 sorry 0 warning）。**leo 修正**：可行性分析曾下结论「几何坐标在 TCM 公理内不可能」→ leo 要求**使得可以几何坐标化**。实现出路：`metric_not_nontrivial` 只堵「张力 = 距离的纯函数」这一形态，**不堵「给坐标配几何」**——保留张力为力，把振数坐标变成极坐标（半径 = period，角度 = phaseFrac）。离散极坐标层：`phaseFrac`（θ = phaseIdx/period 模 1，0 ≤ θ < 1）+ **`step_phase_advance`（均匀旋转：一步 = 1/period 圈）** + `polarCoord` + **`phaseFrac_injective`/`polarCoord_injective`（角度可分辨 ⟹ 同一点）** + **`tension_abs_eq_radial_dist`（几何化桥：|张力| = |振数差| = 径向距离）** + `circleDist`（模 1 圆距离，自零/对称/非负/分离）+ `polarDist`（|半径差| + 圆距离，自零/对称/分离，三角不等式 v2）。实例：点 (2, 1/2)（对合 = 半圈）/ 线 (3, 1/3)(3, 2/3)（正三角形）/ 数中心 (1, 0)（周期 1 = 退化圆 = 不振 = 原点）+ `line_phase_advance_example`（1/3 → 2/3 机器核对）。诚实边界：离散 ℚ 圆；连续弧度（2π·θ ∈ ℝ、U(1)）v2 —— ħ = 每弧度角动量的连接点是 phaseFrac 的连续化极限（共振点，非已证）。详见 `docs/wiki/vibration-coords.md`。<br>**到数条数主线的意义**：坐标系从「计数/分类」升级为「带几何」——每个振动体占据模空间一个极坐标点：坐标唯一（可分辨）、运动均匀（定角旋转）、力的量值 = 半径差。
- **Radical 计算层 v3 已完成**：任意次开方（∀n，ℝ₊ 单值）已落码（`nthrootR` + 三条 ∀n 定理，见上）。未落码候选：带 x² 项的一般三次（平移化为缺项型）、四次 Ferrari、五次 Abel–Ruffini 断崖的精确形式化（Galois 群可解性）、复根分支（μₙ 全貌，Nat.card μₙ = n）。已接主链（`Nods.lean` import）。
- 自动化约束生成（Automated Constraint Generator）：v0.1 之后阶段，尚无代码。

## 在线/风险

_（构建状态以 `lake build` 输出为准。）_

- 核心层定理的表述依赖构造注释中强调的`simp` 属性（`Framework.id_apply` / `comp_apply`）。
- 本页早先记录的"构建失败"与"R→C 空文件"已过时：本 session 已修通全链并使构建全绿，R→C 已实现（`realToComplex` / `realToComplex_minimal` / `complex_rigid`）。

## 最近风险

- 理论层 `Algebraic.lean` 的技术要点：`α →+* β` 把 `NonAssocSemiring` 实例当作类型参数携带，忘却结构后同态类型必须在定义上仍是同一类型，否则 `Biframed.forgetHom` 连恒等函数都写不出——写新理论/新实例时最容易卡住的地方。
