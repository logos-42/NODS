/-
【理论层】扩到 ℝ 与 ℂ：代数数的「次数读数」
==============================================

前一层（`Nods/Theories/TensionCarriers.lean`）证明：ℝ / ℂ 作为**域**没有乘法原子
（`field_no_atoms` / `real_no_atoms` / `complex_no_atoms`）—— 乘法路彻底堵死。

本层换一条路：**不数因子，数「共轭」。**

## 读数

对代数数 `x`（`IsIntegral ℚ x`），**极小多项式** `minpoly ℚ x` 是本征的（monic、不可约），
它的次数 `[ℚ(x) : ℚ]` 就是 `x` 的**共轭个数** —— 一个内蕴的有限数。

```
条数 size(x) := deg (minpoly ℚ x)        （= 共轭个数 = 域扩张次数）
共享 share(x,y) := 极小多项式相同时取全部，否则 0
```

⇒ 按塌缩定理（`AtomicReading.collapse_four`）：

```
τ(x, y) = deg x − deg y                 张力 = 次数差
```

## 一次定义，两个载体

`algReading` 只要求 `L` 是 ℚ 的域扩张 ⟹ **ℝ 与 ℂ 共用同一个读数**：

- `algReadingR` —— ℝ 的代数部分。这是「扩到 ℝ」的正面回答。
- `algReadingC` —— ℂ 的代数部分。注意它与 ℤ[i] 那次是**同一载体的另一个读数**
  （ℤ[i] 数高斯素数，本层数共轭）⟹ **同一载体可以有多个读数，读数不同、张力不同**；
  但每个读数内部，张力仍被公理逼死。

## 诚实边界（三条）

1. **超越数仍进不来**：没有有限极小多项式 ⟹ 没有有限条数。进的是 ℝ/ℂ 的**代数部分**。
   ⇒ 早先「ℝ 的缺口是结构性的」需要**修正**：不是「ℝ 完全进不来」，而是
   **ℝ 的非代数部分进不来** —— 代数部分有一条内蕴的路（次数），而这条路不是乘法。
2. **次数读数很粗**：有理数全是 1 条 ⟹ **有理数之间张力恒为零**；
   共轭的数（极小多项式相同）也全共享。这是**读数的分辨率**问题，不是公理的问题。
3. **`share` 取「极小多项式相同」而非「共同因子的次数」**：更细的 gcd 版本需要多项式 gcd
   的归一化引理（`gcd m m = m`）；而按塌缩定理，**共享项对张力毫无影响**，故不必要。
-/

import Nods.Theories.TensionOptimal

namespace NODS

/-- **代数数读数**：对任何 ℚ 的域扩张 `L`，
    条数 = 极小多项式的次数（共轭个数），共享 = 极小多项式相同时全共享、否则零。 -/
noncomputable def algReading (L : Type*) [Field L] [Algebra ℚ L] :
    AtomicReading {x : L // IsIntegral ℚ x} where
  share x y :=
    if minpoly ℚ (x : L) = minpoly ℚ (y : L) then (minpoly ℚ (x : L)).natDegree else 0
  size x := (minpoly ℚ (x : L)).natDegree
  share_le_size x y := by
    by_cases h : minpoly ℚ (x : L) = minpoly ℚ (y : L)
    · simp only [if_pos h]; exact le_rfl
    · simp only [if_neg h]; exact Nat.zero_le _
  share_comm x y := by
    by_cases h : minpoly ℚ (x : L) = minpoly ℚ (y : L)
    · rw [if_pos h, if_pos h.symm, h]
    · have h' : ¬ (minpoly ℚ (y : L) = minpoly ℚ (x : L)) := fun hh => h hh.symm
      rw [if_neg h, if_neg h']
  share_self x := by rw [if_pos rfl]

/-- **ℝ 的代数部分。** -/
noncomputable abbrev algReadingR : AtomicReading {x : ℝ // IsIntegral ℚ x} := algReading ℝ

/-- **ℂ 的代数部分。** -/
noncomputable abbrev algReadingC : AtomicReading {x : ℂ // IsIntegral ℚ x} := algReading ℂ

/- ------------------------------------------------------------------ -/
/- 1. 主定理：张力 = 次数差                                          -/
/- ------------------------------------------------------------------ -/

/-- **扩到 ℝ/ℂ 的主定理**：代数数之间的张力只能是**次数差**（或反号）。

    注意这里用的是**优化后的公理表** —— 只要 `T6 + T7 + T4′ + T3b`，
    **不需要 T5**（`AtomicReading.collapse_four`）。 -/
theorem alg_tension_is_degree_diff {L : Type*} [Field L] [Algebra ℚ L] (τ : AddTension)
    (h7 : τ.Unit) (h4 : τ.Reciprocal) (h3b : τ.NonfullCrit)
    (x y : {x : L // IsIntegral ℚ x}) :
    τ.grade ((algReading L).toProfile x y) = (((algReading L).size x : ℕ) : ℤ)
        - (((algReading L).size y : ℕ) : ℤ)
      ∨ τ.grade ((algReading L).toProfile x y) = (((algReading L).size y : ℕ) : ℤ)
        - (((algReading L).size x : ℕ) : ℤ) :=
  AtomicReading.collapse_four (algReading L) τ h7 h4 h3b x y

/-- 条数相同的两个代数数张力为零 —— **特别地，有理数之间全平衡**（见下）。
    注意：这里**不需要 T5**（`collapse_four` 用的是优化后的四条表）。 -/
theorem alg_tension_zero_of_same_size {L : Type*} [Field L] [Algebra ℚ L] (τ : AddTension)
    (h7 : τ.Unit) (h4 : τ.Reciprocal) (h3b : τ.NonfullCrit)
    (x y : {x : L // IsIntegral ℚ x}) (h : (algReading L).size x = (algReading L).size y) :
    τ.grade ((algReading L).toProfile x y) = 0 := by
  rcases AtomicReading.collapse_four (algReading L) τ h7 h4 h3b x y with h' | h'
  · rw [h', h]; ring
  · rw [h', h]; ring

/- ------------------------------------------------------------------ -/
/- 2. 有理数的条数 = 1                                                -/
/- ------------------------------------------------------------------ -/

/-- **有理数的条数是 1**：`minpoly ℚ ((a : ℚ) : ℝ) = X − a`，次数 1。 -/
theorem natDegree_minpoly_rat_real (a : ℚ) :
    (minpoly ℚ ((algebraMap ℚ ℝ) a)).natDegree = 1 := by
  rw [minpoly.eq_X_sub_C ℝ a, Polynomial.natDegree_X_sub_C]

/-- 同上（ℂ 版）。 -/
theorem natDegree_minpoly_rat_complex (a : ℚ) :
    (minpoly ℚ ((algebraMap ℚ ℂ) a)).natDegree = 1 := by
  rw [minpoly.eq_X_sub_C ℂ a, Polynomial.natDegree_X_sub_C]

/- ------------------------------------------------------------------ -/
/- 3. 用极小多项式算条数（把 n 次开方的条数一次算完）                    -/
/- ------------------------------------------------------------------ -/

/-- **若极小多项式形如 `Xⁿ − c`，则条数 = `n`**（`natDegree_X_pow_sub_C`）。
    典型例子：`√2` 的极小多项式是 `X² − 2` ⟹ 条数 2；`i` 的是 `X² + 1` ⟹ 条数 2。
    ——（这两个具体的极小多项式是标准代数事实，本层不重证不可约性。） -/
theorem size_of_minpoly_X_pow_sub_C {L : Type*} [Field L] [Algebra ℚ L]
    {x : {x : L // IsIntegral ℚ x}} {n : ℕ} {c : ℚ}
    (h : minpoly ℚ (x : L) = Polynomial.X ^ n - Polynomial.C c) :
    (algReading L).size x = n := by
  rw [show (algReading L).size x = (minpoly ℚ (x : L)).natDegree from rfl, h,
    Polynomial.natDegree_X_pow_sub_C]

end NODS
