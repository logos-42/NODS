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

本文件把这条区分拆成三个可证的目标（当前为签名，待补证明）：

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
/- 三个目标（签名，待证）                                              -/
/- ------------------------------------------------------------------ -/

/-- 定理 1：幂映射 `x ↦ xⁿ` 的核恰是 n 次单位根群 μₙ。 -/
theorem powMap_ker_eq_nRoots (n : ℕ) (G : Type u) [CommGroup G] :
    MonoidHom.ker (powMonoidHom (α := G) n) = nRoots n G := by
  sorry

/-- 定理 2：`zⁿ = xⁿ` 当且仅当 `z` 落在陪集 `x · μₙ` 里（逐点形式）。
    即 `xⁿ` 的全部 n 次根 = `{x · ζ | ζⁿ = 1}`。 -/
theorem powMap_fiber_iff (n : ℕ) (G : Type u) [CommGroup G] (x z : G) :
    z ^ n = x ^ n ↔ ∃ ζ : G, ζ ^ n = 1 ∧ z = x * ζ := by
  sorry

/-- 定理 3：幂映射单射（即开方单值、可退化成「分数次幂」）当且仅当
    μₙ 平凡（无 n 次非平凡单位根）。这是「塌缩条件」的精确形式。 -/
theorem powMap_injective_iff_nRoots_trivial (n : ℕ) (G : Type u) [CommGroup G] :
    Function.Injective ((powMonoidHom (α := G) n) : G → G) ↔ nRoots n G = ⊥ := by
  sorry

/- ------------------------------------------------------------------ -/
/- 两个示范特化（待后续补，需 ℝ₊ / ℂˣ 的群结构与有限性）              -/
/- ------------------------------------------------------------------ -/

-- 特化 1（塌缩侧）：正实数乘法群 ℝ₊ 无挠，故 μₙ 平凡、pₙ 单射 —— 开方单值。
-- example (n : ℕ) : nRoots n {x : ℝ // 0 < x} = ⊥ := by sorry

-- 特化 2（分歧侧）：ℂ 的单位根群 μₙ 有 n 个元素，故 pₙ n 对 1 —— 开方 n 值。
-- example (n : ℕ) : Nat.card (nRoots n ℂˣ) = n := by sorry

end NODS
