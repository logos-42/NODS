# Wiki 日志

## [2026-09-07] Radical：幂 vs 开方 | 形式化 + 计算层 v0

- **新文件 `Nods/Theories/Radical.lean`**（已接主链 `Nods.lean`）：把「开方 ≠ 分数次幂」的区分落成三条**完整证明**（0 sorry）：
  - `powMap_ker_eq_nRoots` —— 幂映射 `x ↦ xⁿ` 的核 = n 次单位根群 μₙ；
  - `powMap_fiber_iff` —— `zⁿ = xⁿ ⟺ z ∈ x·μₙ`（纤维 = 陪集）；
  - `powMap_injective_iff_nRoots_trivial` —— 幂单射 ⟺ μₙ 平凡（塌缩条件）。
- **数学结论**：开方与幂的区分在**挠**（μₙ）上——幂是「按 μₙ 折叠」的商（epi），开方是「把覆盖撑开」的截面（mono）；旧图景（ℝ₊ 无挠）把开方压成"幂的倒数指数"。
- **计算层 v0**（同文件）：形式化地"解释一个数"，四条函数族给不同公式——幂 `5² = 25`、开方 `Nat.sqrt 25 = 5`（ℕ 可算）；`¬∃n:ℕ, n²=2`、`¬∃q:ℚ, (q:ℝ)²=2`（幂解释不了 2 → 逼出根式对象）；开方解可解公式 `φ = (1+√5)/2` 且机器验证 `φ² = φ+1`；指数/对数 `e^(ln 2) = 2`、`e^(ln 3) = 3` 与根式路径公式不同。
- **示意图**：`docs/figures/root_vs_power.png`（幂折叠 vs μ₄ 正方形），脚本 `scripts/plot_root_vs_power.py`，已登记 `manifests/raw_sources.csv`（src-fig-001）。

## [2026-09-04] 修通 N→Z→Q→R→C 全链 | 证成义务 O2

- **修通整条数系扩张链**：`lake build` 从失败变全绿（6 核心层 + 4 实例全部编译通过，Lean v4.21.0）。
- **核心纠错**：删除两个假命题 `no_commRing_on_nat`（¬ Nonempty (CommRing ℕ)）与 `no_field_on_int`（¬ Nonempty (Field ℤ)）。它们**不可能证出**——可数等势（ℕ≃ℤ、ℤ≃ℚ）可沿双射用 `Equiv.commRing`/`Equiv.field` 搬运结构。真正的 gap 在 `HasSolution` 的 `hstr`（`forgetStr s' = S.str`）匹配约束上；三个 `*_gap` 定理统一改为用 `hstr` 转移结构等式，再交给 `omega`/`nlinarith` 收尾。
- **`LOF` 重建**：mathlib 已弃用捆绑类 `LinearOrderedField`，改为自定义结构 `LOF`（`Field` + `LinearOrder` + `IsStrictOrderedRing`），`Nods/Theories/Algebraic.lean` 同步改。
- **修复各实例**：`NatToInt`（emb_inj 用 `Nat.cast_injective`、`natToInt_minimal` 补实例）、`IntToRat`（`int_gap` 用 `hstr` + `int_no_half`、同态唯一性用 `RingHom.ext_rat`）、`RatToReal`（`rat_no_sqrt_two`/`rat_not_dedekind_complete`/`real_cut_generated` 分析证明）、`RealToComplex`（`demandSqrtNegOne`/`real_gap`/`complexLift`/`realToComplex_minimal`）、`Chain`（删重复的 `AnyWorld`/`packWorld` + noncomputable）。
- **证成义务 O2**：`lofLinearOrder_eq_rat`（ℚ 有序域结构唯一）从 `axiom` 改为 `theorem`。关键：`IsStrictOrderedRing` 只给严格单调（不给 `IsOrderedRing` 的 `div_nonneg`），故非负方向用 `le_iff_lt_or_eq` 拆成 `= 0` 与 `> 0` 两路，走 `div_pos_iff_of_pos_right`；同时需显式 `letI` 覆盖 `LE`/`LT`/`Preorder`/`PartialOrder`（全局 `Rat.instLE` 等直接实例会压过局部序）。
- **剩余义务 O1**：`real_initiality_obligation`（R 初始性，约 80 行 Dedekind 分析）仍为 `axiom`，推迟 v0.2。

## [2026-09-04] 初始化 | bootstrap 知识系统

- 用「维基 llm」v2.0.0 bootstrap 出 `docs/wiki/` + `manifests/` + `scripts/` + 平台配置。
- 项目名：NODS — New Object Discovery System（Lean 4 + mathlib 数学对象发现系统）。
- 将 5 个 wiki 页升级到 `schema_version: 2` 并填充真实内容（项目概览 / 当前状态 / 资料索引 / 运行时 / 版本策略）。
- 登记 5 条原始素材进 `manifests/raw_sources.csv`（design.md、skill.md、Core/Instances/Theories 源码）。
- `.gitignore` 补充忽略 `.lake/`（Lake 构建产物）。
- 发现并记录关键缺口：`Nods/Instances/RealToComplex.lean`（R→C）为空，次优下一步。
