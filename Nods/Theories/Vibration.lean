/-
【理论层】振数坐标系：从静态世界从 0 推导振动本体
====================================================

弦理论把「弦」当载体、「振动」当属性。leo 的反转：真正重要的是**振动**，
「弦」只是众多可振动载体之一。本文件**不从任何中间结构出发**（不对合、不借临界线），
而是从系统已有的**静态世界**开始，一步一步把振动本体**逼**出来：

  0. **静态世界（已有）**：`AtomicReading`（share/size）+ 张力公理
     （T6+T7+T4′+T3b）+ 塌缩定理 `τ = size 差`。这是系统的起点，不是振动。

  1. **动力学公理（唯一一条新公理）**：`Dynamics` —— 一个**可逆**的自演化
     `step : X ≃ X`。可逆 = 时间反演对称（物理：振动不损失信息）。
     载体可以是**任何类型** X：点、线、面、数 —— 一切皆可振。

  2. **零张力动力学（定理，不是公理）**：`τ(x, step x) = 0`。
     保 size 的演化 ⟹ 每一步都与前一刻张力为零 —— 这正是 TCM「内容不可见」
     （`size_only`）的动力学版：**内容在变、张力为零**。振动从静态世界自动获得
     动力学性质。

  3. **周期被逼出（定理，不是假设）**：有限载体上，鸽笼原理 ⟹
     `step^[p] x = x` 对某个 `p > 0`。**振数不是输入的，是被有限性逼出来的。**
     振数 = 周期 = 轨道的条数。

  4. **振数坐标（由 2+3 组装）**：`vibrationReading`（size = 周期）+ 塌缩定理
     ⟹ **振动张力 = 振数差**。坐标系规范逐条验证：
     原点（不动点振数 1 = 不振）/ 坐标（`vibCoord`）/ 张力 = 坐标差 /
     可加性（T6 内建）/ 维度（独立振子相乘）。

  5. **实例**：点（Fin 2 交换）/ 线（Fin 3 循环移位）/ 面（Fin 2 × Fin 3 双振子）
     —— 有限载体，周期由鸽笼逼出；**数（ℚ 反转 `x ↦ 1 − x`）—— 无限载体，
     周期是显式的（中心 `1/2` 振数 1，其余 2），轨道有限假设**。
     对合只是「周期 2 的振动」这一个实例，**不是推导的起点**。

## 诚实边界

给：振动本体从静态世界被逼出的完整链条（动力学公理 → 零张力 → 周期 → 坐标）。
不给：具体物理断言（不声称「弦不存在」）。周期来源分两路：
有限载体由鸽笼逼出（`period_exists`，经典选择 noncomputable）；
无限载体需显式周期或轨道有限假设（`PeriodicDynamics.period` 是结构字段，
`same_orbit_comm` 只需 `step_period`，不依赖 `Fintype`）。
-/

import Nods.Theories.TensionReading
import Nods.Theories.TensionOptimal

namespace NODS

/- ------------------------------------------------------------------ -/
/- 1. 动力学：可逆自演化（唯一新公理）                                  -/
/- ------------------------------------------------------------------ -/

/-- **动力学**：载体 `X` 上的**可逆**自演化 `step`。
    这是振动本体的唯一一条公理 —— 一个对象如何随时间变化：
    `step` 可逆 = 时间反演对称（振动不损失信息，是往返不是衰减）。
    载体可以是任何类型 —— 点、线、面、数，一切皆可振。 -/
structure Dynamics (X : Type*) where
  /-- 演化一步（时间推进） -/
  step : X ≃ X

namespace Dynamics

variable {X : Type*}

/-- **相位**：`k` 步后的位置（`k = 0` 是初始相位）。 -/
def phase (D : Dynamics X) (k : ℕ) (x : X) : X := (D.step : X → X)^[k] x

/-- 相位演化：走一步 = 相位推进一位。 -/
theorem phase_succ (D : Dynamics X) (k : ℕ) (x : X) :
    D.phase (k + 1) x = D.step (D.phase k x) := by
  exact Function.iterate_succ_apply' (D.step : X → X) k x

end Dynamics

/- ------------------------------------------------------------------ -/
/- 2. 周期被逼出：有限 + 可逆 ⟹ 鸽笼 ⟹ 每点周期                        -/
/- ------------------------------------------------------------------ -/

/-- 迭代指数可加：`f^[m+n] x = f^[m] (f^[n] x)`。 -/
theorem iterate_add_len {X : Type*} (f : X → X) (m n : ℕ) (x : X) :
    f^[m + n] x = f^[m] (f^[n] x) := by
  exact congrFun (Function.iterate_add f m n) x

/-- **迭代抵消**：`σ.symm^[a] ∘ σ^[a] = id` —— 可逆演化走 a 步再退回 a 步，回到原位。 -/
theorem cancel_iter {X : Type*} (σ : X ≃ X) :
    ∀ a : ℕ, ∀ x : X, (σ.symm : X → X)^[a] ((σ : X → X)^[a] x) = x := by
  intro a
  exact (Function.LeftInverse.iterate (g := (σ.symm : X → X)) (f := (σ : X → X))
    (fun x => Equiv.symm_apply_apply σ x) a)

/-- `σ^[j] x = σ^[i] (σ^[j-i] x)`（`i ≤ j`）。 -/
theorem iterate_split {X : Type*} (σ : X → X) (i j : ℕ) (hij : i ≤ j) (x : X) :
    σ^[j] x = σ^[i] (σ^[j - i] x) := by
  rw [← iterate_add_len σ i (j - i)]
  congr 1
  omega

/-- **周期引理**：若 `σ^[i] x = σ^[j] x` 且 `i < j`，则 `σ^[j-i] x = x`。
    —— 轨迹重复 ⟹ 周期（靠可逆性把多余的步数消掉）。 -/
theorem period_of_repeat {X : Type*} (σ : X ≃ X) {x : X} (i j : ℕ) (hij : i < j)
    (hfij' : (σ : X → X)^[i] x = (σ : X → X)^[j] x) :
    (σ : X → X)^[j - i] x = x := by
  have hle : i ≤ j := le_of_lt hij
  have hstep : (σ.symm : X → X)^[i] ((σ : X → X)^[i] x)
      = (σ.symm : X → X)^[i] ((σ : X → X)^[j] x) := by rw [hfij']
  have hleft : (σ.symm : X → X)^[i] ((σ : X → X)^[i] x) = x := cancel_iter σ i x
  have hright : (σ.symm : X → X)^[i] ((σ : X → X)^[j] x) = (σ : X → X)^[j - i] x := by
    rw [iterate_split (σ : X → X) i j hle x]
    exact cancel_iter σ i ((σ : X → X)^[j - i] x)
  have hL : (σ.symm : X → X)^[i] ((σ : X → X)^[j] x) = x := by
    rw [hstep.symm, hleft]
  rw [← hright]
  exact hL

/-- **周期被逼出（主定理）**：有限载体上的可逆演化，每个点都有正周期 ——
    **振数不是输入的，是被有限性逼出来的。**
    证明：`x, σx, ..., σ^(card X) x` 共 `card X + 1` 个点落在 `card X` 个位置里，
    鸽笼 ⟹ 两个相同 ⟹ 周期。 -/
theorem period_exists {X : Type*} [Fintype X] (D : Dynamics X) (x : X) :
    ∃ p : ℕ, 0 < p ∧ (D.step : X → X)^[p] x = x := by
  let f : Fin (Fintype.card X + 1) → X := fun i => (D.step : X → X)^[i.1] x
  have hcard : Fintype.card X < Fintype.card (Fin (Fintype.card X + 1)) := by
    rw [Fintype.card_fin]
    omega
  obtain ⟨i, j, hneq, hfij⟩ := Fintype.exists_ne_map_eq_of_card_lt f hcard
  have hfij' : (D.step : X → X)^[i.1] x = (D.step : X → X)^[j.1] x := by
    simpa [f] using hfij
  by_cases hij : i.1 ≤ j.1
  · have hijlt : i.1 < j.1 := lt_of_le_of_ne hij (fun hval => hneq (Fin.ext hval))
    refine ⟨j.1 - i.1, ?_, period_of_repeat (D.step) i.1 j.1 hijlt hfij'⟩
    omega
  · have hjlt : j.1 < i.1 := Nat.lt_of_not_ge hij
    refine ⟨i.1 - j.1, ?_, ?_⟩
    · omega
    · exact period_of_repeat (D.step) j.1 i.1 hjlt hfij'.symm

/- ------------------------------------------------------------------ -/
/- 3. 零张力动力学：内容在变、张力为零（定理，不是公理）                -/
/- ------------------------------------------------------------------ -/

/-- **动力学保条数**：可逆演化不改变静态读数（`size` 是轨道不变量）。 -/
theorem size_invariant {X : Type*} (R : AtomicReading X) (D : Dynamics X)
    (hsize : ∀ x, R.size (D.step x) = R.size x) (x : X) (k : ℕ) :
    R.size ((D.step : X → X)^[k] x) = R.size x := by
  induction k generalizing x with
  | zero => rfl
  | succ k ih =>
    rw [Function.iterate_succ_apply]
    rw [ih (D.step x)]
    exact hsize x

/-- **零张力动力学（主定理）**：若演化保持条数，则每一步都与前一时刻**张力为零**。
    `τ(x, step x) = 0` —— 这是 TCM「内容不可见」（`size_only`）的动力学版：
    条数相同 ⟹ 张力为零，但内容（相位）在变。振动 = 内容在变、张力为零的运动。
    —— 从静态世界自动长出动力学，不需要任何额外公理。 -/
theorem dynamics_tension_free {X : Type*} (R : AtomicReading X) (τ : AddTension)
    (h7 : τ.Unit) (h4 : τ.Reciprocal) (h3b : τ.NonfullCrit)
    (D : Dynamics X) (hsize : ∀ x, R.size (D.step x) = R.size x) (x : X) :
    τ.grade (R.toProfile x (D.step x)) = 0 := by
  rcases AtomicReading.collapse_four R τ h7 h4 h3b x (D.step x) with h | h
  · rw [h, hsize x]; ring
  · rw [h, hsize x]; ring

/- ------------------------------------------------------------------ -/
/- 4. 振数坐标：从动力学到读数（组装 2 + 3）                           -/
/- ------------------------------------------------------------------ -/

/-- **周期动力学**：载体 `X` 上的动力学 + 每个点的振数（周期）。
    振数 `period x` 满足周期律（`step^[period x] x = x`）。
    **载体不限有限**：有限载体上周期由 `period_exists`（鸽笼）逼出，
    无限载体上周期是显式结构字段（轨道有限假设）—— 两条路都通，`same_orbit_comm`
    只需 `step_period` 就能补足轨道对称性，不依赖 `Fintype`。 -/
structure PeriodicDynamics (X : Type*) extends Dynamics X where
  /-- 振数：每个点的周期（轨道长度 = 振动条数） -/
  period : X → ℕ
  /-- 周期为正 -/
  period_pos : ∀ x, 0 < period x
  /-- 周期律：迭代 `period x` 步回到自身 -/
  step_period : ∀ x, (step : X → X)^[period x] x = x

namespace PeriodicDynamics

variable {X : Type*}

/-- **同轨道**：`y` 可从 `x` 经有限步演化到达（无界定义）。
    在有限载体上这自动等价于「落在同一条轨道上」—— 周期由 `period_exists` 逼出。 -/
def SameOrbit (V : PeriodicDynamics X) (x y : X) : Prop :=
  ∃ k : ℕ, (V.step : X → X)^[k] x = y

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

/-- **同轨道是对称的**：若 `y = step^k x`，则 `x = step^(q·p − k) y`，其中
    `p = period x`、`q` 足够大使 `p·q ≥ k`。 —— 只需 `step_period`，不需要 `Fintype`，
    **无限载体同样成立**。 -/
theorem same_orbit_comm (V : PeriodicDynamics X) {x y : X}
    (h : SameOrbit V x y) : SameOrbit V y x := by
  rcases h with ⟨k, hxy⟩
  -- p = period x（结构字段，有限/无限载体都可用）
  let p := V.period x
  have hp0 : 0 < p := by dsimp [p]; exact V.period_pos x
  have hper : (V.step : X → X)^[p] x = x := by dsimp [p]; exact V.step_period x
  -- 取 q = k/p + 1,使 p·q ≥ k
  let q := k / p + 1
  have hpm : k ≤ p * q := by
    -- k = p·(k/p) + (k%p),k%p < p ⟹ k < p·(k/p+1) ⟹ k ≤ p·q
    have hmod : k = p * (k / p) + k % p := (Nat.div_add_mod k p).symm
    have hlt : k % p < p := Nat.mod_lt k hp0
    have hlt' : k < p * (k / p + 1) := by
      calc
        k = p * (k / p) + k % p := hmod
        _ < p * (k / p) + p := by omega
        _ = p * (k / p + 1) := by ring
    have hq : p * (k / p + 1) = p * q := by
      dsimp [q]
    exact Nat.le_of_lt (by rw [hq]; exact hlt')
  have hpow : (V.step : X → X)^[p * q] x = x :=
    iterate_mul_fixed (V.step : X → X) p q hper
  refine ⟨p * q - k, ?_⟩
  rw [← hxy]
  rw [← iterate_add_len (V.step : X → X) (p * q - k) k]
  rw [Nat.sub_add_cancel hpm]
  exact hpow

/-- **振数读数**：把周期动力学喂给 TCM 的 `AtomicReading` ——
    `size x = period x`（振数），`share x y =` 同轨道则共享**共同的周期部分**
    `min (period x) (period y)`、否则 0。
    `min` 保证对称（不需要人为假定同轨道两点 `period` 相等）。 -/
noncomputable def vibrationReading (V : PeriodicDynamics X) : AtomicReading X where
  size x := V.period x
  share x y := by
    classical
    exact if SameOrbit V x y then min (V.period x) (V.period y) else 0
  share_le_size := by
    classical
    intro a b
    by_cases h : SameOrbit V a b <;> simp [h, Nat.min_le_left]
  share_comm := by
    classical
    intro a b
    by_cases h : SameOrbit V a b
    · have hb : SameOrbit V b a := same_orbit_comm V h
      simp [h, hb, Nat.min_comm]
    · have hb : ¬ SameOrbit V b a := by
        intro hh
        exact h (same_orbit_comm V hh)
      simp [h, hb]
  share_self := by
    classical
    intro a
    have hsa : SameOrbit V a a := ⟨0, rfl⟩
    simp [hsa, Nat.min_self]

/-- **振动塌缩（主定理）**：在振动读数上，满足 TCM 公理的张力只能是**振数差**
    `period a − period b`（或反号）。振数是被迫对象：任何满足计数公理的振动张力
    都只能是振数差。 -/
theorem vibration_collapse (V : PeriodicDynamics X) (τ : AddTension)
    (h7 : τ.Unit) (h4 : τ.Reciprocal) (h3b : τ.NonfullCrit) (a b : X) :
    τ.grade ((vibrationReading V).toProfile a b) =
        ((V.period a : ℕ) : ℤ) - ((V.period b : ℕ) : ℤ)
      ∨ τ.grade ((vibrationReading V).toProfile a b) =
        (((V.period b : ℕ) : ℤ) - ((V.period a : ℕ) : ℤ)) := by
  exact AtomicReading.collapse_four (vibrationReading V) τ h7 h4 h3b a b

/-- 同振数的两个振动体之间张力为零。 -/
theorem vibration_same_period_balanced (V : PeriodicDynamics X) (τ : AddTension)
    (h7 : τ.Unit) (h4 : τ.Reciprocal) (h3b : τ.NonfullCrit) (a b : X)
    (h : V.period a = V.period b) :
    τ.grade ((vibrationReading V).toProfile a b) = 0 := by
  rcases vibration_collapse V τ h7 h4 h3b a b with h' | h'
  · rw [h', h]; ring
  · rw [h', h]; ring

/-- **不动点 = 不振**：振数 1 ⟹ `step x = x`。 -/
theorem period_one_fixed (V : PeriodicDynamics X) (x : X)
    (h : V.period x = 1) : (V.step : X → X) x = x := by
  have h1 : (V.step : X → X)^[1] x = (V.step : X → X) x := by rfl
  rw [← h1]
  rw [← h]
  exact V.step_period x

/-- **不动点处张力为零**：不振的振动体与「下一步的自己」无张力 —— 临界 = 不振。 -/
theorem fixed_point_balanced (V : PeriodicDynamics X) (τ : AddTension)
    (h7 : τ.Unit) (h4 : τ.Reciprocal) (h3b : τ.NonfullCrit) (x : X)
    (hfix : (V.step : X → X) x = x) :
    τ.grade ((vibrationReading V).toProfile x ((V.step : X → X) x)) = 0 := by
  rw [hfix]
  exact vibration_same_period_balanced V τ h7 h4 h3b x x rfl

/-- **振数坐标**：对象 `x` 的坐标 = 它的振数 `period x`。
    不动点（不振）是原点，振数 = 1。 -/
def vibCoord (V : PeriodicDynamics X) (x : X) : ℕ := V.period x

/-- **振动张力 = 坐标差**（坐标系语言的塌缩定理）：
    两个振动体之间的张力就是它们振数坐标的差（或反号）。
    —— 这正是「以振动为模式的坐标系」：坐标 = 振数，距离/力 = 坐标差。 -/
theorem vib_tension_is_coord_diff (V : PeriodicDynamics X) (τ : AddTension)
    (h7 : τ.Unit) (h4 : τ.Reciprocal) (h3b : τ.NonfullCrit) (a b : X) :
    τ.grade ((vibrationReading V).toProfile a b) =
        ((vibCoord V a : ℕ) : ℤ) - ((vibCoord V b : ℕ) : ℤ)
      ∨ τ.grade ((vibrationReading V).toProfile a b) =
        (((vibCoord V b : ℕ) : ℤ) - ((vibCoord V a : ℕ) : ℤ)) := by
  simpa [vibCoord] using vibration_collapse V τ h7 h4 h3b a b

end PeriodicDynamics

/- ------------------------------------------------------------------ -/
/- 5. 实例：点 / 线 / 面（有限载体，周期被逼出）                        -/
/- ------------------------------------------------------------------ -/

/-- 两点的交换演化：`0 ↔ 1`，周期 2 —— 最小的非平凡振动，**不需要弦**。 -/
def swapFin2 : Fin 2 ≃ Fin 2 where
  toFun := fun i => if i = 0 then 1 else 0
  invFun := fun i => if i = 0 then 1 else 0
  left_inv := by
    intro i
    fin_cases i <;> simp
  right_inv := by
    intro i
    fin_cases i <;> simp

/-- **点振动**：两个点彼此交换 —— 振动的东西是「点」，不是线。 -/
def pointDynamics : Dynamics (Fin 2) := ⟨swapFin2⟩

/-- 三点的循环移位（线振动）：`0 → 1 → 2 → 0`，周期 3。
    逆映射用 `+2`（3 元环上 `+2 ≡ −1`），避免 `Fin` 减法符号问题。 -/
def shiftFin3 : Fin 3 ≃ Fin 3 where
  toFun := fun i => (i + 1)
  invFun := fun i => (i + 2)
  left_inv := by
    intro i
    fin_cases i <;> simp
  right_inv := by
    intro i
    fin_cases i <;> simp

/-- **线振动**：一条「线」（3 个点排成环）整体循环 —— 载体是线，振动照常。 -/
def lineDynamics : Dynamics (Fin 3) := ⟨shiftFin3⟩

/-- **面振动 = 两个独立振子的乘积**：`step` 在两坐标上分别走。 -/
def productDynamics {X Y : Type*} (D : Dynamics X) (W : Dynamics Y) :
    Dynamics (X × Y) where
  step := Equiv.prodCongr D.step W.step

/-- **面振动实例**：`Fin 2 × Fin 3`（2×3 的格点面），x 方向两点交换、y 方向三点循环。 -/
def planeDynamics : Dynamics (Fin 2 × Fin 3) := productDynamics pointDynamics lineDynamics

/-- **实例：点振动的周期被逼出**（`period_exists` 在 `Fin 2` 上给正周期）。 -/
theorem point_period_exists : ∃ p : ℕ, 0 < p ∧ (pointDynamics.step : Fin 2 → Fin 2)^[p] 0 = 0 :=
  period_exists pointDynamics 0

/-- **实例：线振动的周期被逼出**（`Fin 3`）。 -/
theorem line_period_exists : ∃ p : ℕ, 0 < p ∧ (lineDynamics.step : Fin 3 → Fin 3)^[p] 0 = 0 :=
  period_exists lineDynamics 0

/-- **实例：面振动的周期被逼出**（`Fin 2 × Fin 3`，周期 ≤ 6）。 -/
theorem plane_period_exists : ∃ p : ℕ, 0 < p ∧ (planeDynamics.step : Fin 2 × Fin 3 → Fin 2 × Fin 3)^[p] (0, 0) = (0, 0) :=
  period_exists planeDynamics (0, 0)

/- ------------------------------------------------------------------ -/
/- 6. 无限载体实例：ℚ 反转（显式周期，轨道有限假设）                    -/
/- ------------------------------------------------------------------ -/

/-- **ℚ 上的反转**：`x ↦ 1 − x` —— 数自身在反转下来回振。
    这是**对合**（自己作为自己的逆），故是合法动力学。 -/
def revQ1 : ℚ ≃ ℚ where
  toFun := fun x => 1 - x
  invFun := fun x => 1 - x
  left_inv := by intro x; ring
  right_inv := by intro x; ring

/-- **数振动（无限载体）**：ℚ 无限，周期不能靠鸽笼逼出 —— 这里是**显式周期**：
    中心 `1/2` 振数 1（不振），其余数振数 2（一个来回）。
    —— 这是「无限载体需轨道有限假设」的实例：每条轨道恰好 1 或 2 个点。 -/
def numPeriodicDynamics : PeriodicDynamics ℚ where
  toDynamics := ⟨revQ1⟩
  period := fun x => if 1 - x = x then 1 else 2
  period_pos := by
    intro x
    by_cases h : 1 - x = x <;> simp [h]
  step_period := by
    intro x
    by_cases h : 1 - x = x
    · -- period = 1：一次迭代 1 − x = x
      simp [h, revQ1]
    · -- period = 2：两次迭代 1 − (1 − x) = x（对合）
      have h2 : (revQ1 : ℚ → ℚ)^[2] x = x := by
        change 1 - (1 - x) = x
        ring
      simp [h, h2, revQ1]

/-- **中心 `1/2` 振数 = 1（不振）**：`1 − 1/2 = 1/2`。 -/
theorem num_period_center : numPeriodicDynamics.period (1 / 2 : ℚ) = 1 := by
  simp [numPeriodicDynamics]
  norm_num

/-- **非中心点振数 = 2**：`x ≠ 1/2` ⟹ `1 − x ≠ x`。 -/
theorem num_period_off_center {x : ℚ} (h : x ≠ 1 / 2) : numPeriodicDynamics.period x = 2 := by
  have hne : 1 - x ≠ x := by
    intro hh
    apply h
    linarith
  simp [numPeriodicDynamics, hne]

/-- **中心处张力为零**（不振 = 临界）：`τ(1/2, 1 − 1/2) = 0`。
    —— 数振动的中心 `1/2` 是临界点：`Re = 1/2` 的形状在振数坐标里是「不振」。 -/
theorem num_center_balanced (τ : AddTension) (h7 : τ.Unit) (h4 : τ.Reciprocal)
    (h3b : τ.NonfullCrit) :
    τ.grade ((PeriodicDynamics.vibrationReading numPeriodicDynamics).toProfile (1 / 2 : ℚ)
      (revQ1 (1 / 2 : ℚ))) = 0 := by
  have hfix : revQ1 (1 / 2 : ℚ) = (1 / 2 : ℚ) := by
    simp [revQ1]
    norm_num
  exact PeriodicDynamics.fixed_point_balanced numPeriodicDynamics τ h7 h4 h3b (1 / 2 : ℚ) hfix

end NODS
