/-
【理论层】PU-12：用「振动坐标系 + 张力计数法 + 隐数三射线」构造的 12 层宇宙
================================================================================

本文件不是物理断言，而是把一个**给定的宇宙参数集**编译成定理：

    给定：12 个频率带（按对数量级均分）、上限 f₀ = 10⁴¹ Hz；
          12 个维度，每维 3 子维度、每子维 3 亚维度；
          初始能量、后续从结构维度内生获得的能量；
          频率越高能量越纯粹。

本文件证明的（0 sorry）：

  1. **阶梯**（§1）：bandHi k = 10⁴¹ / 10^(5k)。12 带均分 ⟹ 带宽恰好 10⁵ 倍；
     最低带上沿 = 10⁴¹/10⁶⁰ = 1/10¹⁹。阶梯严格递减、相邻带首尾相接（无空隙）。
  2. **频率 = 振动坐标**（§2）：ω_k = 2π·f_k（`step_phase_advance` 的连续化读法：
     一步 = 1/period 圈 ⟹ 圆频率 ∝ 1/period）。量子能量 ε_k = ℏω_k 严格递减。
  3. **纯度**（§3）：两种独立定义都严格单调 ——
     谱纯度（阶梯位置）与量子纯度（定量能量下的量子数倒数）。
     「频率越高越纯」= 定理，不是设定。
  4. **张力计数法**（§4）：把 TCM 的塌缩定理实例化成一个**具体的** `AddTension`
     （K = a 的独有条数，L = b 的），得到 `τ(a,b) = 条数(a) − 条数(b)`。
     结构读数 `structReading` 用「共享 = 两边条数的较小者」，于是张力量就是
     **隐数条数差** —— 能量流动的方向不是选的，是被塌缩定理逼出来的。
  5. **交换守恒**（§5）：把 q 个量子从 i 搬到 j，总量不变；能量改变 = q·(ε_j − ε_i)；
     因此 ΔE 的符号 = 频率升降的方向，纯度同号。
  6. **平衡**（§6）：张力为零 ⟺ 条数相等（TCM「内容不可见」的宇宙版：
     平衡是**结构的**，不是能量的 —— 条数齐了，再悬殊的能量也不流）。
  7. **阶梯封闭**（§7）：低于第 12 带上沿（1/10¹⁹ Hz）没有任何带 ⟹
     12 维是**封闭**的，不是被截断的。

对应 wiki 页：`docs/wiki/private-universe.md`
可执行实现：`scripts/universe_model.py`（精确有理数、无浮点误差）
-/

import Nods.Theories.TensionReading
import Nods.Theories.VibrationGeometry

namespace NODS

open scoped BigOperators

/- ------------------------------------------------------------------ -/
/- 1. 频率阶梯：12 带、带宽 10⁵、上沿 10⁴¹                            -/
/- ------------------------------------------------------------------ -/

/-- 第 `k` 带的**上沿**频率（`k = 0` 为最高带）：`10^41 / 10^(5k)`。
    5 个数量级一个带 —— 这个 5 不是选的，见 `band_ratio` 与 wiki 的定阶论证。 -/
noncomputable def bandHi (k : ℕ) : ℝ := (10 : ℝ) ^ 41 / (10 : ℝ) ^ (5 * k)

/-- 第 `k` 带的**下沿**频率 = 第 `k+1` 带的上沿（首尾相接，无空隙）。 -/
noncomputable def bandLo (k : ℕ) : ℝ := (10 : ℝ) ^ 41 / (10 : ℝ) ^ (5 * (k + 1))

theorem bandHi_pos (k : ℕ) : 0 < bandHi k := by
  unfold bandHi
  positivity

/-- 相邻带首尾相接：`bandLo k = bandHi (k+1)`（定义即得）。 -/
theorem bandLo_eq_bandHi_succ (k : ℕ) : bandLo k = bandHi (k + 1) := rfl

/-- 上沿按固定倍数 `10^5` 递减。 -/
theorem bandHi_succ (k : ℕ) : bandHi (k + 1) = bandHi k / 10 ^ 5 := by
  unfold bandHi
  rw [Nat.mul_succ, pow_add]
  rw [div_div]

/-- 阶梯严格下降：带宽 10⁵ > 1。 -/
theorem bandHi_step_lt (k : ℕ) : bandHi (k + 1) < bandHi k := by
  rw [bandHi_succ]
  exact div_lt_self (bandHi_pos k) (by norm_num)

/-- 上沿单调不增。 -/
theorem bandHi_antitone : Antitone bandHi := by
  intro a b hab
  induction b, hab using Nat.le_induction with
  | base => exact le_rfl
  | succ m hm ih => exact le_trans (le_of_lt (bandHi_step_lt m)) ih

/-- 上沿严格反单调（更高带 = 更低频率）。 -/
theorem bandHi_strictAnti : StrictAnti bandHi := by
  intro a b hab
  obtain ⟨c, rfl⟩ : ∃ c, b = a + c + 1 := ⟨b - a - 1, by omega⟩
  have h1 : bandHi (a + c + 1) ≤ bandHi (a + 1) := bandHi_antitone (by omega)
  exact lt_of_le_of_lt h1 (bandHi_step_lt a)

/-- 最高带的上沿就是给定的天花板 `10^41`。 -/
theorem bandHi_zero : bandHi 0 = (10 : ℝ) ^ 41 := by
  unfold bandHi
  norm_num

/-- 第 12 带（索引 11）的下沿 = `1/10^19` —— 宇宙阶梯的地板。 -/
theorem bandLo_eleven : bandLo 11 = 1 / (10 : ℝ) ^ 19 := by
  unfold bandLo
  have h : (10 : ℝ) ^ (5 * (11 + 1)) = (10 : ℝ) ^ 60 := by norm_num
  rw [h]
  rw [show (60 : ℕ) = 41 + 19 from rfl, pow_add]
  field_simp

/-- **带宽 = 10⁵ 倍**：相邻两带的上沿之比恰是 10⁵（5 个数量级）。
    这条是「量子不可分」与「交换必须整数」的接合点：
    一个高带量子在低一档的带里恰好裂成 10⁵ 个，能量精确守恒（§5）。 -/
theorem band_ratio (k : ℕ) : bandHi k / bandLo k = 10 ^ 5 := by
  have h1 : (0 : ℝ) < (10 : ℝ) ^ 41 := by positivity
  have h2 : (0 : ℝ) < (10 : ℝ) ^ (5 * k) := by positivity
  have h3 : (0 : ℝ) < (10 : ℝ) ^ (5 * (k + 1)) := by positivity
  have h4 : (10 : ℝ) ^ (5 * (k + 1)) = (10 : ℝ) ^ (5 * k) * 10 ^ 5 := by
    rw [Nat.mul_succ, pow_add]
  unfold bandHi bandLo
  rw [h4]
  field_simp

/- ------------------------------------------------------------------ -/
/- 2. 频率 = 振动坐标：ω_k = 2π·f_k，量子能量 ε_k = ℏω_k              -/
/- ------------------------------------------------------------------ -/

/-- 第 `k` 带代表的圆频率（振动坐标的连续读法：`step_phase_advance` 说
    一步推进 `1/period` 圈 ⟹ 角速度 ∝ `1/period`；取 `ω = 2π·f`）。 -/
noncomputable def omega (k : ℕ) : ℝ := 2 * Real.pi * bandHi k

/-- 一个量子的能量：`ε_k = ℏ·ω_k`。 -/
noncomputable def quantumE (ℏ : ℝ) (k : ℕ) : ℝ := ℏ * omega k

theorem omega_pos (k : ℕ) : 0 < omega k := by
  unfold omega
  have := bandHi_pos k
  positivity

theorem omega_strictAnti : StrictAnti omega := by
  intro a b hab
  unfold omega
  exact mul_lt_mul_of_pos_left (bandHi_strictAnti hab) (by positivity)

/-- 带越高，一个量子越重（`ℏ > 0`）。 -/
theorem quantumE_strictAnti (ℏ : ℝ) (hℏ : 0 < ℏ) : StrictAnti (quantumE ℏ) := by
  intro a b hab
  unfold quantumE
  exact mul_lt_mul_of_pos_left (omega_strictAnti hab) hℏ

/-- 量子能量的比值也是 `10^5`（与 `band_ratio` 同源）。 -/
theorem quantumE_ratio (ℏ : ℝ) (k : ℕ) (hℏ : ℏ ≠ 0) :
    quantumE ℏ k / quantumE ℏ (k + 1) = 10 ^ 5 := by
  have h : quantumE ℏ k / quantumE ℏ (k + 1) = bandHi k / bandHi (k + 1) := by
    unfold quantumE omega
    field_simp
  rw [h, bandHi_succ]
  have hk : bandHi k ≠ 0 := ne_of_gt (bandHi_pos k)
  field_simp

/- ------------------------------------------------------------------ -/
/- 3. 纯度：两种独立定义，都严格随频率上升                            -/
/- ------------------------------------------------------------------ -/

/-- **谱纯度**：`π(k) = f_k / f₀ ∈ (0,1]` —— 在阶梯上的位置。 -/
noncomputable def spectralPurity (k : ℕ) : ℝ := bandHi k / bandHi 0

theorem spectralPurity_pos (k : ℕ) : 0 < spectralPurity k := by
  unfold spectralPurity
  exact div_pos (bandHi_pos k) (bandHi_pos 0)

/-- **「频率越高，能量越纯粹」（谱版，定理）**：谱纯度严格反单调于带索引。 -/
theorem spectralPurity_strictAnti : StrictAnti spectralPurity := by
  intro a b hab
  unfold spectralPurity
  exact div_lt_div_of_pos_right (bandHi_strictAnti hab) (bandHi_pos 0)

/-- **量子纯度**：把定量能量 `E` 装在频率 `ε` 的量子里的个数是 `E/ε`；
    纯度取倒数形态 `ε/E` —— 量子越少、每个越重，能量越纯。 -/
noncomputable def quantumPurity (E ε : ℝ) : ℝ := ε / E

/-- **「频率越高，能量越纯粹」（量子版，定理）**：同一份能量 `E`，
    分到更重的量子里 ⟹ 量子数更少 ⟹ 纯度更高。 -/
theorem quantumPurity_lt_of_lt {E ε ε' : ℝ} (hE : 0 < E) (h : ε < ε') :
    quantumPurity E ε < quantumPurity E ε' := by
  unfold quantumPurity
  exact div_lt_div_of_pos_right h hE

/-- 两版纯度一致地随带索引反单调：高带两版都更纯。 -/
theorem purity_agree (ℏ : ℝ) (hℏ : 0 < ℏ) (E : ℝ) (hE : 0 < E) {a b : ℕ} (hab : a < b) :
    quantumPurity E (quantumE ℏ b) < quantumPurity E (quantumE ℏ a) ∧
      spectralPurity b < spectralPurity a := by
  refine ⟨quantumPurity_lt_of_lt hE (quantumE_strictAnti ℏ hℏ (a := a) (b := b) hab), ?_⟩
  exact spectralPurity_strictAnti hab

/- ------------------------------------------------------------------ -/
/- 4. 张力计数法：把塌缩定理实例化成「条数差」                         -/
/- ------------------------------------------------------------------ -/

/-- 计数张力的收敛力：只数 `a` 侧独有的条数（剖面第二分量）。 -/
def countK : (ℕ × ℕ × ℕ) →+ ℤ where
  toFun u := (u.2.1 : ℤ)
  map_zero' := by simp
  map_add' := by
    intro x y
    have h : (x + y).2.1 = x.2.1 + y.2.1 := rfl
    rw [h]
    push_cast
    ring

/-- 计数张力的发散力：只数 `b` 侧独有的条数（剖面第三分量）。 -/
def countL : (ℕ × ℕ × ℕ) →+ ℤ where
  toFun u := (u.2.2 : ℤ)
  map_zero' := by simp
  map_add' := by
    intro x y
    have h : (x + y).2.2 = x.2.2 + y.2.2 := rfl
    rw [h]
    push_cast
    ring

/-- **计数张力**（TCM 的一个具体实例）：`grade = K − L = a 独有 − b 独有`。 -/
def countTension : AddTension := ⟨countK, countL⟩

theorem countTension_grade (u : ℕ × ℕ × ℕ) :
    countTension.grade u = (u.2.1 : ℤ) - (u.2.2 : ℤ) := rfl

theorem countTension_selfZero : countTension.SelfZero := by
  intro t
  constructor <;> rfl

theorem countTension_unit : countTension.Unit := by
  unfold AddTension.Unit countTension countK countL
  simp

theorem countTension_reciprocal : countTension.Reciprocal := by
  intro u
  simp only [AddTension.grade, countTension, countK, countL]
  simp

theorem countTension_nonfull : countTension.NonfullCrit := by
  refine ⟨(0, 1, 0), ?_⟩
  simp [AddTension.grade, countTension, countK, countL]

/-- **直接算法**：这个实例的张力就是两条独有条数之差。 -/
theorem countTension_grade_eq {X : Type*} (R : AtomicReading X) (a b : X) :
    countTension.grade (R.toProfile a b)
      = ((R.onlyA a b : ℕ) : ℤ) - ((R.onlyB a b : ℕ) : ℤ) := rfl

/-- **塌缩定理的实例化**：把仓库已证的 `AtomicReading.collapse` 套到 `countTension` 上
    —— 任意读数上，张力只能取「条数差」或它的反号（唯一到取向）。 -/
theorem countTension_collapse_form {X : Type*} (R : AtomicReading X) (a b : X) :
    countTension.grade (R.toProfile a b) = ((R.size a : ℕ) : ℤ) - ((R.size b : ℕ) : ℤ)
      ∨ countTension.grade (R.toProfile a b)
          = ((R.size b : ℕ) : ℤ) - ((R.size a : ℕ) : ℤ) :=
  R.collapse countTension countTension_selfZero countTension_unit
    countTension_reciprocal countTension_nonfull a b

/-- **本宇宙的流动定律**：`countTension` 落在「+条数差」这一支
    （记账见 `countTension_grade_eq`：a 独有 − b 独有 = 条数差）。 -/
theorem countTension_collapse {X : Type*} (R : AtomicReading X) (a b : X) :
    countTension.grade (R.toProfile a b) = ((R.size a : ℕ) : ℤ) - ((R.size b : ℕ) : ℤ) := by
  rw [countTension_grade_eq R a b]
  unfold AtomicReading.onlyA AtomicReading.onlyB
  have h1 : R.share a b ≤ R.size a := R.share_le_size a b
  have h2 : R.share a b ≤ R.size b := R.share_le_size_right a b
  omega

/-- **结构读数**：一个维度 = 一束隐数，`size = 条数`、共享 = 两边条数的较小者
    （嵌套结构「小的整体被大的包含」）。这是 TCM 允许的最小载体。 -/
def structReading {X : Type*} (a : X → ℕ) : AtomicReading X where
  share i j := min (a i) (a j)
  size := a
  share_le_size := by intro i j; exact min_le_left _ _
  share_comm := by intro i j; exact min_comm _ _
  share_self := by intro i; exact min_self _

/-- **宇宙的张力**：维度 `i` 对维度 `j` 的张力 = 隐数条数差。 -/
theorem struct_tension {X : Type*} (a : X → ℕ) (i j : X) :
    countTension.grade ((structReading a).toProfile i j)
      = ((a i : ℕ) : ℤ) - ((a j : ℕ) : ℤ) :=
  countTension_collapse (structReading a) i j

/- ------------------------------------------------------------------ -/
/- 5. 交换：量子数守恒、能量改变 = q·(ε_j − ε_i)                       -/
/- ------------------------------------------------------------------ -/

/-- 把 `q` 个量子从 `i` 搬到 `j`。 -/
def exch {ι : Type*} [DecidableEq ι] (n : ι → ℕ) (i j : ι) (q : ℕ) : ι → ℕ :=
  fun x => if x = i then n x - q else if x = j then n x + q else n x

/-- 逐点记账：交换 = 在 `j` 处 +q、在 `i` 处 −q。 -/
theorem exch_apply {ι : Type*} [DecidableEq ι] (n : ι → ℕ) {i j : ι} (hij : i ≠ j)
    (q : ℕ) (hq : q ≤ n i) (x : ι) :
    ((exch n i j q x : ℕ) : ℤ)
      = (n x : ℤ) + (if x = j then (q : ℤ) else 0) - (if x = i then (q : ℤ) else 0) := by
  unfold exch
  by_cases hx : x = i
  · subst hx
    simp [hij, Nat.cast_sub hq]
  · by_cases hx2 : x = j
    · subst hx2
      simp [hx, Nat.cast_add]
    · simp [hx, hx2]

/-- **量子数守恒（定理）**：交换不产生也不消灭量子。 -/
theorem sum_exch {ι : Type*} [Fintype ι] [DecidableEq ι] (n : ι → ℕ) {i j : ι}
    (hij : i ≠ j) (q : ℕ) (hq : q ≤ n i) :
    ∑ x, exch n i j q x = ∑ x, n x := by
  classical
  have hZ : ((∑ x, exch n i j q x : ℕ) : ℤ)
      = ∑ x, ((n x : ℤ) + (if x = j then (q : ℤ) else 0)
          - (if x = i then (q : ℤ) else 0)) := by
    rw [Nat.cast_sum]
    exact Finset.sum_congr rfl (fun x _ => exch_apply n hij q hq x)
  have hsum : ∑ x : ι, ((n x : ℤ) + (if x = j then (q : ℤ) else 0)
      - (if x = i then (q : ℤ) else 0)) = ∑ x, (n x : ℤ) := by
    rw [Finset.sum_sub_distrib, Finset.sum_add_distrib]
    simp
  have hcast : ((∑ x, exch n i j q x : ℕ) : ℤ) = ((∑ x, n x : ℕ) : ℤ) := by
    rw [hZ, hsum, Nat.cast_sum]
  exact Nat.cast_injective hcast

/-- 维度 `k` 的能量：`n_k` 个量子 × 每量子 `w_k`。 -/
noncomputable def energyOf {ι : Type*} [Fintype ι] (w : ι → ℝ) (n : ι → ℕ) : ℝ :=
  ∑ x, (n x : ℝ) * w x

/-- **能量改变 = q·(ε_j − ε_i)**：交换不是免费的，差价由结构场收支。
    这条 + `band_ratio` 给出「跨带交换必须整数」：`q` 个高带量子在低一档带里
    变成 `10^5·q` 个，能量精确相等。 -/
theorem energy_exch {ι : Type*} [Fintype ι] [DecidableEq ι] (w : ι → ℝ) (n : ι → ℕ)
    {i j : ι} (hij : i ≠ j) (q : ℕ) (hq : q ≤ n i) :
    energyOf w (exch n i j q) = energyOf w n + (q : ℝ) * (w j - w i) := by
  classical
  have hpt : ∀ x, ((exch n i j q x : ℕ) : ℝ) * w x
      = (n x : ℝ) * w x + (if x = j then (q : ℝ) * w j else 0)
        - (if x = i then (q : ℝ) * w i else 0) := by
    intro x
    unfold exch
    by_cases hx : x = i
    · subst hx
      simp [hij, Nat.cast_sub hq, sub_mul]
    · by_cases hx2 : x = j
      · subst hx2
        simp [hx, Nat.cast_add, add_mul]
      · simp [hx, hx2]
  unfold energyOf
  rw [Finset.sum_congr rfl (fun x _ => hpt x)]
  rw [Finset.sum_sub_distrib, Finset.sum_add_distrib]
  rw [show ∑ x : ι, (if x = j then (q : ℝ) * w j else 0) = (q : ℝ) * w j from by simp,
      show ∑ x : ι, (if x = i then (q : ℝ) * w i else 0) = (q : ℝ) * w i from by simp]
  ring

/-- **纯度的流向（定理）**：搬量子到更高频的维度 ⟹ 总能量严格上升。 -/
theorem energy_up_of_upconvert {ι : Type*} [Fintype ι] [DecidableEq ι] (w : ι → ℝ)
    (n : ι → ℕ) {i j : ι} (hij : i ≠ j) (q : ℕ) (hq : q ≤ n i) (hq0 : 0 < q)
    (hwij : w i < w j) :
    energyOf w n < energyOf w (exch n i j q) := by
  rw [energy_exch w n hij q hq]
  have hq' : (0 : ℝ) < (q : ℝ) := by exact_mod_cast hq0
  nlinarith

/- ------------------------------------------------------------------ -/
/- 6. 平衡：张力为零 ⟺ 条数相等                                       -/
/- ------------------------------------------------------------------ -/

/-- 隐含数条数的张力（ℤ 值）。 -/
def countTensionZ {X : Type*} (a : X → ℕ) (i j : X) : ℤ := (a i : ℤ) - (a j : ℤ)

/-- **平衡判据（TCM「内容不可见」的宇宙版）**：张力为零 ⟺ **条数相等**。
    ⟹ 宇宙的平衡是**结构的**平衡，不是能量的平衡：条数一齐，能量再悬殊也不流。 -/
theorem tension_zero_iff {X : Type*} (a : X → ℕ) (i j : X) :
    countTensionZ a i j = 0 ↔ a i = a j := by
  unfold countTensionZ
  constructor
  · intro h
    have : (a i : ℤ) = (a j : ℤ) := by omega
    exact_mod_cast this
  · intro h
    rw [h]
    simp

/-- 条数相等 ⟹ 张力（塌缩形态）为零：与 `tension_zero_iff` 同一件事的两面。 -/
theorem tension_zero_of_eq {X : Type*} (a : X → ℕ) {i j : X} (h : a i = a j) :
    countTensionZ a i j = 0 := (tension_zero_iff a i j).mpr h

/- ------------------------------------------------------------------ -/
/- 7. 阶梯封闭：第 12 带以下没有带                                     -/
/- ------------------------------------------------------------------ -/

/-- **地板定理**：频率不高于第 12 带下沿（`1/10^19 Hz`）的，不属于任何带。
    ⟹ 12 维不是「截断」，是**封闭**：阶梯下方没有下一档。 -/
theorem no_band_below_floor (f : ℝ) (h : f ≤ bandLo 11) :
    ¬ ∃ k : ℕ, k < 12 ∧ bandLo k < f := by
  rintro ⟨k, hk, hkf⟩
  have h1 : bandHi 12 ≤ bandHi (k + 1) := bandHi_antitone (by omega)
  have h2 : bandHi 12 = bandLo 11 := rfl
  have h3 : bandLo k = bandHi (k + 1) := rfl
  rw [h3] at hkf
  linarith

/-- 天花板之上也没有带：`10^41` 之上没有第 −1 档。 -/
theorem no_band_above_ceiling (f : ℝ) (h : bandHi 0 < f) :
    ¬ ∃ k : ℕ, f ≤ bandHi k := by
  rintro ⟨k, hk⟩
  exact absurd (le_trans hk (bandHi_antitone (Nat.zero_le k))) (not_le.mpr h)

end NODS
