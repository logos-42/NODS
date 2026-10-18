# Wiki 日志

## [2026-10-18] 振数坐标系 | 几何坐标化：离散极坐标层（leo 修正后实现）

- **leo 修正**：上一条可行性分析（本日）的结论是「几何坐标在 TCM 公理内不可能」——
  leo 要求**使得可以几何坐标化**。实现出路：`metric_not_nontrivial` 只堵
  「张力 = 距离的纯函数（零集 = 对角线）」这一形态，**不堵「给坐标配几何」**——
  保留张力为力（TCM 塌缩不动），把振数坐标变成真正的极坐标。
- **新文件 `Nods/Theories/VibrationGeometry.lean`**（已接主链，`lake build Nods`
  0 sorry 0 warning，`#print axioms` 无 `sorryAx`）：
  - `phaseFrac`：相位分数 θ = phaseIdx/period ∈ ℚ 模 1（`phaseFrac_nonneg`/`_lt_one`：0 ≤ θ < 1）
  - `PhaseLink_self` + `phaseFrac_self`：原点相位 = 0（自链 k = 0）
  - **`step_phase_advance`（均匀旋转，主定理）**：走一步角度精确推进 1/period —— 轨道是正 N 边形
  - `polarCoord`：极坐标（半径 = period，角度 = phaseFrac）
  - **`phaseFrac_injective` / `polarCoord_injective`**：同窗口角度相同 ⟹ 同一点（坐标可分辨）
  - **`tension_abs_eq_radial_dist`（几何化桥，主定理）**：|张力| = |振数差| = 径向距离
  - `circleDist`：圆距离 min(|Δθ|, 1−|Δθ|)；自零 / 对称 / 非负 / 分离（`circleDist_eq_zero_iff`）
  - `polarDist`：极坐标度量 = |半径差| + 圆距离；自零 / 对称 / 分离（`polarDist_eq_zero_iff`）
  - 实例：点 (2, 1/2)（对合 = 半圈）/ 线 (3, 1/3)、(3, 2/3) / 数中心 (1, 0)
    （周期 1 = 退化圆 = 不振 = 原点）+ `line_phase_advance_example`（1/3 → 2/3 均匀推进机器核对）
- **含义**：坐标系从「计数/分类」升级为「带几何」——每个振动体占据模空间一个
  极坐标点：坐标唯一、运动均匀（定角旋转）、力的量值 = 半径差。
- **诚实边界**：离散 ℚ 圆（正 N 边形）；连续弧度（2π·θ ∈ ℝ、U(1)、sin）v2；
  `polarDist` 三角不等式 v2。ħ = 每弧度角动量的连接点是 phaseFrac 的连续化极限
  （共振点，非已证）。
- **回写**：`vibration-coords.md`（几何坐标化节 + 台账 + 下一步 ③ 更新 +
  可行性分析节「不可能」结论更正）、`current-status.md` 追加；raw manifest 无需登记
  （纯代码文件，`src-code-vibration-002` 注释更新）。

## [2026-10-18] 振数坐标系 | 弦论推导可行性分析（模空间 / 组合律 / 连续谱）

- **leo 问**：坐标系能否实现？能否直接构建一个新空间体系、在里面推导出弦论？
- **结论一（坐标系）**：计数坐标已实现（`phaseCoord = (period, phaseIdx)`，0 sorry），
  几何坐标在 TCM 四条公理内**不可能**（`metric_not_nontrivial` 度量被堵 +
  `size_only` 内容不可见）——「坐标系」的两种含义必须分开。
- **结论二（新空间）**：能构建的是**模空间（mode space）**= 独立振子的乘积
  （`productDynamics` 已是种子），坐标 = 每振子 `(振数, 相位)`，维数 = 独立振子数。
  这正是简正坐标/傅里叶模空间的结构——弦的模展开 `X = Σ Xₙ e^{2πinσ}` 天然住这里。
  真运算：组合（并，已形式化）/ 张力可加（T6）/ 相位推进；缺距离层（换读数
  才能有几何）与连续化（相位是 ℕ 不是弧度）。
- **结论三（弦论）**：**推导不出**。能证的是「振动优先于弦」（载体任意，弦只是
  载体之一）；推不出频率谱（哈密顿量对角化 = 动力学内容）、临界维数 D=10/26
  （量子化一致性）、相互作用、背景时空度量。深层数学：连续振动 = `ℝ → U(1)`
  同态 = 频率（Pontryagin 对偶/特征群）——傅里叶分析就是振动的数学；频率谱
  不在计数里，与 `O-TCM-canon`（RH 不在计数里）同型。
- **候选缺口（NODS 判据，按距代码远近）**：① 组合律——叠加两振子总振数是和还是积，
  若"叠加后仍单振子且保塌缩"在同一载体不可表达 ⟹ 逼出叠加运算 = 给空间装算术；
  ② 连续频率——什么约束逼出 ℝ 值频率（候选：时间平移对称连续化 → U(1) 特征）；
  ③ 相位 → 角度——轨道内序 ℕ 升级为弧度，**接 ħ = 每弧度角动量**（共振点，非已证）。
- 未改代码；本批只回写分析结论。

## [2026-10-18] 振数坐标系 | 相位层（第二坐标）：最小周期 + 轨道内序

- **`Nods/Theories/Vibration.lean` 新增 §4.5 相位层**（0 sorry 0 warning，已接主链）—— 振数坐标从一维升级为二维：第一坐标 = 振数 `period x`，第二坐标 = 轨道内序。
  - `MinimalPeriod`：`period x` 是最小正周期（`∀ x k, 0 < k → k < period x → step^k x ≠ x`）—— 不是振动本体的起点（本体已由 `Dynamics` + `period_exists` 建立），只负责让「轨道内第几步」成为唯一的第二坐标。
  - `period_invariant_minimal`：最小周期沿轨道不变（可逆性 + 最小性 ⟹ `period (step^k x) = period x`）。
  - `PhaseLink`：`y` 在 `x` 的一个周期窗口内可达（`∃ k < period x, step^k x = y`）—— 局部规范版本，不需要重新选轨道代表元。
  - `phase_position_unique`（主定理）：最小周期 ⟹ 相位链步数唯一（`step^k x = step^k' x` 且都在窗口内 ⟹ `k = k'`）。
  - `phase_link_unique`：`∃! k`；`phaseIdx`（`Classical.choose`）+ `phaseIdx_lt` / `phaseIdx_spec` / `phaseIdx_step`（走一步，原始步数推进一格）。
  - `phaseCoord`：坐标对 `(period x, phaseIdx)`。
- **§7 实例补齐**：新增 `pointPeriodicDynamics : PeriodicDynamics (Fin 2)`（显式周期 2，`swapFin2` 对合）与 `linePeriodicDynamics : PeriodicDynamics (Fin 3)`（显式周期 3，`shiftFin3` 移位）—— 此前 §5 只有裸 `Dynamics`，`MinimalPeriod`/`PhaseLink` 无载体可挂。三个最小周期证：`num_minimal`（ℚ 反转：中心 1/2 振数 1、其余 2）/ `point_minimal` / `line_minimal`；相位数值：`point_phase_link`（`0 → 1` 一步可达）、`point_phase_idx`（`phaseIdx 0 1 = 1`）、`point_phase_coord`（`(period 0, phaseIdx 0 1) = (2, 1)`）。
- **含义**：相位是周期之上的第二坐标，唯一性来自最小周期——没有 `MinimalPeriod`，同一个 `y` 可在窗口内多步到达（周期倍数），第二坐标无从定义。对合（周期 2）仍是相位层的实例而非起点。

## [2026-10-17] 振数坐标系 | 无限载体：ℚ 反转（显式周期）+ PeriodicDynamics 泛化

- **leo 选的下一步：无限载体（轨道有限假设下的显式周期）。**
- **`PeriodicDynamics` 泛化**（`Nods/Theories/Vibration.lean`，仍 0 sorry 0 warning）：
  - 去掉 `[Fintype X]` 约束 —— **载体不限有限**。`same_orbit_comm` 不再依赖
    `period_exists`（鸽笼），改用结构字段 `period x` + `step_period` 补足轨道对称性
    （`p = period x`、`q·p ≥ k`）⟹ **有限与无限载体共用同一套读数与塌缩**。
  - 有限载体周期仍由 `period_exists`（鸽笼）**逼出**；无限载体周期是**显式结构字段**
    （轨道有限假设）—— 两条路都通。
- **新实例：`ℚ` 反转（无限载体）**：`numPeriodicDynamics`（`revQ1 : x ↦ 1 − x`）。
  `period := if 1 − x = x then 1 else 2` —— 中心 `1/2` 振数 1（不振），其余 2。
  - `num_period_center` / `num_period_off_center`：中心 1、非中心 2（机器核对）。
  - **`num_center_balanced`：中心 `1/2` 处张力为零** —— 不振 = 临界，
    `Re = 1/2` 的形状回到视野（作为数振动的**不动点实例**，不是推导起点）。
- **wiki `vibration-coords.md`**：实例表加入 ℚ 行 + 泛化说明（`PeriodicDynamics`
  不要求 `Fintype`）+ 台账更新（无限载体 🟢）+ 「下一步」标记无限载体已完成。
- **回写**：`current-status.md` 追加；`manifests/raw_sources.csv` 更新
  `src-code-vibration-001`。

## [2026-10-17] 振数坐标系 | 修正：从静态世界从 0 推导振动本体（不再借对合/临界线）

- **leo 方向修正**：不要从对合、临界线、`Re = 1/2` 这些**中间结构**出发推导，
  要从系统架构（静态世界）从 0 推导振动本体。
- **重写 `Nods/Theories/Vibration.lean`**（仍接主链；`lake build Nods` 0 sorry 0 warning）：
  - **第 0 步**：静态世界（已有）—— `AtomicReading` + 张力公理 + 塌缩。不是振动。
  - **第 1 步：动力学公理（唯一新公理）** `Dynamics`：`step : X ≃ X`（**可逆**自演化
    = 时间反演对称）。载体 X 任意——点/线/面/数一切皆可振。
  - **第 2 步：零张力动力学（定理）** `dynamics_tension_free`：保 size 演化 ⟹
    `τ(x, step x) = 0` —— TCM「内容不可见」的动力学版：**内容在变、张力为零**。
  - **第 3 步：周期被逼出（定理）** `period_exists`：有限载体 + 鸽笼 ⟹
    `∃ p > 0, step^[p] x = x`。辅助：`cancel_iter`（可逆迭代抵消）、`iterate_split`、
    `period_of_repeat`（轨迹重复 ⟹ 周期）、`iterate_mul_fixed`（周期倍数闭包）、
    `same_orbit_comm`（同轨道对称，用周期 + q·p ≥ k，不需要最小周期）。
  - **第 4 步：振数坐标** `vibrationReading`（size = period，share = min 共同周期）+
    **`vibration_collapse`（张力 = 振数差）**；`vibCoord` / `vib_tension_is_coord_diff`。
  - 实例：点（`Fin 2` 交换）/ 线（`Fin 3` 循环）/ 面（`Fin 2 × Fin 3` 双振子），
    周期存在各被 `period_exists` 证出（`point_period_exists` 等）。
  - **对合降级为实例**（`swapFin2` 只是周期 2 的振动），不再是推导起点；
    `ℚ` 反转、`Re=1/2` 连接移出（无限载体需显式周期假设，见「下一步」）。
- **wiki `vibration-coords.md` 重写**：推导链四步（静态世界 → 动力学公理 → 零张力 →
  周期逼出 → 坐标）+ 坐标系规范表 + 诚实台账（唯一新公理 1 条，其余全定理）。
- **诚实边界**：周期需要载体有限（鸽笼依附 `Fintype`）；无限载体要 `PeriodicDynamics`
  式显式周期或轨道有限假设。
- **回写**：`current-status.md` 追加；`manifests/raw_sources.csv` 更新
  `src-code-vibration-001` 注释。

## [2026-10-12] 张力计数法 | 公理优化（T5 出列）+ 扩到 ℝ/ℂ（代数数的次数读数）

- **两个新文件**（均接主链，`lake build Nods` 0 sorry 0 warning，`#print axioms` 无 `sorryAx`）：
  `Nods/Theories/TensionOptimal.lean`（11 定理）、`Nods/Theories/TensionAlgebraic.lean`（5 定理）。

### ① 公理优化：T5 出列（`TensionOptimal.lean`）

- **主结果 `share_coeff_zero`：T4′ 反号自己就把共享项系数消掉。**
  全共享剖面 `(t,0,0)` 反着读还是自己 ⟹ 反号要求该处张力等于自己的相反数 ⟹ ℤ 里只能为 0。
  原来这一步靠 T5（自零：两力各自为零）来做，**现在证明不需要它**。
- `grade_linear_free`（不带任何假设的线性化）→ `grade_eq_scale`（**T6 + T4′ ⟹ 张力 = 刻度 × 条数差**）
  → `scale_cases`（**T7 ⟹ 刻度 ∈ {−1, 0, +1}**）→ `forced_three`（±条数差 或 恒零，不假设 T5/T3b）
  → **`forced_four`：T6 + T7 + T4′ + T3b ⟹ `τ = ±条数差`，不需要 T5**。
- `nonfull_iff_scale_ne_zero`：**T3b ⟺ 刻度 ≠ 0** —— 它是「去零力」的非退化要求，不是结构公理。
- 读数版：`AtomicReading.collapse_three` / `collapse_four`。
- 读数接口补一条自然性质 **`share_self`（自共享）**：⟹ `onlyA_self` / `onlyB_self` / `toProfile_self`
  ⇒ **「自张力为零」不是公理，而是读数的性质**。
- ⇒ **权威表 6 条 → 4 条**，分工变干净的三层：**T4′ 管形状 / T7 管刻度 / T3b 管去零**；
  T5 的真正作用只有一个：把 `K` 与 `L` 各自钉住（对**张力差** —— 唯一可观测的东西 —— 无影响）。

### ② 扩到 ℝ 与 ℂ：代数数的次数读数（`TensionAlgebraic.lean`）

- 前一层结论是「ℝ/ℂ 作为**域**没有乘法原子 ⇒ 乘法路堵死」。本层换路：**不数因子，数共轭。**
  对代数数 `x`（`IsIntegral ℚ x`）：`size(x) := deg (minpoly ℚ x)` = **共轭个数 = 域扩张次数**；
  `share(x,y) := 极小多项式相同时取全部，否则 0`。
- `algReading` 只要求 `L` 是 ℚ 的域扩张 ⟹ **ℝ 与 ℂ 共用同一个读数**（`algReadingR` / `algReadingC`）。
- **`alg_tension_is_degree_diff`：张力 = 次数差**（用优化后的四条表，不需要 T5）。
- `alg_tension_zero_of_same_size`；`natDegree_minpoly_rat_real` / `_complex`（**有理数条数 = 1**，已机器核对）；
  `size_of_minpoly_X_pow_sub_C`（`Xⁿ − c` 型 ⟹ 条数 `n`；`√2` 与 `i` 都是这一型）。
- **三条边界**：
  1. **超越数仍进不来**（无有限极小多项式）⟹ **修正早先结论**：「ℝ 的缺口是结构性的」应改为
     「**ℝ 的非代数部分**进不来」—— 代数部分有一条**内蕴的路（次数），且这条路不是乘法**。
  2. **次数读数很粗**：有理数全是 1 条 ⟹ 有理数之间张力恒为零；共轭数（极小多项式相同）也全共享。
     这是**读数的分辨率**问题，不是公理的问题。
  3. `share` 取「极小多项式相同」而非「共同因子的次数」：更细的 gcd 版本需要多项式 gcd 的
     归一化引理（`gcd m m = m`）；而按塌缩定理，**共享项对张力毫无影响**，故不必要。
- **结构性观察**：ℂ 现在有**两个**读数（ℤ[i] 数高斯素数 / 次数数共轭）⟹
  **同一载体可以有多个读数，读数不同、张力不同**，但每个读数内部张力仍被逼死。

### 回写

- `tension-counting.md`：**页首权威表升级为 TCM-3（4 条）** + 「公理优化」节 + 「扩到 ℝ 与 ℂ」节
  + 两条台账行 + 下一步重写（读数已有三种口味：乘法条数 / 次序条数 / 共轭条数）。
- `current-status.md`；`manifests/raw_sources.csv` 登记 `src-code-tension-006` / `-007`。

## [2026-10-12] 张力计数法 | 塌缩的哲学含义 + 对合层（临界线 = 对合的不动点）

- **新文件** `Nods/Theories/TensionDuality.lean`（13 定理，已接主链，`lake build Nods` 0 sorry 0 warning，`#print axioms` 无 `sorryAx`）。
- **塌缩的哲学含义**（写入 `tension-counting.md`「塌缩的哲学含义」节）：`τ = 条数差` 不是「结果太薄」，
  而是四条承诺的**精确外延、没有一丝余量** ——
  **计数**（只看「有几条」⟹ 排除「是哪些条」）/ **线性**（⟹ 排除耦合项）/
  **是力不是距离**（T4′ ⟹ 排除一切对称量）/ **共享不计力**（T5 ⟹ 排除线性共享项）。
  四条排完只剩一个东西：条数差。**这个名字把整个理论写完了。**
- **归因更正**：早先把「内容不可见」记成 T5 的后果是**错的**。两条承诺分工不同 ——
  **计数性**排除「是哪些条」；**T5** 排除「共有多 = 收敛」这个线性共享项。文档已改。
- **三个读法**：① 作为极简计数法是**好消息**（不能再简，且可证）；
  ② 作为「新空间」是坏消息（`ω` = Hardy–Ramanujan 1934 / Erdős–Kác 1940，条数差不是新空间），
  但**支持 leo 最初的直觉**：数字的临界现象**正是 ω 的分布**（Erdős–Kác 正态律），
  而它**完整地住在条数里**；ζ 零点与 `Re = 1/2` **不在条数里** ⟹ 「RH 不在计数里」，
  这解释了 `O-TCM-canon` 为什么难；
  ③ 最要紧：**理论是关于「什么算一条」的，不是关于力的** ——
  选原子（语义全在此）+ 数条数（力被逼死）⟹ 扩载体与内容进场是同一个难题，
  都卡在**原子分解那一侧**。
- **三个门（各有票价）**：放弃计数 ⟹ 原子带重量的加权版；放弃线性 ⟹ 允许耦合；
  放弃 T5 ⟹ 回到两力图景；放弃「是力」⟹ 得到距离（`metric_not_nontrivial` 已证到不了非平凡临界流形）。
- **对合层**：缺的件是「**对合 + 载体里的 `1/2`**」。已证：
  `fixOf`（中心 = 对合的不动点集）/ `fixOf_invariant` / **`selfdual_tension_zero`（中心处张力为零）** /
  `revZ_involutive` + `revZ_fix_iff`（反转 `ι(x) = c − x`，不动点 `⟺ 2x = c`）/
  **`revZ_exists_fix_iff_even`（中心存在 ⟺ `c` 为偶 ⟹ 载体里必须有 `1/2`）** /
  **`revZ_one_no_center`（ℤ 上没有 `1/2` ⟹ 无中心）** / `revQ_fix_iff`（ℚ 上中心 = `c/2`）/
  **`revQ_one_fix_iff_half`（`1 − x = x ⟺ x = 1/2` = `Re = 1/2` 的形状）** /
  `nat_reversal_not_involutive`（ℕ 上连对合都不是）。
  ⇒ **临界线 = 对合的不动点集**；`Re = 1/2` 就是「`1 − s`」的不动点，而 `1/2` 只在 2 可逆的载体里存在。
- **诚实边界**：给的是**临界线的形状**，不是 **RH**（零点落在线上需真的 ζ）。意义是**把缺件说准**。
- **下一个真问题**：对合的**内蕴性** —— ℤ 的 `c − x` 借加法结构；ζ 的函数方程 `s ↦ 1 − s` 才是内蕴的。
- **回写**：`tension-counting.md`（哲学节 + 归因更正 + 对合节 + 台账行 + 下一步重写）；
  `current-status.md`；`manifests/raw_sources.csv` 登记 `src-code-tension-005`。

## [2026-10-12] 张力计数法 | 读数升级：从 `Finset` 到序列 / 自由幺半群（塌缩定理）

- **新文件** `Nods/Theories/TensionReading.lean`（8 定理，已接主链，`lake build Nods` 0 sorry 0 warning，`#print axioms` 无 `sorryAx`）。
- **接口降级**：载体从「有限集分解 `supp : X → Finset A`」降为**读数** `AtomicReading = (share, size)`，
  只要求 `share` 对称与 `share ≤ size` —— 无集合、无交并差、无序、无乘法。
  ⇒ 重集（自由交换幺半群）、序列（自由幺半群）都成合法载体。
- **主结果：塌缩定理** `collapse` —— `τ(a,b) = size a − size b`。
  共享项被 **T5 自零**强制消去，张力只能是两边的**条数差**；收敛力 / 发散力只是条数差拆两半的记账。
  ℕ 上的样子 `dirTension_grade_eq_omega_diff`：**τ = ω(a) − ω(b)**（不同素数个数之差），
  与 §10 五个数值例子全部对上（已机器核对）；早先「临界流形 = {|S∖T| = |T∖S|}」可简化为 **{两边条数相同}**。
- **三个后果**：
  1. 扩载体的问法变干净：**扩到 X ⟺ 给 X 找一个内蕴的条数 `size`**（不必再找集合分解）。
  2. 「共同点当收敛力」必然失败的正解：共享项被 T5 强制消去，是公理组的结构性后果，不是可修的 bug。
  3. **内容不可见**（`size_only`）：条数相同 ⇒ 张力为零，不论「是哪些条」。
- **实例**：`ofFinset`（上一层接口 = 本层特例）/ **`listLCP`（序列：共享 = 最长公共前缀 `lcpLen`）**；
  `list_tension_is_length_diff` 说序列上的张力就是长度差 —— 诚实说明：LCP 也属共享、照样被约掉，
  **任何读数都一样**，所以本层的真收获是「张力只看得见有几条，看不见是哪些条」。
- **对 ℝ**：判据从「找有限集分解」变为「找内蕴有限条数」；CF 项数只对有理性有限
  ⇒ 能进的是**二次无理数**（Lagrange：前缀 + 周期有限），一般无理数仍进不来。
- **分叉点**：要让内容进场只能**放弃 T5（自零）**，代价是「数与自身有正张力」—— 记为候选 TCM-3（内容版）。
- **回写**：`tension-counting.md` 新增「升级：从 `Finset` 到读数」节 + 台账行 + 下一步重写；
  `current-status.md` 追加本条；`manifests/raw_sources.csv` 登记 `src-code-tension-004`。

## [2026-10-12] 张力计数法 | 扩到实数 / 虚数 / 隐数：载体逐个定案

- **leo 要的**：把张力计数法扩到实数、虚数、隐数。
- **新文件 `Nods/Theories/TensionCarriers.lean`**（已接主链；`lake build Nods` 0 sorry 0 warning）：
  - 接口 `AtomicDecomp X A`（= `supp : X → Finset A`）+ `AtomicDecomp.forced`：给了原子分解，逼出定理直接用。
  - **实例**：`natDecomp`（素数）/ `intDecomp`（`|z|` 的素数）/ `ratDecomp`（`num/den` 的素数，分子分母分开）/ **`gaussDecomp`（ℤ[i] 高斯素数）** / **`hiddenDecomp`（隐数）**。
  - **障碍定理**：`field_no_atoms`（域里非零元都是单位 ⇒ 没有不可约元）、`real_no_atoms`、`complex_no_atoms`。
  - 例子 `hidden_tag_balanced`：同值不同标签的两个隐数各独有一条（对方的标签）⇒ 张力为零。
- **三条结论**：
  1. **「虚数」的正确落点是 ℤ[i]，不是 ℂ。** ℂ 是域（无原子），ℤ[i] 是唯一分解环 ⇒ 高斯素数就是原子。
  2. **挡住实数的不是「是不是域」—— ℚ 也是域，但 `num/den` 典范 ⇒ 它有原子。** 真判据是「有没有内蕴有限分解」。
  3. **ℝ 的缺口是结构性的**：`real_no_atoms` 说域里没有原子 ⇒ 扩到实数不能走 ℝ 自己的乘法；借 ℤ/ℚ 就退化成它们的实例，换连分数又只给**序列**不是有限集（截断即引入选择，破坏 T1）⇒ 要扩到实数，必须把抽象从 `Finset` 升级到「序列 / 自由幺半群」。**这是真缺口。**
  4. **隐数（HIBS）有天然原子**：`Hidden = ⟨val : ℤ, tag ∈ {S,R,iR}⟩` ⇒ 原子 = `val` 的素数 **+ 标签本身一条**（标签不是坐标，是一条原子）。
- **审计**：新定理 `#print axioms` → `[propext, Classical.choice, Quot.sound]`（`hidden_tag_balanced` 含 `Lean.ofReduceBool`，走 native 求值），无 `sorryAx`；三个 Tension 文件合 59 定理 0 sorry。

## [2026-10-12] 张力计数法 | 出关：载体抽象 —— 公式与载体无关

- **leo 要的**：把判据从 ℕ 抽象到「任何有原子分解的载体」。
- **新文件 `Nods/Theories/TensionAbstract.lean`**（已接主链 `Nods.lean`；`lake build Nods` 0 sorry 0 warning）：
  - `profileOf S T := (|S∩T|, |S∖T|, |T∖S|)` —— 「原子读数」，TCM 唯一需要的东西。
  - **`forced_carrier_agnostic`（主定理）**：`X` 是**任何**类型、`supp : X → Finset A` 是**任何**原子分解 ⇒ 满足公理的张力只能是 `|supp a ∖ supp b| − |supp b ∖ supp a|`（唯一到取向）。命题里 `X / A / supp` 全是自由变量 —— **没有 ℕ、没有素数、没有乘法、没有序**。
  - **三个实例**：A = ℕ（素因子集，`dirTension` 直读）；B = **任意有限集本身**（`supp = id`，完全不是数 ⇒ 张力 = 两有限集的独有差）；C = ℤ（`suppZ z = |z|` 的素因子集，**一行套用不用重证** —— 抽象出来的收益）。
  - **`supp_intrinsic`**：`p ∈ supp n ↔ p 素 ∧ p ∣ n` —— 原子分解由整除关系定死，**没有选择**（唯一分解）。逼出是载体无关的（定理），**直接性（T1）靠分解的内蕴性**。
- **结论一句话**：**TCM 的载体不是「数」，是「原子集合」；数只是通过唯一分解供应原子集合的一种方式。** 换载体的代价只剩一件 —— 找到该载体自己的内蕴原子分解；找到了，公式不变、定理免费。
- **审计**：新定理 `#print axioms` → `[propext, Classical.choice, Quot.sound]`，无 `sorryAx`。

## [2026-10-12] 张力计数法 | 数字层面为什么成立：直读三句话 + `60 与 45` 算例

- **leo 要的解释**：为什么张力计数法在数字层面成立、为什么能算出两个数之间的张力与收敛力。
- **写进文档**：`tension-counting.md` 新增「为什么它成立：数字层面的直读」一节（置于页首定义之后、权威表之前）。
  - **三句话**：① 每个数就是一捆素数条（唯一分解，不同素数各算一条）；② 两条数并排，每条素数只有三种身份（两边都有 / 只在 a / 只在 b）—— 数对可读的就这三样，所以 T1 是**实话**不是规定；③ 力必须有方向，故「两边都有」出局（对称、推不动任何一边）—— 力只能来自**不对称**。
  - **一句话公式**：`τ(a→b) = |S_a∖S_b| − |S_b∖S_a|`（谁比谁多几条独有）。收敛力/发散力是 T2 的两半记账；哪一半叫「收敛」正是那个被证明**自由**的取向。
  - **算例 `60 与 45`**：`60 = 2²·3·5 → {2,3,5}`、`45 = 3²·5 → {3,5}` ⇒ 共享 `{3,5}` 两条（不进张力）、只在 60 有 `{2}`（1 条）、只在 45 有 0 条 ⇒ `τ(60→45) = +1`，`τ(45→60) = −1`。
  - **四个对照**：`(12,18) = 0`（支撑完全相同）、`(2,3) = 0`（互素但一样陌生）、`(30,7) = +2`（互素但 30 多两条）—— 要害：**它量的不是「像不像」，是「谁比谁多」**。
  - **为什么能算**：分解 → 数三种条 → 相减。有限、可判定、无公式、无极限、无参数。
- **机器核对**：`Nods/Theories/Tension.lean` §10 新增五个例子（`ex_60_45` / `ex_45_60` / `ex_12_18` / `ex_2_3` / `ex_30_7`），与文档表一一对应；现 44 定理，`lake build Nods` 0 sorry 0 warning。
- **审计口径（诚实标注）**：这几个**具体数字**的例子走 `native_decide`，依赖 `Lean.ofReduceBool`（native 求值的标准信任公理）；**一般定理**不需要它（只依赖 `propext / Quot.sound`）。

## [2026-10-12] 张力计数法 TCM-2 | 收尾：权威表统一 + 其它逼出路线 + 刚性

- **收尾（leo 定的第 1 步）**：`tension-counting.md` 页首新增「**当前公理表（权威版 · TCM-2）**」，旧的 TCM-0 五条标注为**已被取代**（只作演进记录）—— 文档里不再并存两套说法。
- **严密性收紧（§9）**：`Nods/Theories/Tension.lean` 仍 0 sorry 0 warning（现 39 条定理）。
  - `grade_linear_gen`：张力差的线性形式，**不假设 T5**。
  - `form_up_to_scale'`：形状的逼出**不需要 T5** —— T4′ 已单独杀掉共享坐标，T3b 保证刻度非零。T5 的活只是管 `(K, L)` 这一对。
  - `kernel_forces`：**「核路」** —— 不靠 T3b，而是**把要发现的临界流形直接写进公理**（`crit u ↔ |S∖T| = |T∖S|`）+ 一个归一值 ⇒ 同一个 τ。
  - `scale_free_without_bound`：无「计数界」时只剩整数刻度自由（`doubleTension`，`c = 2` 反模型）⇒ 形状与刻度是两件事。
- **刚性（NODS 意义的最小性）**：`two_solutions` 证满足公理的张力**恰两个**（`τ` 与 `−τ`）；`forced_grade_swap` + `swapProfile_involutive` + `swap_nontrivial` 证二者互为「反着读」且该对合非平凡 ⇒ 解集两点、商掉取向是单点 = `IsMinimal`。
- **哪条路被否**：`not_leibniz` —— 要求乘法性 `τ(a,bc) = τ(a,b) + τ(a,c)` 得不到我们的 τ（`a=2,b=3,c=5` 时 `−1 ≠ 0`）⇒「乘法性」不是逼出张力的替代路线，是**另一个对象**。
- **结论**：逼出张力的方式**不唯一**（T3b 路 / 核路都到同一 τ），但都到同一个对象；刚性成立 ⇒ 公理搭建收尾。
- **审计**：新定理 `#print axioms` 只剩 `[propext, Quot.sound]`（部分含 `Classical.choice` / `Lean.ofReduceBool`），无 `sorryAx`。

## [2026-10-12] 张力计数法 TCM-1 | 最小化审计：公理表压到六条

- **再压一轮（leo 定的第 1 步）**：`Nods/Theories/Tension.lean` §7–8 新增（仍 0 sorry 0 warning，已接主链）。
- **分工定理**（回答了「T6/T7 能否合并」）：
  - `form_up_to_scale`：T5 + T4′ + T3b ⇒ τ = `c · (|S∖T| − |T∖S|)`（`c ≠ 0`）—— **形状被完全逼出，只留一个整数单位**。
  - `unit_fixes_scale`：再加 T7 ⇒ `c = ±1` —— **T7 唯一的工作就是定单位**。
  - ⇒ T6（可加，管形状）与 T7（单位，管刻度）**不能合并**：两件事正交。
- **单位表可换写法**：`Unit_of_bound` / `Bound_of_unit` 合证「T7（系数 ∈ {0,1}）」与「计数界 `0 ≤ K,L ≤ 总条数`」在 T5 下**等价** ⇒ 公理表只写「力**数不出比东西本身更多的条**」，T7 降为定理。
- **独立性表（反模型法，HIBS 第 8 步）**：每条公理都给反模型 ——
  - T3a **冗余**（`nontrivialCrit_free`）；T5 的 grade 部分**冗余**（`diagonal_grade_zero`：T4′ 已蕴含对角差为零）。
  - T3b **不可省**（`T3b_needed`：`K = L = 0` 满足其余，张力处处为零）。
  - T4′ **独立**（`T4'_independent`：`K = |S∖T| + |T∖S|`、`L = 0` 满足 T5/T6/T7/T3b，却是个对称「距离」而不是力）。
  - T6 **独立**（`additivity_needed`：`|S∖T|² − |T∖S|²` 满足其余各条，却不可加）。
  - T5 不可省（`T5_needed`：否则同一个 τ 可由不同 `(K,L)` 对给出）。
- **压出来的公理表（6 条）**：T1 直接性 + T2 二分力 + T6 计数（可加 且 `0 ≤ K,L ≤ 总条数`）+ T4′ 反号 + T5 自零 + T3b 非全。其中 **T4′ 是把「距离」变成「力」的那一条**。
- **审计**：新定理 `#print axioms` 只剩 `[propext, Quot.sound]`（部分含 `Classical.choice`），无 `sorryAx`。

## [2026-10-12] 张力计数法 TCM-1 | 判别公理 + 逼出定理：τ 不再是记号

- **目标纠偏（leo）**：先完成公理搭建，不直接走黎曼函数 —— 本阶段只做「让张力被逼出来」。
- **`Nods/Theories/Tension.lean` §5–6 新增**（仍 `lake build Nods` 0 sorry 0 warning，已接主链）：加判别公理，把 τ 逼成唯一对象。
  - `profile`：数对的三条计数 `(共享, a独有, b独有)`；`AddTension`：两个力 = 剖面的**可加**映射（`→+ ℤ`）—— T6 计数公理的形式化（逐素数计数、不加权）。
  - `K_linear` / `L_linear`：把「可加」落成「线性」—— 每多一条素数多固定一份力，T6 的确切内容。
  - `grade_linear`：T5 自零的推论 —— **共享条数整个掉出张力差的视野**，张力只看见两条「独有」计数。
  - **`forced_unique`（主定理）**：T5 + T7（单位：系数 ∈ {0,1}）+ T4′（必须反号）+ T3b（非全）⇒ τ 只能是 `|S∖T| − |T∖S|` 或其反号，**没有第三种**。
  - `forcedTension_axioms` + `forcedTension_to_dirTension`：该对象存在，且读回数对**正是 `dirTension`**。
  - 最小化：`nontrivialCrit_free` 证 T3a 是**定理**而非公理；`T5_needed` 证 T5 不可省（同一个 τ 可由不同 `(K,L)` 对给出）。
- **关键改动**：`T4 允许有向` → **`T4′ 必须反号`** —— 这一条是逼出唯一性的开关。
- **与 R→C 同型**：`(ℕ, K=|S∖T|)` 与 `(ℕ, K=|T∖S|)` 是同一载体的两个极小扩张，唯一同构（就是「反着读」）。TCM 由此从「我选了一个记号」升为「被迫 + 刚性」。
- **审计**：`#print axioms NODS.AddTension.forced_unique` → `[propext, Classical.choice, Quot.sound]`，无 `sorryAx`。
- **暂缓**：`O-TCM-canon`（ℂ / ζ）—— 按 leo 指示，先完成公理搭建。

## [2026-10-12] 张力计数法 TCM-0 | Lean 形式化：T5 反例 + 临界流形不唯一

- **新文件 `Nods/Theories/Tension.lean`**（已接主链 `Nods.lean`；`lake build Nods` 全绿 0 warning 0 sorry；`#print axioms` 无 `sorryAx`）：把 TCM-0 的 ℕ 判定从 prose 落成**机器检查**的定理。
  - `Tension D` 结构只含 T1（`K`/`L` 仅吃两个数）+ T2（`grade := K − L`）；T3 / T3′（非平凡临界）/ T4 / T5 做成谓词，于是「实例是否满足某条公理」本身可证。
  - `metric_not_nontrivial`（**Lemma 1 度量障碍**）：单幅度 `τ = f∘d`（`d` 忠实、`f` 只在 0 取零）⇒ 临界流形恒为对角线 ⇒ metric / 序 / 整除三条借来的结构都承载不了 T3′ —— 把「借来的结构失效」从断言升为定理。
  - `radTension_violates_T5`（**新发现**）：`K = |S∩T|`、`L = |SΔT|` 在 `a = b` 时给 `T_grade = ω(a) ≠ 0` —— 页面 §实例化 1 **违反公理 T5**；因算例全取 `a ≠ b`，此前未暴露。两条出路已写入页面（改 T5 语义，或把 `L` 改为含自项定义如 `|S∪T|`）。
  - `crit_manifold_not_unique`（**核心负结论**）：`(6,10)` 在 `dirTension` 下临界、在 `symTension` 下不临界 —— 两个**都满足 T5 + T3′** 的 intrinsic 实例给出**不同临界流形** ⇒ ℕ 上 `IsMinimal` 机器证伪；不唯一的是中心对象本身，不只是函数取值。
  - `nods_verdict_nat` 汇总，结论与上一条一致且更硬：ℕ 需求 = `solved`（非 gap），`novelty = 0`。
- **审计口径**：`#print axioms NODS.nods_verdict_nat` → `[propext, Classical.choice, Lean.ofReduceBool, Quot.sound]`，无 `sorryAx`。

## [2026-10-12] 张力计数法 TCM-0 | 缺口分析：ℕ 为 solved 非 gap

- **新概念页 `tension-counting.md`（draft）**：发明「数字自身张力」的极简公理系统 `TCM-0`（5 条：直接性 / 二分力 / 临界流形 / 方向性 / 退化），四数域实例化（ℕ 素因子 / ℤ 符号 / ℝ 连分数 / ℂ 临界线）。
- **诚实缺口论证（关键）**：对 ℕ 实例化跑 NODS `HasSolution` 检查 —— 素数、`rad`、整除、素因子集、K/L/T 全部在 (ℕ,+,·) 内一阶可定义 → T(a,b) 在现有结构**同一载体**上即可承载 → **判定为 `solved`，不是 `gap`**。存在性层面新颖性 = 0；且张力定义不唯一 → `IsMinimal` 失败。结论：TCM-0 在 ℕ 上是**设计选择 / 记号**，非被迫对象，不得宣称发现。
- **转向 canonicity**：真正可能升级为「发现」的缺口是 **`O-TCM-canon`（ℂ）**——要求张力由 ζ 结构强制、Re=1/2 为唯一最大收敛轨迹；裸 ℂ 域/拓扑不强制此性质，唯 ζ 强制之。已写入页面与 `current-status.md`。
- **纪律价值**：本步避免了 NODS 黑名单第 1 条（把可解需求当缺口），保护了「发明」不被误认为「发现」。

## [2026-09-08] 论文顶刊标准扩写 | 双语发布 EN v1.2 / ZH v1.1（aiXiv，无 EAS）

- **顶刊标准扩写（leo 要求）**：内容从 436 行扩到 EN 855 / ZH 714 行。阅读流重排（摘要独立成文、主结果前置、路线图）、详略重分配（该详处：配方法/Cardano 替换推导、每定理 What-it-says+策略段、数字展览表 tab:exhibit、分支隐藏挠的 Remark、图引导段与新 caption；该略处：删模板残留、剪掉与后续工作重复的边界句）。新增：引言重写 + 相关工作子节、两条推论（cor:rootset-coset / cor:p-inj-Rpos）、后续工作节（复根全貌/形式化 Galois 墙/混合塔补齐/区间法数值根式——均声明未完成）。数学简洁性保持：不发明新定理，\Lean 标识符全部真实存在。
- **Skill 落库**：`topjournal-math-paper`（顶刊写作标准：single-pass 阅读流、重点分层、详略规则、自查清单、配子智能体扩写工作流）——以后写论文照此标准。
- **发布（版本更新，按新规无 EAS）**：
  - aiXiv EN：`aixiv.260907.000001` v1.1 → **v1.2**（id 1461，Under Review，public）——扩写版 PDF + 新摘要。
  - aiXiv ZH：`aixiv.260908.000008` v1.0 → **v1.1**（id 1462，Under Review，public）——中文镜像同步扩写。
  - 元数据模板两版摘要已同步（`aixiv_meta_radical_{en,zh}.json`）。
  - EAS 自本版本起停用（leo 决定：成本过高）；历史 attestation 记录保留在 `~/.hermes/eas-bind/README.md` 与旧 wiki 条目。

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
