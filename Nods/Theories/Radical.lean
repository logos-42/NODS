/-
【理论层】根式扩张：幂（商）与开方（截面）的结构区分
==================================================

这不是把「开方」定义成「幂的倒数指数」。那是在**无挠群**（正实数乘法群 ℝ₊）
上才成立的塌缩：`pₙ : x ↦ xⁿ` 在 ℝ₊ 上核平凡、是自同构，开方是它的（单值）逆。

一旦有**挠**（n 次单位根 μₙ），区分就冒出来：

  * 幂 `pₙ : G → G, x ↦ xⁿ` 是群同态，核 = μₙ（大小 n），故 n 对 1 —— 它是
    「按 μₙ 折叠」的**商映射** `G ↠ G/μₙ ≅ G`。
  * 开方是 `pₙ` 的**多值逆**（n 个分支，彼此差一个 μₙ 因子）—— 它是「把覆盖
    撑开」的**截面**，只在选分支后才是单值函数。

于是「幂 vs 开方」不是「同一族 x^t 取 t = n 与 t = 1/n」，
而是范畴论里的 **epi（商/折叠）与 mono（截面/撑开）** 两个不同角色。

本文件把这条区分落成三条定理（均已完整证明）：

  1. `powMap_ker_eq_nRoots`       —— pₙ 的核恰是 n 次单位根群 μₙ。
  2. `powMap_fiber_iff`           —— xⁿ 的所有 n 次根 = 陪集 x·μₙ（逐点形式）。
  3. `powMap_injective_iff_nRoots_trivial` —— pₙ 单射（开方单值）⇔ μₙ 平凡（无挠）。

第 3 条正是「塌缩条件」：ℝ₊ 上 μₙ = {1}（无挠），开方才单值、才退化成
「分数次幂」；ℂ^× 上 μₙ 有 n 个元素，开方 n 值。
-/

import Mathlib

namespace NODS

universe u

/-- n 次单位根群：交换群 `G` 中满足 `x ^ n = 1` 的元素构成的子群。
    这就是「挠」的 n-成分——幂映射 `x ↦ xⁿ` 的核。 -/
def nRoots (n : ℕ) (G : Type u) [CommGroup G] : Subgroup G where
  carrier := {x | x ^ n = 1}
  one_mem' := by
    change (1 : G) ^ n = 1
    simp
  mul_mem' := by
    intro a b ha hb
    change (a * b) ^ n = 1
    rw [mul_pow a b n, ha, hb, one_mul]
  inv_mem' := by
    intro a ha
    change (a⁻¹) ^ n = 1
    rw [inv_pow a n, ha, inv_one]

/- ------------------------------------------------------------------ -/
/- 三条定理                                                           -/
/- ------------------------------------------------------------------ -/

/-- 定理 1：幂映射 `x ↦ xⁿ` 的核恰是 n 次单位根群 μₙ。 -/
theorem powMap_ker_eq_nRoots (n : ℕ) (G : Type u) [CommGroup G] :
    MonoidHom.ker (powMonoidHom (α := G) n) = nRoots n G := by
  ext x
  change x ^ n = 1 ↔ x ^ n = 1
  exact Iff.rfl

/-- 定理 2：`zⁿ = xⁿ` 当且仅当 `z` 落在陪集 `x · μₙ` 里（逐点形式）。
    即 `xⁿ` 的全部 n 次根 = `{x · ζ | ζⁿ = 1}`。 -/
theorem powMap_fiber_iff (n : ℕ) (G : Type u) [CommGroup G] (x z : G) :
    z ^ n = x ^ n ↔ ∃ ζ : G, ζ ^ n = 1 ∧ z = x * ζ := by
  constructor
  · intro h
    refine ⟨x⁻¹ * z, ?_, ?_⟩
    · calc
        (x⁻¹ * z) ^ n = (x⁻¹) ^ n * z ^ n := mul_pow x⁻¹ z n
        _ = (x ^ n)⁻¹ * z ^ n := by rw [inv_pow x n]
        _ = (x ^ n)⁻¹ * x ^ n := by rw [h]
        _ = 1 := inv_mul_cancel (x ^ n)
    · exact (mul_inv_cancel_left x z).symm
  · rintro ⟨ζ, hζ, rfl⟩
    calc
      (x * ζ) ^ n = x ^ n * ζ ^ n := mul_pow x ζ n
      _ = x ^ n * 1 := by rw [hζ]
      _ = x ^ n := mul_one (x ^ n)

/-- 定理 3：幂映射单射（即开方单值、可退化成「分数次幂」）当且仅当
    μₙ 平凡（无 n 次非平凡单位根）。这是「塌缩条件」的精确形式。 -/
theorem powMap_injective_iff_nRoots_trivial (n : ℕ) (G : Type u) [CommGroup G] :
    Function.Injective ((powMonoidHom (α := G) n) : G → G) ↔ nRoots n G = ⊥ := by
  rw [← powMap_ker_eq_nRoots]
  exact (MonoidHom.ker_eq_bot_iff (powMonoidHom (α := G) n)).symm

/- ------------------------------------------------------------------ -/
/- 计算层 v0：形式化地「解释一个数」                                   -/
/- ------------------------------------------------------------------ -/

-- 思路：同一个数，四条函数族给出**不同**的构造公式，且哪些路走得通
-- 各不相同 —— 这正是「开方 ≠ 幂 ≠ 对数 ≠ 指数」的可计算体现。
-- ℕ/ℚ 部分真的会算（norm_num）；ℝ 部分是精确定理（sqrt/log/exp 非可计算
-- 定义，但等式可被机器检查）。

/-- 幂族解释 25：5² = 25（ℕ，直接可算）。 -/
example : (5 : ℕ) ^ 2 = 25 := by norm_num

/-- 开方族解释 25：√25 = 5（ℕ 整数平方根，直接可算）。 -/
example : Nat.sqrt 25 = 5 := by norm_num

/-- 开方族解释 169：√169 = 13（可算）。 -/
example : Nat.sqrt 169 = 13 := by norm_num

/-- 但 2 是幂族（平方）解释不了的：ℕ 里没有 n 满足 n² = 2。 -/
theorem two_not_sq_nat : ¬ ∃ n : ℕ, n ^ 2 = 2 := by
  rintro ⟨n, hn⟩
  have h1 : n ≤ 1 := by
    by_contra h
    have hn2 : 2 ≤ n := by omega
    have hsq : 4 ≤ n ^ 2 := by nlinarith [sq_nonneg (n - 2), hn2]
    nlinarith
  interval_cases n <;> norm_num at hn

/-- 有理数里同样解释不了：x² = 2 无有理根（与 Instances/RatToReal 的
    `rat_no_sqrt_two` 同款，经 ℚ ↪ ℝ 与 √2 的无理性）。 -/
theorem two_not_sq_rat : ¬ ∃ q : ℚ, (q : ℝ) ^ 2 = 2 := by
  rintro ⟨q, hq⟩
  have hs : (Real.sqrt 2 : ℝ) ^ 2 = 2 := by rw [Real.sq_sqrt]; norm_num
  have hqsq : (q : ℝ) ^ 2 = (Real.sqrt 2) ^ 2 := hq.trans hs.symm
  rcases sq_eq_sq_iff_eq_or_eq_neg.mp hqsq with h | h
  · exact irrational_sqrt_two ⟨q, h⟩
  · exact irrational_sqrt_two ⟨-q, by rw [Rat.cast_neg, h, neg_neg]⟩

/-- 开方族解释 2：(√2)² = 2 —— 幂族解释不了的数，开方族给出精确公式。 -/
example : (Real.sqrt 2 : ℝ) ^ 2 = 2 := by
  rw [Real.sq_sqrt]
  norm_num

/-- 指数/对数族解释 2：e^(ln 2) = 2 —— 另一条路也走得通，但公式与根式路径不同。 -/
example : Real.exp (Real.log 2) = 2 := by
  rw [Real.exp_log]
  norm_num

/-- 特殊的可解公式：x² − x − 1 = 0，用开方解出 x = (1 + √5)/2（黄金分割）。 -/
noncomputable def radicalGolden : ℝ := (1 + Real.sqrt 5) / 2

/-- 机器验证这个开方公式确实解出方程：φ² = φ + 1。 -/
theorem radicalGolden_sq : radicalGolden ^ 2 = radicalGolden + 1 := by
  dsimp [radicalGolden]
  have hs : (Real.sqrt 5 : ℝ) ^ 2 = 5 := by rw [Real.sq_sqrt]; norm_num
  ring_nf
  rw [hs]
  ring

/-- 同样的 3：开方给 (√3)² = 3，指数/对数给 e^(ln 3) = 3 —— 公式不同。 -/
example : (Real.sqrt 3 : ℝ) ^ 2 = 3 := by
  rw [Real.sq_sqrt]
  norm_num

example : Real.exp (Real.log 3) = 3 := by
  rw [Real.exp_log]
  norm_num

end NODS
