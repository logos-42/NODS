/-
【理论层】振数坐标系 · 几何坐标化（离散极坐标层）
================================================

leo 方向：`metric_not_nontrivial` 堵住的只是「张力 = 距离的纯函数」
（零集 = 对角线 ⟹ 承载不了非平凡临界流形）。它**不堵**「给坐标配几何」。

几何坐标化 = 保留张力为力（振数坐标差，TCM 塌缩），同时在模空间上
把振数坐标变成真正的极坐标：

  半径   r  = period x        （振数：被有限性/显式周期逼出的轨道条数）
  角度   θ  = phaseFrac x     （相位分数：相位步数 / 周期 —— 轨道圆上的
                                 比例位置，模 1；连续化即 2π·θ 弧度）

几何内容（全部从已有公理长出，无新公理）：

  0. 相位分数 θ = k/p ∈ ℚ，0 ≤ θ < 1（phaseIdx_lt + period_pos）
  1. 均匀旋转：step 一步 = 角度推进 1/p（轨道是正多边形 / 均匀圆，
     phaseIdx_step 的几何读法）
  2. 坐标可分辨：同轨道窗口内，相位分数相同 ⟹ 同一点
     （phase_position_unique 的几何读法）
  3. 几何化桥：|张力| = |振数差| = 径向距离（vib_tension_is_coord_diff
     取绝对值）—— 力的量值就是半径差
  4. 圆距离 circleDist（模 1 角距） + 组合极坐标度量 polarDist
     （径向 + 角向；对称 / 自零 / 分离，三角不等式留 v2）

诚实边界：
  · 相位分数是 ℚ（离散圆，正 N 边形），连续弧度（ℝ、U(1)、sin）留 v2；
    ħ = 每弧度角动量 接的是「2π·phaseFrac = 弧度」这个连续化极限。
  · polarDist 的三角不等式需要 min 的 ℚ 引理集，v2 补。
  · 每条轨道需代表元 rep + PhaseLink 证明（与 §4.5 PhaseLink 的
    「局部规范版本，不重新选轨道代表元」精神一致）。
-/

import Nods.Theories.Vibration

namespace NODS
namespace PeriodicDynamics

/- ------------------------------------------------------------------ -/
/- 1. 相位分数：相位步数归一化为轨道圆上的角度（模 1）                -/
/- ------------------------------------------------------------------ -/

/-- **相位分数（角度坐标）**：`phaseIdx / period` —— 相位在轨道圆上的
    比例位置（模 1）。连续化后乘 2π 就是弧度。 -/
noncomputable def phaseFrac (V : PeriodicDynamics X) (hmin : MinimalPeriod V)
    {x y : X} (h : PhaseLink V x y) : ℚ :=
  (phaseIdx V hmin h : ℚ) / (V.period x : ℚ)

/-- 相位分数非负：`0 ≤ k/p`（k ∈ ℕ，p > 0）。 -/
theorem phaseFrac_nonneg (V : PeriodicDynamics X) (hmin : MinimalPeriod V)
    {x y : X} (h : PhaseLink V x y) : 0 ≤ phaseFrac V hmin h := by
  unfold phaseFrac
  exact div_nonneg (by exact_mod_cast Nat.zero_le (phaseIdx V hmin h))
    (by exact_mod_cast le_of_lt (V.period_pos x))

/-- 相位分数小于 1：`k/p < 1`（k < p，phaseIdx_lt）。角度在圆上，模 1。 -/
theorem phaseFrac_lt_one (V : PeriodicDynamics X) (hmin : MinimalPeriod V)
    {x y : X} (h : PhaseLink V x y) : phaseFrac V hmin h < 1 := by
  unfold phaseFrac
  have hp : 0 < (V.period x : ℚ) := by exact_mod_cast V.period_pos x
  have hk : (phaseIdx V hmin h : ℚ) < (V.period x : ℚ) := by
    exact_mod_cast phaseIdx_lt V hmin h
  exact (div_lt_one hp).2 hk

/-- 自链：任何点都在自己的相位窗口内（`k = 0` 步）。 -/
theorem PhaseLink_self (V : PeriodicDynamics X) (x : X) : PhaseLink V x x := by
  refine ⟨0, V.period_pos x, ?_⟩
  rfl

/-- **原点相位 = 0**：自己看自己，相位分数为零（角度起点）。 -/
theorem phaseFrac_self (V : PeriodicDynamics X) (hmin : MinimalPeriod V) (x : X) :
    phaseFrac V hmin (PhaseLink_self V x) = 0 := by
  unfold phaseFrac
  have hspec := Classical.choose_spec (phase_link_unique V hmin (PhaseLink_self V x))
  have hk : 0 < V.period x ∧ (V.step : X → X)^[0] x = x := by
    constructor
    · exact V.period_pos x
    · rfl
  have h0 : 0 = phaseIdx V hmin (PhaseLink_self V x) := hspec.2 0 hk
  have hz : (phaseIdx V hmin (PhaseLink_self V x) : ℚ) = 0 := by
    exact_mod_cast h0.symm
  rw [hz]
  simp

/- ------------------------------------------------------------------ -/
/- 2. 均匀旋转：step 一步 = 角度推进 1/period（轨道是均匀圆）         -/
/- ------------------------------------------------------------------ -/

/-- 相位链的步进：`y` 在窗口内且 `k + 1 < period` ⟹ `step y` 也在窗口内。 -/
theorem PhaseLink_step (V : PeriodicDynamics X) (hmin : MinimalPeriod V)
    {x y : X} (h : PhaseLink V x y) (hk' : phaseIdx V hmin h + 1 < V.period x) :
    PhaseLink V x (V.step y) := by
  refine ⟨phaseIdx V hmin h + 1, hk', ?_⟩
  exact phaseIdx_step V hmin h

/-- **均匀旋转（主定理）**：走一步，角度精确推进 `1/period` 圈。
    轨道是正 N 边形 —— 相位坐标不是乱贴的，步进 = 定角旋转。 -/
theorem step_phase_advance (V : PeriodicDynamics X) (hmin : MinimalPeriod V)
    {x y : X} (h : PhaseLink V x y) (hk' : phaseIdx V hmin h + 1 < V.period x) :
    phaseFrac V hmin (PhaseLink_step V hmin h hk') =
      phaseFrac V hmin h + 1 / (V.period x : ℚ) := by
  have hstep : PhaseLink V x (V.step y) := PhaseLink_step V hmin h hk'
  have hspec := Classical.choose_spec (phase_link_unique V hmin hstep)
  have hk : phaseIdx V hmin h + 1 < V.period x ∧
      (V.step : X → X)^[phaseIdx V hmin h + 1] x = V.step y := by
    constructor
    · exact hk'
    · exact phaseIdx_step V hmin h
  have hidx : phaseIdx V hmin hstep = phaseIdx V hmin h + 1 :=
    (hspec.2 (phaseIdx V hmin h + 1) hk).symm
  unfold phaseFrac
  rw [hidx]
  push_cast
  ring

/- ------------------------------------------------------------------ -/
/- 3. 极坐标 + 可分辨性                                               -/
/- ------------------------------------------------------------------ -/

/-- **极坐标**：`(period y, phaseFrac x y)` = （半径, 角度）。
    第一坐标 = 振数（轨道条数 = 圆的大小），第二坐标 = 圆上的位置。 -/
noncomputable def polarCoord (V : PeriodicDynamics X) (hmin : MinimalPeriod V)
    {x y : X} (h : PhaseLink V x y) : ℕ × ℚ :=
  (V.period y, phaseFrac V hmin h)

/-- **角度可分辨**：同一窗口内相位分数相同 ⟹ 同一点。
    这是「坐标合法」的第一要求 —— 第二坐标不是重影。 -/
theorem phaseFrac_injective (V : PeriodicDynamics X) (hmin : MinimalPeriod V)
    {rep x y : X} (hx : PhaseLink V rep x) (hy : PhaseLink V rep y)
    (hθ : phaseFrac V hmin hx = phaseFrac V hmin hy) : x = y := by
  have hp0 : (V.period rep : ℚ) ≠ 0 := by exact_mod_cast ne_of_gt (V.period_pos rep)
  unfold phaseFrac at hθ
  have hk : phaseIdx V hmin hx = phaseIdx V hmin hy := by
    field_simp [hp0] at hθ
    exact_mod_cast hθ
  have hxspec := phaseIdx_spec V hmin hx
  have hyspec := phaseIdx_spec V hmin hy
  rw [hk] at hxspec
  exact hxspec.symm.trans hyspec

/-- **极坐标可分辨**：极坐标相同 ⟹ 同一点（角度分量已够；径向分量自动）。 -/
theorem polarCoord_injective (V : PeriodicDynamics X) (hmin : MinimalPeriod V)
    {rep x y : X} (hx : PhaseLink V rep x) (hy : PhaseLink V rep y)
    (hxy : polarCoord V hmin hx = polarCoord V hmin hy) : x = y := by
  have hθ : phaseFrac V hmin hx = phaseFrac V hmin hy := congrArg Prod.snd hxy
  exact phaseFrac_injective V hmin hx hy hθ

/- ------------------------------------------------------------------ -/
/- 4. 几何化桥：张力的量值 = 径向距离（半径差）                       -/
/- ------------------------------------------------------------------ -/

/-- **几何化桥（主定理）**：`|张力| = |振数差| = 径向距离`。
    TCM 塌缩给的是「力 = 坐标差」（符号未定）；取绝对值 ⟹
    力的量值就是半径差 —— 力与距离在量值上合一。 -/
theorem tension_abs_eq_radial_dist (V : PeriodicDynamics X) (τ : AddTension)
    (h7 : τ.Unit) (h4 : τ.Reciprocal) (h3b : τ.NonfullCrit) (a b : X) :
    |τ.grade ((vibrationReading V).toProfile a b)| =
      |((V.period a : ℕ) : ℤ) - ((V.period b : ℕ) : ℤ)| := by
  rcases vib_tension_is_coord_diff V τ h7 h4 h3b a b with h | h
  · rw [h]
    simp [vibCoord]
  · rw [h]
    simp [vibCoord]
    exact abs_sub_comm ((V.period b : ℕ) : ℤ) ((V.period a : ℕ) : ℤ)

/- ------------------------------------------------------------------ -/
/- 5. 圆距离：模 1 角距（ℚ 版，角度的度量）                          -/
/- ------------------------------------------------------------------ -/

/-- **圆距离**：圆上两点间的短弧（模 1）。`q1, q2 ∈ [0,1)` 时
    `min(|q1−q2|, 1−|q1−q2|)` —— 走短边，不走长边。 -/
def circleDist (q1 q2 : ℚ) : ℚ := min (|q1 - q2|) (1 - |q1 - q2|)

/-- 圆距离自零：同一点距离为零。 -/
theorem circleDist_self_zero (q : ℚ) : circleDist q q = 0 := by
  unfold circleDist
  simp

/-- 圆距离对称：短弧不分方向。 -/
theorem circleDist_symm (q1 q2 : ℚ) : circleDist q1 q2 = circleDist q2 q1 := by
  unfold circleDist
  rw [abs_sub_comm q1 q2]

/-- 圆距离非负（相位分数界内）：`|Δθ| < 1` ⟹ 两个候选都 ≥ 0。 -/
theorem circleDist_nonneg {q1 q2 : ℚ} (h1lo : 0 ≤ q1) (h1hi : q1 < 1)
    (h2lo : 0 ≤ q2) (h2hi : q2 < 1) : 0 ≤ circleDist q1 q2 := by
  unfold circleDist
  have hlt : |q1 - q2| < 1 := by
    rw [abs_lt]
    constructor <;> linarith
  exact le_min (abs_nonneg (q1 - q2)) (by linarith)

/-- **圆距离分离**：界内 ⟹ 距离为零 ⟺ 同一点（模 1 的圆上）。 -/
theorem circleDist_eq_zero_iff {q1 q2 : ℚ} (h1lo : 0 ≤ q1) (h1hi : q1 < 1)
    (h2lo : 0 ≤ q2) (h2hi : q2 < 1) : circleDist q1 q2 = 0 ↔ q1 = q2 := by
  constructor
  · intro h0
    unfold circleDist at h0
    have hlt : |q1 - q2| < 1 := by
      rw [abs_lt]
      constructor <;> linarith
    by_cases hle : |q1 - q2| ≤ 1 - |q1 - q2|
    · have hmin : min (|q1 - q2|) (1 - |q1 - q2|) = |q1 - q2| := min_eq_left hle
      rw [hmin] at h0
      exact sub_eq_zero.mp (abs_eq_zero.mp h0)
    · have hgt : 1 - |q1 - q2| < |q1 - q2| := by linarith
      have hmin : min (|q1 - q2|) (1 - |q1 - q2|) = 1 - |q1 - q2| :=
        min_eq_right (le_of_lt hgt)
      rw [hmin] at h0
      have : |q1 - q2| = 1 := by linarith
      linarith
  · intro h
    rw [h]
    exact circleDist_self_zero q2

/- ------------------------------------------------------------------ -/
/- 6. 组合极坐标度量：径向 + 角向                                     -/
/- ------------------------------------------------------------------ -/

/-- **极坐标度量**：同一代表元窗口内两点间距离 =
    径向距离（振数差）+ 圆距离（相位差）。 -/
noncomputable def polarDist (V : PeriodicDynamics X) (hmin : MinimalPeriod V)
    {rep x y : X} (hx : PhaseLink V rep x) (hy : PhaseLink V rep y) : ℚ :=
  |(V.period x : ℚ) - (V.period y : ℚ)| +
    circleDist (phaseFrac V hmin hx) (phaseFrac V hmin hy)

/-- 度量自零：`d(x,x) = 0`。 -/
theorem polarDist_self_zero (V : PeriodicDynamics X) (hmin : MinimalPeriod V)
    {rep x : X} (hx : PhaseLink V rep x) : polarDist V hmin hx hx = 0 := by
  unfold polarDist
  simp [circleDist_self_zero]

/-- 度量对称：`d(x,y) = d(y,x)`。 -/
theorem polarDist_symm (V : PeriodicDynamics X) (hmin : MinimalPeriod V)
    {rep x y : X} (hx : PhaseLink V rep x) (hy : PhaseLink V rep y) :
    polarDist V hmin hx hy = polarDist V hmin hy hx := by
  unfold polarDist
  rw [abs_sub_comm (V.period x : ℚ) (V.period y : ℚ)]
  rw [circleDist_symm]

/-- **度量分离**：`d(x,y) = 0 ⟺ x = y`。
    径向（振数差）与角向（圆距离）同时为零 ⟹ 同一点。
    三角不等式（min 引理集）留 v2。 -/
theorem polarDist_eq_zero_iff (V : PeriodicDynamics X) (hmin : MinimalPeriod V)
    {rep x y : X} (hx : PhaseLink V rep x) (hy : PhaseLink V rep y) :
    polarDist V hmin hx hy = 0 ↔ x = y := by
  constructor
  · intro h0
    unfold polarDist at h0
    have hθ1lo := phaseFrac_nonneg V hmin hx
    have hθ1hi := phaseFrac_lt_one V hmin hx
    have hθ2lo := phaseFrac_nonneg V hmin hy
    have hθ2hi := phaseFrac_lt_one V hmin hy
    have hc_nonneg :
        0 ≤ circleDist (phaseFrac V hmin hx) (phaseFrac V hmin hy) :=
      circleDist_nonneg hθ1lo hθ1hi hθ2lo hθ2hi
    have hrad : |(V.period x : ℚ) - (V.period y : ℚ)| = 0 := by
      nlinarith [abs_nonneg ((V.period x : ℚ) - (V.period y : ℚ)), hc_nonneg]
    have hc : circleDist (phaseFrac V hmin hx) (phaseFrac V hmin hy) = 0 := by
      nlinarith
    have hθ : phaseFrac V hmin hx = phaseFrac V hmin hy :=
      (circleDist_eq_zero_iff hθ1lo hθ1hi hθ2lo hθ2hi).mp hc
    exact phaseFrac_injective V hmin hx hy hθ
  · intro hxy
    subst hxy
    exact polarDist_self_zero V hmin hx

/- ------------------------------------------------------------------ -/
/- 7. 实例数值核对：点 / 线 / 数 —— 极坐标                 -/
/- ------------------------------------------------------------------ -/

/-- 线振动（周期 3）相位链：`0 → 1`。 -/
theorem line_phase_link_1 : PhaseLink linePeriodicDynamics 0 1 := by
  refine ⟨1, ?_, ?_⟩
  · decide
  · decide

/-- 线振动（周期 3）相位链：`0 → 2`。 -/
theorem line_phase_link_2 : PhaseLink linePeriodicDynamics 0 2 := by
  refine ⟨2, ?_, ?_⟩
  · decide
  · decide

/-- 线振动相位值：`phaseIdx 0 1 = 1`。 -/
theorem line_phase_idx_1 : phaseIdx linePeriodicDynamics line_minimal
    line_phase_link_1 = 1 := by
  have hspec := Classical.choose_spec
    (phase_link_unique linePeriodicDynamics line_minimal line_phase_link_1)
  have hk : 1 < linePeriodicDynamics.period 0 ∧
      (linePeriodicDynamics.step : Fin 3 → Fin 3)^[1] 0 = 1 := by
    decide
  have h1 : (1 : ℕ) = phaseIdx linePeriodicDynamics line_minimal
      line_phase_link_1 := hspec.2 1 hk
  exact h1.symm

/-- 线振动相位值：`phaseIdx 0 2 = 2`。 -/
theorem line_phase_idx_2 : phaseIdx linePeriodicDynamics line_minimal
    line_phase_link_2 = 2 := by
  have hspec := Classical.choose_spec
    (phase_link_unique linePeriodicDynamics line_minimal line_phase_link_2)
  have hk : 2 < linePeriodicDynamics.period 0 ∧
      (linePeriodicDynamics.step : Fin 3 → Fin 3)^[2] 0 = 2 := by
    decide
  have h2 : (2 : ℕ) = phaseIdx linePeriodicDynamics line_minimal
      line_phase_link_2 := hspec.2 2 hk
  exact h2.symm

/-- **点振动（周期 2）相位分数 = 1/2**：交换 `0 ↔ 1` 是半圈 ——
    对合 = 转 180°。 -/
theorem point_phase_frac : phaseFrac pointPeriodicDynamics point_minimal
    point_phase_link = 1 / 2 := by
  unfold phaseFrac
  rw [point_phase_idx]
  norm_num [pointPeriodicDynamics]

/-- **点振动极坐标 = (2, 1/2)**：半径 2（两个轨道点），角度半圈。 -/
theorem point_polar_coord : polarCoord pointPeriodicDynamics point_minimal
    point_phase_link = (2, 1 / 2) := by
  unfold polarCoord
  rw [point_phase_frac]
  simp [pointPeriodicDynamics]

/-- **线振动相位分数：三分之一圈与三分之二圈** —— 正三角形的两个顶点。 -/
theorem line_phase_frac_1 : phaseFrac linePeriodicDynamics line_minimal
    line_phase_link_1 = 1 / 3 := by
  unfold phaseFrac
  rw [line_phase_idx_1]
  norm_num [linePeriodicDynamics]

theorem line_phase_frac_2 : phaseFrac linePeriodicDynamics line_minimal
    line_phase_link_2 = 2 / 3 := by
  unfold phaseFrac
  rw [line_phase_idx_2]
  norm_num [linePeriodicDynamics]

/-- **线振动极坐标 = (3, 1/3)**：半径 3（三个轨道点），三分之一圈。 -/
theorem line_polar_coord_1 : polarCoord linePeriodicDynamics line_minimal
    line_phase_link_1 = (3, 1 / 3) := by
  unfold polarCoord
  rw [line_phase_frac_1]
  simp [linePeriodicDynamics]

/-- **均匀旋转实例**：线上走一步，角度从 1/3 推进到 2/3 圈
    （`hk'` = 这一步仍在周期窗口内）。 -/
theorem line_phase_advance_example
    (hk' : phaseIdx linePeriodicDynamics line_minimal line_phase_link_1 + 1 <
      linePeriodicDynamics.period 0) :
    phaseFrac linePeriodicDynamics line_minimal
      (PhaseLink_step linePeriodicDynamics line_minimal line_phase_link_1 hk') = 2 / 3 := by
  calc
    phaseFrac linePeriodicDynamics line_minimal
        (PhaseLink_step linePeriodicDynamics line_minimal line_phase_link_1 hk')
        = phaseFrac linePeriodicDynamics line_minimal line_phase_link_1
            + 1 / (linePeriodicDynamics.period 0 : ℚ) :=
        step_phase_advance linePeriodicDynamics line_minimal line_phase_link_1 hk'
    _ = 2 / 3 := by
        rw [line_phase_frac_1]
        norm_num [linePeriodicDynamics]

/-- 数振动（ℚ 反转）中心相位链：`1/2` 自己看自己。 -/
theorem num_phase_self : PhaseLink numPeriodicDynamics (1 / 2 : ℚ) (1 / 2 : ℚ) := by
  refine ⟨0, ?_, ?_⟩
  · rw [num_period_center]
    norm_num
  · rfl

/-- **中心相位分数 = 0**：不振（周期 1）的点在角度起点的原位 ——
    退化圆（半径 1、只有一个点）。 -/
theorem num_center_phase_frac : phaseFrac numPeriodicDynamics num_minimal
    num_phase_self = 0 := by
  unfold phaseFrac
  have hspec := Classical.choose_spec
    (phase_link_unique numPeriodicDynamics num_minimal num_phase_self)
  have hk : 0 < numPeriodicDynamics.period (1 / 2 : ℚ) ∧
      (numPeriodicDynamics.step : ℚ → ℚ)^[0] (1 / 2 : ℚ) = 1 / 2 := by
    constructor
    · rw [num_period_center]
      norm_num
    · rfl
  have h0 : 0 = phaseIdx numPeriodicDynamics num_minimal num_phase_self :=
    hspec.2 0 hk
  rw [← h0]
  simp

/-- **中心极坐标 = (1, 0)**：半径 1（退化圆），角度 0 —— 不振 = 原点。 -/
theorem num_center_polar_coord : polarCoord numPeriodicDynamics num_minimal
    num_phase_self = (1, 0) := by
  unfold polarCoord
  rw [num_center_phase_frac, num_period_center]

end PeriodicDynamics
end NODS
