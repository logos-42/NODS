# Wiki 日志

## [2026-09-07] 计算层 v3 | 任意次开方（∀n）+ 论文双语发布 EN v1.1 / ZH v1.0

- **计算层 v3（任意次开方）**：Radical.lean 新增 `nthrootR n x := e^{(ln x)/n}`（ℝ₊ 的 n 次开方）与三条 ∀n 定理——`nthrootR_pow`（(⁽ⁿ⁾√x)ⁿ=x）、`pow_inj_on_Rpos`（ℝ₊ 上 pₙ 对任意 n 单值 = μₙ 平凡塌缩的 ∀n 形式）、`nthrootR_eq_of_pow`（a>0 ∧ aⁿ=x ⟹ a=⁽ⁿ⁾√x，单值逆）。同一定理覆盖 √（n=2）、∛（3）、⁵√（5）与任意 n：示例 `(nthrootR 5 32)^5 = 32`、`nthrootR 5 (2^5) = 2`、∛27、√9、`a^7 = 128 ⟹ a = ⁷√128`。0 sorry 0 warning，`lake build` 全绿。
- **论文扩展（中英双版）**：新增 Theorem（任意次开方）——纯开方无次数上限（对每个 n 同时成立，非 n→∞ 极限）；五次之墙是**混合塔**之墙（一般五次逃出根式塔，Abel–Ruffini），纯根式民主。摘要/结论/边界措辞同步；`aixiv_meta_radical_en.json` 摘要刷新，新建 `aixiv_meta_radical_zh.json`。
- **发布（双语）**：
  - aiXiv EN：`aixiv.260907.000001` v1.0 → **v1.1**（id 1459，Under Review，public）——含任意次开方的新 PDF + 新摘要；v1.0 保留。
  - aiXiv ZH（新）：`aixiv.260908.000008` v1.0（id 1460，Under Review，public），标题《被逼出的真实结构：如何把幂与开方劈开》。
  - EAS 主网（schema #405）：EN v1.1 UID `0xd808138983bda69edc418ee6d3dc30a0eb8f634b924a705eda89031d64a7ea68`（CID `QmVgDR916EHoNFb3rg3W4EdDNkmR1hRLDJarJqyhGZcLGj`）；ZH v1.0 UID `0x042a1ee3a44f8e0aef91627b70db72b68781a515378bf4d4ca00381d686f2faa`（CID `QmRnfwEUo3LE7qpzu5AnAwvmLomdoUNpAvwocnrtzac3Ed`）。链上 getAttestation 验证通过；台账 `~/.hermes/eas-bind/README.md` 已记录。

## [2026-09-07] 论文发表 | radical EN 上 aiXiv + 以太坊 EAS 锚定

- **aiXiv 预印本**：`aixiv.260907.000001` v1.0（submission 1445，Under Review，CC-BY-4.0，is_public=1，authorship_type=human）；公开记录署名「元杰 刘」/ ~User52。
  - 标题：*The radical as a forced structure: how to split powers from radicals*
  - 摘要已同步论文当前版（含 Cardano 三次推进段）；元数据模板 `paper/radical/aixiv_meta_radical_en.json` 留档供后续版本更新。
- **以太坊 EAS 主网锚定**（照黎曼论文流程，`eas-bind-paper.js`，复用 schema #405）：
  - Attestation UID: `0x5e52a523299a348fd61f2264ac735e6bbfd5ecc439c35718432aa5791d53e05d`
  - 验证: https://easscan.org/attestation/view/0x5e52a523299a348fd61f2264ac735e6bbfd5ecc439c35718432aa5791d53e05d
  - 绑定: IPFS CID `QmVQDR2MT2fGKkAeUhKTjTmg9boqAnFiaSoMAfdHTys7Ec`（本地 Kubo pin）+ 标题 + sha256 `d0ddbafc…e15c9`；recipient `0xb4e9dCF79055A8232670ebb1c8c664Dff4E70066`
- 发布对象 = 计算层 v2（Cardano 三次）落码后的 EN 论文版（2026-09-07 重编译，tex 含新增 thm:cubic）。

## [2026-09-07] 计算层 v2 | Cardano 三次根式解

- **三次 Cardano**（`Nods/Theories/Radical.lean` 计算层 v2）：`x³+px+q=0`，判别式 ≥0 时构造性给根。
  - `cube_surj`：先证实数立方满射（IVT 于 `[0,max 1 √y]`，负数走对称）——这是 ∛ 的存在性半边；
  - `cardano_certificate`：纯代数证书（u³、v³ 方程 + uv = −p/3 ⟹ u+v 是根）；
  - `vcube`：v := −(p/3)/u 技巧自动满足 v³ = −q/2 − s（v 不能独立开方，否则 u·v 差三次单位根——挠第三次出场）；
  - 示例 `x³−3x+2=0`（判别式 0）有实根。
- 全仓 `lake build` 绿（0 错误 0 警告 0 sorry）；边界注明：五次及以上一般无根式解（Abel–Ruffini，待后续）。

## [2026-09-07] 计算层 v1 | 通用二次根式 solver + 主链 0 警告

- **通用二次根式 solver**（`Nods/Theories/Radical.lean` 计算层 v1）：示范 φ 升级为任意 `x²−bx−c=0`。判别式 ≥0 → 根式公式 `(b±√(b²+4c))/2` 机器验证为解（`quadRootPlus_sq`/`quadRootMinus_sq`）+ 多项式分解证书 `quadFactor`（无其他根）；判别式 <0 → `quad_no_roots` 证无实根；判据合成 `quad_solvable_iff`。含可算示例 `quadRootPlus 2 3 = 3`。
- **主链警告清零（0 警告 0 sorry）**：Verdict/Engine 三定理 `omit [Biframed T T']`（omit 须在 docstring 之前）；Engine 两处未用绑定改名 `_h`/`_d`；Algebraic 六个 Refinement 实例去掉未用 `{α}`。
- 全仓 `lake build` 绿；AGENTS.md 已加 §5 commit 门禁（wiki 校验前置）。

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
