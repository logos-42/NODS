/-
【理论层】振数坐标系：振动作为第一性本体
============================================

弦理论把「弦」当载体、「振动」当属性。leo 的反转：真正重要的是**振动**，
「弦」只是众多可振动载体之一。本文件把「振动」翻译成数学对象，并用已有的
TCM 公理体系（`AtomicReading` + 塌缩定理）把它逼成**坐标**：

  1. `Vibration` —— 振动结构：载体 X + 周期自映射 `step`（`step^[period x] x = x`）。
     载体可以是**任何类型** X：点、线、面、数 —— 一切皆可振（承接载体抽象）。
  2. `vibrationReading` —— 由振动结构给出读数：`size x = period x`（**振数**），
     `share x y =` 同轨道则共享整条周期，否则 0。
  3. `vibration_collapse` —— 塌缩定理：**振动张力 = 振数差**
     （`τ = period a − period b`，唯一到取向）。这是 TCM 公理（T6+T7+T4′+T3b，
     无需 T5）直接逼出来的 —— 振数不是选出来的记号，是被迫对象。
  4. 动力学：`step` 迭代 = 相位演化；不动点（`step x = x`）= 不振 = 临界；
     对合（周期 2）= **最小振动** —— 承接对合层（临界线 = 对合不动点）。
  5. 实例：点（Fin 2 交换，周期 2）/ 线（Fin 3 循环移位，周期 3）/
     面（Fin 2 × Fin 3 双振子，周期 6）/ 数（ℚ 反转 `x ↦ 1 − x`，中心 `1/2`）。

坐标系规范逐条验证（详见 wiki `vibration-coords.md`）：
原点（不动点振数最小 = 1）、坐标（`vibCoord x = period x`）、
可加性（T6 ⟹ 张力线性）、维度（独立振子数）、
动力学（相位演化 + 不动点处张力为零）。

## 本文件给什么、不给什么（诚实边界）

给：**振数坐标系的公理化 + 塌缩** —— 振动作为对象，振数作为被逼出的坐标。
不给：**具体物理** —— 不声称「弦不存在」或「这就是弦论的替代」；
给的是数学层：任何载体上的振动都服从同一计数公理，振数差是唯一可观测的张力。
-/

import Nods.Theories.TensionReading
import Nods.Theories.TensionDuality
import Nods.Theories.TensionOptimal

namespace NODS

/- ------------------------------------------------------------------ -/
/- 1. 振动结构                                                         -/
/- ------------------------------------------------------------------ -/

/-- **振动结构**：载体 `X` + 一个周期自映射 `step`（振动一步 = 相位推进一位）。
    每个点 `x` 有一个**振数** `period x`（轨道长度 = 振动周期）：
    `step` 迭代 `period x` 次回到 `x`，且周期是轨道不变量。
    载体可以是任何类型 —— 点、线、面、数，一切皆可振。 -/
structure Vibration (X : Type*) where
  /-- 振动一步（时间演化算子） -/
  step : X → X
  /-- 振数：每个点的振动周期（轨道长度 = 振动条数） -/
  period : X → ℕ
  /-- 周期为正 -/
  period_pos : ∀ x, 0 < period x
  /-- 周期律：迭代 `period x` 步回到自身 -/
  step_period : ∀ x, step^[period x] x = x
  /-- 周期是轨道不变量：沿轨道走多少步，振数不变 -/
  period_invariant : ∀ x k, period (step^[k] x) = period x

namespace Vibration

variable {X : Type*}

/-- **相位**：振动在时刻 `k` 的位置（`k = 0` 是初始相位）。
    这是「动力学」的第一个对象：时间 = 轨道的脚步数。 -/
def phase (V : Vibration X) (k : ℕ) (x : X) : X := V.step^[k] x

/-- 相位演化：走一步 = 相位推进一位。 -/
theorem phase_succ (V : Vibration X) (k : ℕ) (x : X) :
    V.phase (k + 1) x = V.step (V.phase k x) := by
  exact Function.iterate_succ_apply' V.step k x

end Vibration

/- ------------------------------------------------------------------ -/
/- 2. 轨道与读数：振数进入 TCM                                       -/
/- ------------------------------------------------------------------ -/

/-- **同轨道**：`y` 在 `x` 的一个周期内可达（`k ≤ period x`；`k = period x` 时就是
    `step^period x x = x` 自己，故仍同轨道）。共享振动 = 落在同一条轨道上。 -/
def SameOrbit {X : Type*} (V : Vibration X) (x y : X) : Prop :=
  ∃ k : ℕ, k ≤ V.period x ∧ V.step^[k] x = y

/-- 迭代指数可加：`f^[m+n] x = f^[m] (f^[n] x)`。 -/
theorem iterate_add_len {X : Type*} (f : X → X) (m n : ℕ) (x : X) :
    f^[m + n] x = f^[m] (f^[n] x) := by
  exact congrFun (Function.iterate_add f m n) x

/-- 同轨道是对称的：若 `y = step^k x`，则 `x = step^(period x − k) y`
    （靠周期律补足剩下的步数；不需要 `step` 可逆）。 -/
theorem same_orbit_comm {X : Type*} (V : Vibration X) {x y : X}
    (h : SameOrbit V x y) : SameOrbit V y x := by
  rcases h with ⟨k, hk, hxy⟩
  refine ⟨V.period x - k, ?_, ?_⟩
  · -- 需证 V.period x - k ≤ V.period y；先看 x 侧的 period 与 y 的关系
    -- 因 y = step^k x，有 period y = period x（周期不变量）
    have hp : V.period y = V.period x := by
      rw [← hxy]
      exact V.period_invariant x k
    rw [hp]
    omega
  · rw [← hxy]
    -- 目标: (V.step)^[V.period x - k] (V.step^[k] x) = x
    -- 把指数合并: (period x - k) + k = period x
    have hsub : V.period x - k + k = V.period x := Nat.sub_add_cancel hk
    rw [← iterate_add_len V.step (V.period x - k) k]
    rw [hsub, V.step_period x]

/-- 同轨道的两个点共享同一个振数（周期是轨道不变量）。 -/
theorem same_orbit_period {X : Type*} (V : Vibration X) {x y : X}
    (h : SameOrbit V x y) : V.period x = V.period y := by
  rcases h with ⟨k, hk, hxy⟩
  rw [← hxy]
  exact (V.period_invariant x k).symm
/-- **振动读数**：把振动结构喂给 TCM 的 `AtomicReading` ——
    `size x = period x`（振数），`share x y =` 同轨道则共享整条周期、否则 0。
    ⇒ 振数从此进入已有的公理体系，下面的塌缩定理归它管。
    注意 `SameOrbit` 需要 `Decidable`，因为 `share` 是逐点定义；实际载体
    （ℕ 上的循环、ℚ 上的反转）都带 `DecidableEq`，见实例。 -/
noncomputable def vibrationReading {X : Type*} (V : Vibration X) :
    AtomicReading X where
  size x := V.period x
  share x y := by
    classical
    exact if SameOrbit V x y then V.period x else 0
  share_le_size := by
    classical
    intro a b
    by_cases h : SameOrbit V a b <;> simp [h]
  share_comm := by
    classical
    intro a b
    by_cases h : SameOrbit V a b
    · have hb : SameOrbit V b a := same_orbit_comm V h
      have hp : V.period a = V.period b := same_orbit_period V h
      simp [h, hb, hp]
    · have hb : ¬ SameOrbit V b a := by
        intro hh
        exact h (same_orbit_comm V hh)
      simp [h, hb]
  share_self := by
    classical
    intro a
    have h0 : 0 ≤ V.period a := Nat.zero_le _
    have hsa : SameOrbit V a a := ⟨0, h0, rfl⟩
    simp [hsa]

/- ------------------------------------------------------------------ -/
/- 3. 主定理：振动张力 = 振数差（塌缩）                                -/
/- ------------------------------------------------------------------ -/

/-- **振动塌缩（主定理）**：在振动读数上，满足 TCM 公理（T6+T7+T4′+T3b）的
    张力只能是**振数差** `period a − period b`（或反号）—— 没有第三种可能。

    这就是「振数」是被迫对象的意思：不是我们选了「用周期当坐标」，
    而是任何满足计数公理的振动张力，都只能是振数差。 -/
theorem vibration_collapse {X : Type*} (V : Vibration X) (τ : AddTension)
    (h7 : τ.Unit) (h4 : τ.Reciprocal) (h3b : τ.NonfullCrit) (a b : X) :
    τ.grade ((vibrationReading V).toProfile a b) =
        ((V.period a : ℕ) : ℤ) - ((V.period b : ℕ) : ℤ)
      ∨ τ.grade ((vibrationReading V).toProfile a b) =
        (((V.period b : ℕ) : ℤ) - ((V.period a : ℕ) : ℤ)) := by
  exact AtomicReading.collapse_four (vibrationReading V) τ h7 h4 h3b a b

/-- 同振数的两个振动体之间张力为零 —— 振数相同 = 振动平衡。 -/
theorem vibration_same_period_balanced {X : Type*} (V : Vibration X) (τ : AddTension)
    (h7 : τ.Unit) (h4 : τ.Reciprocal) (h3b : τ.NonfullCrit) (a b : X)
    (h : V.period a = V.period b) :
    τ.grade ((vibrationReading V).toProfile a b) = 0 := by
  rcases vibration_collapse V τ h7 h4 h3b a b with h' | h'
  · rw [h', h]; ring
  · rw [h', h]; ring

/- ------------------------------------------------------------------ -/
/- 4. 动力学：相位演化 · 不动点 = 不振 = 临界                          -/
/- ------------------------------------------------------------------ -/

/-- 振数 = 1 ⟹ 不动点（不振：`step x = x`，相位不再推进）。 -/
theorem period_one_fixed {X : Type*} (V : Vibration X) (x : X)
    (h : V.period x = 1) : V.step x = x := by
  have h1 : V.step^[1] x = V.step x := by rfl
  rw [← h1]
  rw [← h]
  exact V.step_period x

/-- **不动点处张力为零**：不振的振动体（`step x = x`）与「下一步的自己」无张力。
    —— 临界线在振动语言里的样子：临界 = 不振。 -/
theorem fixed_point_balanced {X : Type*} (V : Vibration X) (τ : AddTension)
    (h7 : τ.Unit) (h4 : τ.Reciprocal) (h3b : τ.NonfullCrit) (x : X)
    (hfix : V.step x = x) :
    τ.grade ((vibrationReading V).toProfile x (V.step x)) = 0 := by
  rw [hfix]
  exact vibration_same_period_balanced V τ h7 h4 h3b x x rfl

/- ------------------------------------------------------------------ -/
/- 5. 最小振动 = 对合（周期 2 的往返）                                -/
/- ------------------------------------------------------------------ -/

/-- **最小振动 = 对合**：`ι∘ι = id`，周期 2 的往返（不动点振数 1 =不振）。
    对合是**最小**的非平凡振动 —— 轨道只有两种：2-元往返 / 1-元不动点。
    `period` 用 `if ι x = x` 判定不动点，需要经典可判定，故标 `noncomputable`。 -/
noncomputable def involutionVibration {X : Type*} (ι : X → X) (hι : Function.Involutive ι) :
    Vibration X := by
  classical
  exact
    { step := ι
      period := fun x => if ι x = x then 1 else 2
      period_pos := by
        intro x
        by_cases h : ι x = x <;> simp [h]
      step_period := by
        intro x
        by_cases h : ι x = x
        · simp [h]
        · have h2 : ι^[2] x = x := by
            change ι (ι x) = x
            exact hι x
          simp [h, h2]
      period_invariant := by
        intro x k
        by_cases hfix : ι x = x
        · have hiter : ι^[k] x = x := by
            induction k with
            | zero => rfl
            | succ k ih =>
              rw [Function.iterate_succ_apply']
              rw [ih, hfix]
          simp [hiter, hfix]
        · have hnf : ∀ k, ι (ι^[k] x) ≠ ι^[k] x := by
            intro k
            induction k with
            | zero => exact hfix
            | succ k ih =>
              rw [Function.iterate_succ_apply']
              rw [hι (ι^[k] x)]
              exact ih.symm
          have hnfx : ι (ι^[k] x) ≠ ι^[k] x := hnf k
          -- 目标: (if ι (ι^[k] x) = ι^[k] x then 1 else 2) = (if ι x = x then 1 else 2)
          rw [if_neg hnfx, if_neg hfix] }

/-- 不动点是振数最小的点（振数 = 1 = 原点 / 不振）。 -/
theorem fixed_point_min_period {X : Type*} {ι : X → X} (hι : Function.Involutive ι)
    (x : X) (hfix : ι x = x) : (involutionVibration ι hι).period x = 1 := by
  simp [involutionVibration, hfix]

/- ------------------------------------------------------------------ -/
/- 6. 实例：点 / 线 / 数 / 面                                        -/
/- ------------------------------------------------------------------ -/

/-- 两点的交换振动：`0 ↔ 1`，周期 2 —— 最小的非平凡振动，**不需要弦**。 -/
def swapFin2 : Fin 2 → Fin 2 := fun i => if i = 0 then 1 else 0

theorem swapFin2_involutive : Function.Involutive swapFin2 := by
  intro i
  fin_cases i <;> simp [swapFin2]

/-- **点振动**：两个点彼此交换 —— 振动的东西是「点」，不是线。 -/
noncomputable def pointVibration : Vibration (Fin 2) := involutionVibration swapFin2 swapFin2_involutive

theorem pointVibration_period_zero : pointVibration.period 0 = 2 := by
  have hne : swapFin2 0 ≠ 0 := by
    simp [swapFin2]
  simp [pointVibration, involutionVibration, swapFin2, hne]

/-- 三点的循环移位（线振动）：`0 → 1 → 2 → 0`，周期 3。 -/
def shiftFin3 : Fin 3 → Fin 3 := fun i => (i + 1)

theorem shiftFin3_period (x : Fin 3) : shiftFin3^[3] x = x := by
  fin_cases x <;> simp [shiftFin3]

/-- **线振动**：一条「线」（3 个点排成环）整体循环 —— 载体是线，振动照常。 -/
def lineVibration : Vibration (Fin 3) where
  step := shiftFin3
  period := fun _ => 3
  period_pos := by intro x; norm_num
  step_period := by intro x; exact shiftFin3_period x
  period_invariant := by intro x k; rfl

theorem lineVibration_period (x : Fin 3) : lineVibration.period x = 3 := by rfl

/-- **数振动**：数自身在反转对合 `x ↦ 1 − x` 下来回振。
    不动点 = 中心 = `1/2`（振数 1，不振）；其余数振数 2。
    —— 这就是对合层里 `Re = 1/2` 的形状：临界线 = 振动的不动点。 -/
noncomputable def numVibration : Vibration ℚ := involutionVibration (revQ 1) (revQ_involutive 1)

theorem numVibration_center : numVibration.period (1 / 2 : ℚ) = 1 := by
  unfold numVibration involutionVibration revQ
  norm_num

theorem numVibration_off_center {x : ℚ} (h : x ≠ 1 / 2) : numVibration.period x = 2 := by
  have hne : revQ 1 x ≠ x := by
    intro hh
    unfold revQ at hh
    apply h
    linarith
  simp [numVibration, involutionVibration, hne]

/-- 中心（`1/2`）处张力为零：中心 = 不振 = 临界 —— `Re = 1/2` 的振动读法。 -/
theorem numVibration_center_balanced (τ : AddTension) (h7 : τ.Unit) (h4 : τ.Reciprocal)
    (h3b : τ.NonfullCrit) :
    τ.grade ((vibrationReading numVibration).toProfile (1 / 2 : ℚ)
      (revQ 1 (1 / 2 : ℚ))) = 0 := by
  have hfix : revQ 1 (1 / 2 : ℚ) = 1 / 2 := by
    unfold revQ
    norm_num
  exact fixed_point_balanced numVibration τ h7 h4 h3b (1 / 2 : ℚ) hfix

/- 面 = 两个独立振子的乘积：step 在两个坐标上分别走，振数 = 两方向振数之积 -/

/-- 迭代作用于积载体 = 分量各自迭代。 -/
theorem iterate_prod {X Y : Type*} (f : X → X) (g : Y → Y) (n : ℕ) (a : X) (b : Y) :
    (fun p : X × Y => (f p.1, g p.2))^[n] (a, b) =
      (f^[n] a, g^[n] b) := by
  induction n with
  | zero => rfl
  | succ n ih =>
    ext <;> simp [Function.iterate_succ_apply', ih]

/-- 若 `f` 在 `p` 步回到 `a`，则在 `p*k` 步也回到 `a`（周期律的倍数闭包）。 -/
theorem iterate_mul_fixed {X : Type*} (f : X → X) {a : X} (p k : ℕ)
    (h : f^[p] a = a) : f^[p * k] a = a := by
  induction k with
  | zero => simp
  | succ k ih =>
    calc
      f^[p * (k + 1)] a = f^[p * k + p] a := by rw [Nat.mul_succ]
      _ = f^[p * k] (f^[p] a) := by rw [iterate_add_len f (p * k) p]
      _ = f^[p * k] a := by rw [h]
      _ = a := ih

/-- **面振动 = 两个独立振子的乘积**：`step` 在两坐标上分别走，
    振数 = 两方向振数之积。 ⇒ 振动的东西可以是**面**（积载体）。 -/
def productVibration {X Y : Type*} (V : Vibration X) (W : Vibration Y) :
    Vibration (X × Y) where
  step := fun p => (V.step p.1, W.step p.2)
  period := fun p => V.period p.1 * W.period p.2
  period_pos := by
    intro p
    exact Nat.mul_pos (V.period_pos p.1) (W.period_pos p.2)
  step_period := by
    intro p
    rw [show (fun q : X × Y => (V.step q.1, W.step q.2))^[V.period p.1 * W.period p.2] p =
        (V.step^[V.period p.1 * W.period p.2] p.1,
         W.step^[V.period p.1 * W.period p.2] p.2)
        from iterate_prod V.step W.step (V.period p.1 * W.period p.2) p.1 p.2]
    ext
    · exact iterate_mul_fixed V.step (V.period p.1) (W.period p.2) (V.step_period p.1)
    · have hw : W.step^[W.period p.2 * V.period p.1] p.2 = p.2 :=
        iterate_mul_fixed W.step (W.period p.2) (V.period p.1) (W.step_period p.2)
      rw [Nat.mul_comm]
      exact hw
  period_invariant := by
    intro p k
    rw [show (fun q : X × Y => (V.step q.1, W.step q.2))^[k] p =
        (V.step^[k] p.1, W.step^[k] p.2)
        from iterate_prod V.step W.step k p.1 p.2]
    simp [V.period_invariant p.1 k, W.period_invariant p.2 k]

/-- **面振动实例**：`Fin 2 × Fin 3`（2×3 的格点面），x 方向两点交换、y 方向三点循环，
    振数 = 2 × 3 = 6。 -/
noncomputable def planeVibration : Vibration (Fin 2 × Fin 3) :=
  productVibration pointVibration lineVibration

theorem planeVibration_period (p : Fin 2 × Fin 3) : planeVibration.period p = 6 := by
  rcases p with ⟨i, j⟩
  have hne : swapFin2 i ≠ i := by
    fin_cases i <;> simp [swapFin2]
  simp [planeVibration, productVibration, pointVibration, lineVibration,
        involutionVibration, hne]

/- ------------------------------------------------------------------ -/
/- 7. 振数坐标：以振动为模式的坐标系                                  -/
/- ------------------------------------------------------------------ -/

/-- **振数坐标**：对象 `x` 的坐标 = 它的振数 `period x`。
    不动点（不振）是原点，振数 = 1。 -/
def vibCoord {X : Type*} (V : Vibration X) (x : X) : ℕ := V.period x

/-- **振动张力 = 坐标差**（坐标系语言的塌缩定理）：
    两个振动体之间的张力就是它们振数坐标的差（或反号）。
    —— 这正是「以振动为模式的坐标系」：坐标 = 振数，距离/力 = 坐标差。 -/
theorem vib_tension_is_coord_diff {X : Type*} (V : Vibration X) (τ : AddTension)
    (h7 : τ.Unit) (h4 : τ.Reciprocal) (h3b : τ.NonfullCrit) (a b : X) :
    τ.grade ((vibrationReading V).toProfile a b) =
        ((vibCoord V a : ℕ) : ℤ) - ((vibCoord V b : ℕ) : ℤ)
      ∨ τ.grade ((vibrationReading V).toProfile a b) =
        (((vibCoord V b : ℕ) : ℤ) - ((vibCoord V a : ℕ) : ℤ)) := by
  simpa [vibCoord] using vibration_collapse V τ h7 h4 h3b a b

end NODS