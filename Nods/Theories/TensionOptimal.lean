/-
【理论层】公理体系优化：力只需三条，T5 出列
==============================================

## 优化了什么

TCM-2 的表是 6 条：`T1 + T2 + T6 + T7 + T4′ + T5 + T3b`（其中 T1/T2 是结构内建）。

本层证明：**T5（自零）对张力差毫无影响，可以从力公理表里摘掉。**

  1. `grade_linear_free` —— 不带任何假设的线性化：可加性本身就说张力差是
     三条计数（共享 / a 独有 / b 独有）的线性组合，各带一个整数系数。
  2. **`share_coeff_zero`** —— **T4′（反号）⟹ 共享项系数为零**。
     原来这一步靠 T5 做（自零：两力在 `(t,0,0)` 上各自为零）；现在证明**光靠反号就够**：
     全共享剖面上反号要求 `x = −x`，ℤ 里 ⟹ `x = 0`。
     ⇒ **T5 的作用只是把「两条力各自」钉住**（这对可观测的张力差没有影响）。
  3. `grade_eq_scale` —— **T6 + T4′ ⟹ 张力 = 刻度 × 条数差**（形状已定，只留一个整数刻度）。
  4. `scale_cases` —— **再加 T7（单位）⟹ 刻度 ∈ {−1, 0, +1}**。
  5. `forced_three` / `forced_four` —— **三条力公理（T6 + T4′ + T7）就逼出 ±条数差**
     （第三档 = 零力这个退化）；再加 T3b（非全）去掉退化。

## 优化后的表

| 层 | 内容 |
|----|------|
| 结构内建 | **T1 直接性**（力只吃两个数）+ **T2 二分力**（`grade := K − L`）+ **T6 可加**（`AddMonoidHom`） |
| **形状**（1 条） | **T4′ 反号** ⟹ `τ = 刻度 × 条数差`（刻度自由） |
| **刻度**（1 条） | **T7 单位** ⟹ 刻度 ∈ `{−1, 0, +1}` |
| **去退化**（1 条） | **T3b 非全** ⟹ 刻度 = `±1`（排除零力） |
| **出列** | **T5 自零** —— 只管「两条力各自」，对张力差无关（`share_coeff_zero` 证明反号自己就够了） |

> 读数层还额外出列一条：**自张力为零不是公理，而是读数的性质**
> （`share_self` ⟹ `onlyA_self` / `onlyB_self` ⟹ `toProfile_self`）。
-/

import Nods.Theories.TensionReading

namespace NODS

namespace AddTension

variable (τ : AddTension)

/- ------------------------------------------------------------------ -/
/- 1. 不带假设的线性化                                                -/
/- ------------------------------------------------------------------ -/

/-- **T6 的确切内容（不加任何其它公理）**：可加性 ⟹ 张力差是三条计数的线性组合。 -/
theorem grade_linear_free (u : ℕ × ℕ × ℕ) :
    τ.grade u = (u.1 : ℤ) * (τ.K (1, 0, 0) - τ.L (1, 0, 0))
              + (u.2.1 : ℤ) * (τ.K (0, 1, 0) - τ.L (0, 1, 0))
              + (u.2.2 : ℤ) * (τ.K (0, 0, 1) - τ.L (0, 0, 1)) := by
  simp only [grade, K_linear τ u, L_linear τ u]
  ring

/-- **主结果：T4′ 反号 ⟹ 共享项系数为零。**

    全共享剖面 `(t, 0, 0)` 反着读还是自己，故反号要求该处张力等于自己的相反数；
    ℤ 里只有 `0` 满足（`omega` 收尾）。

    ⇒ 共享条数**整条掉出张力的视野** —— 这件事**不需要 T5**。 -/
theorem share_coeff_zero (h4 : τ.Reciprocal) : τ.K (1, 0, 0) - τ.L (1, 0, 0) = 0 := by
  have h := h4 (1, 0, 0)
  have h' : τ.grade (1, 0, 0) = -τ.grade (1, 0, 0) := by simpa using h
  have hz : τ.grade (1, 0, 0) = 0 := by omega
  simpa only [grade] using hz

/-- **T6 + T4′ ⟹ 张力 = 刻度 × 条数差**（形状已定，只留一个整数刻度）。 -/
theorem grade_eq_scale (h4 : τ.Reciprocal) (u : ℕ × ℕ × ℕ) :
    τ.grade u = (τ.K (0, 1, 0) - τ.L (0, 1, 0)) * ((u.2.1 : ℤ) - (u.2.2 : ℤ)) := by
  have h1 : τ.K (1, 0, 0) - τ.L (1, 0, 0) = 0 := share_coeff_zero τ h4
  have h2 : τ.K (0, 0, 1) - τ.L (0, 0, 1) = -(τ.K (0, 1, 0) - τ.L (0, 1, 0)) := by
    have h := h4 (0, 1, 0)
    have h' : τ.grade (0, 0, 1) = -τ.grade (0, 1, 0) := by simpa using h
    simpa only [grade] using h'
  rw [grade_linear_free τ u, h1, h2]
  ring

/- ------------------------------------------------------------------ -/
/- 2. 刻度：T7 把它压到 −1 / 0 / +1                                    -/
/- ------------------------------------------------------------------ -/

/-- **T7（单位）⟹ 刻度只能取 `−1 / 0 / +1`**（每个素数对每个力至多贡献一条）。 -/
theorem scale_cases (h7 : τ.Unit) :
    τ.K (0, 1, 0) - τ.L (0, 1, 0) = -1 ∨ τ.K (0, 1, 0) - τ.L (0, 1, 0) = 0
      ∨ τ.K (0, 1, 0) - τ.L (0, 1, 0) = 1 := by
  obtain ⟨hKB, hKC, hLB, hLC⟩ := h7
  omega

/- ------------------------------------------------------------------ -/
/- 3. 三条公理逼出张力（T5 与 T3b 都不必假设）                          -/
/- ------------------------------------------------------------------ -/

/-- **逼出定理（三条版）**：只要 **T6 可加 + T4′ 反号 + T7 单位**，
    张力就只能是 `条数差`、其反号、或恒零（零力这个退化）。
    —— **不假设 T5，也不假设 T3b。** -/
theorem forced_three (h4 : τ.Reciprocal) (h7 : τ.Unit) :
    (∀ u : ℕ × ℕ × ℕ, τ.grade u = (u.2.1 : ℤ) - (u.2.2 : ℤ)) ∨
    (∀ u : ℕ × ℕ × ℕ, τ.grade u = (u.2.2 : ℤ) - (u.2.1 : ℤ)) ∨
    (∀ u : ℕ × ℕ × ℕ, τ.grade u = 0) := by
  rcases scale_cases τ h7 with h | h | h
  · right; left
    intro u; rw [grade_eq_scale τ h4 u, h]; ring
  · right; right
    intro u; rw [grade_eq_scale τ h4 u, h]; ring
  · left
    intro u; rw [grade_eq_scale τ h4 u, h]; ring

/-- **逼出定理（四条版 / 优化后的主定理）**：**T6 + T7 + T4′ + T3b ⇒ `τ = ±条数差`**
    —— 与旧的 `forced_unique` 结论相同，但**不再需要 T5**。 -/
theorem forced_four (h7 : τ.Unit) (h4 : τ.Reciprocal) (h3b : τ.NonfullCrit) :
    (∀ u : ℕ × ℕ × ℕ, τ.grade u = (u.2.1 : ℤ) - (u.2.2 : ℤ)) ∨
    (∀ u : ℕ × ℕ × ℕ, τ.grade u = (u.2.2 : ℤ) - (u.2.1 : ℤ)) := by
  rcases forced_three τ h4 h7 with h | h | h
  · exact Or.inl h
  · exact Or.inr h
  · obtain ⟨u, hu⟩ := h3b
    exact absurd (h u) hu

/-- 旧的 `forced_unique` 是它的一条推论 —— **`T5` 是个多余的假设**（注意参数带下划线）。 -/
theorem forced_unique_of_four (_h5 : τ.SelfZero) (h7 : τ.Unit) (h4 : τ.Reciprocal)
    (h3b : τ.NonfullCrit) :
    (∀ u : ℕ × ℕ × ℕ, τ.grade u = (u.2.1 : ℤ) - (u.2.2 : ℤ)) ∨
    (∀ u : ℕ × ℕ × ℕ, τ.grade u = (u.2.2 : ℤ) - (u.2.1 : ℤ)) :=
  forced_four τ h7 h4 h3b

/-- `NonfullCrit` 在三条公理之下**等价于**「刻度 ≠ 0」——
    所以 T3b 不是结构公理，只是「去零力」这个非退化要求。 -/
theorem nonfull_iff_scale_ne_zero (h4 : τ.Reciprocal) :
    τ.NonfullCrit ↔ τ.K (0, 1, 0) - τ.L (0, 1, 0) ≠ 0 := by
  constructor
  · intro h
    by_contra hq
    obtain ⟨u, hu⟩ := h
    exact hu (by rw [grade_eq_scale τ h4 u, hq]; ring)
  · intro hq
    exact ⟨(0, 1, 0), by rw [grade_eq_scale τ h4 (0, 1, 0)]; simp [hq]⟩

end AddTension

/- ------------------------------------------------------------------ -/
/- 4. 读数版：三条公理下的塌缩                                          -/
/- ------------------------------------------------------------------ -/

/-- **塌缩（三条版）**：任何读数上，**T6 + T4′ + T7** 就逼出 `τ = size a − size b`（或反号或零）。
    —— 不需要 T5、不需要 T3b。 -/
theorem AtomicReading.collapse_three {X : Type*} (R : AtomicReading X) (τ : AddTension)
    (h4 : τ.Reciprocal) (h7 : τ.Unit) (a b : X) :
    τ.grade (R.toProfile a b) = ((R.size a : ℕ) : ℤ) - ((R.size b : ℕ) : ℤ)
      ∨ τ.grade (R.toProfile a b) = (((R.size b : ℕ) : ℤ) - ((R.size a : ℕ) : ℤ))
      ∨ τ.grade (R.toProfile a b) = 0 := by
  rcases AddTension.forced_three τ h4 h7 with h | h | h
  · left
    rw [h (R.toProfile a b)]
    have h1 : R.share a b ≤ R.size a := R.share_le_size a b
    have h2 : R.share a b ≤ R.size b := R.share_le_size_right a b
    simp only [AtomicReading.toProfile, AtomicReading.onlyA, AtomicReading.onlyB]
    omega
  · right; left
    rw [h (R.toProfile a b)]
    have h1 : R.share a b ≤ R.size a := R.share_le_size a b
    have h2 : R.share a b ≤ R.size b := R.share_le_size_right a b
    simp only [AtomicReading.toProfile, AtomicReading.onlyA, AtomicReading.onlyB]
    omega
  · right; right; exact h (R.toProfile a b)

/-- **塌缩（四条版）**：加 T3b（去零力）⟹ 只剩两档（±条数差），仍**不需要 T5**。 -/
theorem AtomicReading.collapse_four {X : Type*} (R : AtomicReading X) (τ : AddTension)
    (h7 : τ.Unit) (h4 : τ.Reciprocal) (h3b : τ.NonfullCrit) (a b : X) :
    τ.grade (R.toProfile a b) = ((R.size a : ℕ) : ℤ) - ((R.size b : ℕ) : ℤ)
      ∨ τ.grade (R.toProfile a b) = (((R.size b : ℕ) : ℤ) - ((R.size a : ℕ) : ℤ)) := by
  rcases AddTension.forced_four τ h7 h4 h3b with h | h
  · left
    rw [h (R.toProfile a b)]
    have h1 : R.share a b ≤ R.size a := R.share_le_size a b
    have h2 : R.share a b ≤ R.size b := R.share_le_size_right a b
    simp only [AtomicReading.toProfile, AtomicReading.onlyA, AtomicReading.onlyB]
    omega
  · right
    rw [h (R.toProfile a b)]
    have h1 : R.share a b ≤ R.size a := R.share_le_size a b
    have h2 : R.share a b ≤ R.size b := R.share_le_size_right a b
    simp only [AtomicReading.toProfile, AtomicReading.onlyA, AtomicReading.onlyB]
    omega

/- ------------------------------------------------------------------ -/
/- 5. 读数把「自张力为零」接过来                                          -/
/- ------------------------------------------------------------------ -/

/-- **自张力为零是读数的性质，不是公理**：`share_self` ⟹ 对角线剖面 = `(size a, 0, 0)`，
    故两个「独有」都为零 —— 这正是 T5 声称的内容（在读数层）。 -/
theorem AtomicReading.self_tension_free {X : Type*} (R : AtomicReading X) (a : X) :
    R.onlyA a a = 0 ∧ R.onlyB a a = 0 :=
  ⟨R.onlyA_self a, R.onlyB_self a⟩

end NODS
