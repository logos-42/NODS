/-
【理论层】对合与临界线：`Re = 1/2` 的形状
============================================

塌缩定理说：张力 = 条数差（`Nods/Theories/TensionReading.lean`）。那 `Re = 1/2` 这种
**中心线**从哪来？

本层的回答：**临界线 = 一个内蕴对合的不动点集**（对合的固定集 = 它的中心）。

一个对合 `ι`（`ι∘ι = id`）把载体切成 2-元轨道 `{a, ι a}`；轨道在「自己与自己配对」处
退化成一个点 —— 那里正是**中心**，也正是（按塌缩）**张力为零**的地方。

最要紧的例子：**反转对合** `revI c x := c − x`（尺度对称的「反转」）。

| 载体 | 中心（`c − x = x` 的解） | 结论 |
|------|------------------------|------|
| `ℤ`  | 存在 ⟺ `c` 为**偶**（要中点，载体里必须有 `1/2`） | `revZ_exists_fix_iff_even` |
| `ℤ`，`c = 1` | **不存在**（`1` 是奇数） | `revZ_one_no_center` |
| `ℚ`  | 恒存在，就是 `c/2` | `revQ_fix_iff` |
| `ℚ`，`c = 1` | 恰是 `1/2` | **`revQ_one_fix_iff_half`** |
| `ℕ`  | 连对合都不是（截断减法爆掉） | `nat_reversal_not_involutive` |

⇒ **`Re = 1/2` = 「`1 − x`」这个对合的不动点。** ζ 的函数方程 `s ↦ 1 − s` 的不动点
正是 `Re = 1/2`；而「`1/2`」只在 **2 可逆**的载体里存在 —— 这就是为什么这条路必须走出 `ℕ`/`ℤ`。

## 本层给什么、不给什么（诚实边界）

给：**临界线的形状** —— 中心 = 对合的固定集；中心处张力为零；`1/2` 的存在条件。
不给：**RH 本身**。零点落在线上是关于那个固定集的*进一步*陈述，需要真的 ζ（函数方程、
解析延拓、零点计数），本层一个字都没碰到。

本层的意义在于**把缺件说准**：通往 Riemann 形状最短的路缺的不是「更强的计数公理」，
而是**一个对合 + 载体里的 `1/2`**。

## 本层内容

  1. `IsInvolution` / `fixOf`（中心）/ `mem_fixOf` / `fixOf_invariant`
  2. `selfdual_tension_zero` —— 中心处张力为零（塌缩定理的直接后果）
  3. `revZ`（ℤ 上的反转）：对合 / 不动点方程 / **中心存在 ⟺ `c` 偶** / **`c=1` 无中心**
  4. `revQ`（ℚ 上的反转）：对合 / 中心 = `c/2` / **`c=1` 时中心 = `1/2`**
  5. `no_fix_no_center` —— 没有不动点就没有中心
  6. `nat_reversal_not_involutive` —— `ℕ` 上截断减法连对合都不是
-/

import Nods.Theories.TensionReading

namespace NODS

/- ------------------------------------------------------------------ -/
/- 1. 对合与中心                                                       -/
/- ------------------------------------------------------------------ -/

/-- **对合**：自己与自己配对（`ι∘ι = id`）。这正是「自对偶」的精确意思。 -/
def IsInvolution {X : Type*} (ι : X → X) : Prop := Function.Involutive ι

/-- **中心**：对合的不动点集（自对偶点）。「临界线」在本层就是它。 -/
def fixOf {X : Type*} (ι : X → X) : Set X := {a | ι a = a}

theorem mem_fixOf {X : Type*} {ι : X → X} {a : X} : a ∈ fixOf ι ↔ ι a = a :=
  Iff.rfl

/-- 中心是 `ι`-不变的：`a` 自对偶 ⟹ `ι a` 也自对偶。 -/
theorem fixOf_invariant {X : Type*} {ι : X → X} (h : IsInvolution ι) {a : X}
    (ha : a ∈ fixOf ι) : ι a ∈ fixOf ι := by
  rw [mem_fixOf] at ha ⊢
  rw [h a, ha]

/-- 对合单射（配对是双射）。 -/
theorem IsInvolution.injective {X : Type*} {ι : X → X} (h : IsInvolution ι) :
    Function.Injective ι := Function.Involutive.injective h

/-- **没有不动点就没有中心**。 -/
theorem no_fix_no_center {X : Type*} {ι : X → X} (h : ∀ a : X, ι a ≠ a) : fixOf ι = ∅ := by
  ext a
  simp only [Set.mem_empty_iff_false, iff_false]
  exact h a

/- ------------------------------------------------------------------ -/
/- 2. 中心处张力为零（塌缩定理的直接后果）                              -/
/- ------------------------------------------------------------------ -/

/-- **自对偶处张力为零**：`a` 落在中心（`ι a = a`）⟹ 它与自己的配对者的张力为零。

    按塌缩定理 `τ = 条数差`：中心处两侧是同一个点，条数当然相同 ⟹ 张力为零。
    （反向不成立：条数相同的非不动点对也张力为零 —— 中心是零轨迹的真子集。） -/
theorem selfdual_tension_zero {X : Type*} (R : AtomicReading X) (τ : AddTension)
    (h5 : τ.SelfZero) (h7 : τ.Unit) (h4 : τ.Reciprocal) (h3b : τ.NonfullCrit)
    {ι : X → X} {a : X} (ha : ι a = a) :
    τ.grade (R.toProfile a (ι a)) = 0 := by
  rw [ha]
  exact R.size_only τ h5 h7 h4 h3b a a rfl

/- ------------------------------------------------------------------ -/
/- 3. ℤ 上的反转：中心存在 ⟺ 载体里有 1/2                                -/
/- ------------------------------------------------------------------ -/

/-- **反转**：`ι(x) = c − x`（尺度对称：把 `x` 反射到另一半）。 -/
def revZ (c x : ℤ) : ℤ := c - x

/-- 反转是**对合**（自对偶）。 -/
theorem revZ_involutive (c : ℤ) : IsInvolution (revZ c) := by
  intro x
  simp only [revZ]
  ring

/-- 不动点方程：`c − x = x ⟺ 2x = c`。 -/
theorem revZ_fix_iff (c x : ℤ) : revZ c x = x ↔ 2 * x = c := by
  simp only [revZ]
  constructor <;> intro h <;> omega

/-- **中心存在 ⟺ `c` 为偶**：要「中点」，载体里必须**有 `1/2`**（ℤ 里没有）。 -/
theorem revZ_exists_fix_iff_even (c : ℤ) : (∃ x : ℤ, revZ c x = x) ↔ Even c := by
  constructor
  · rintro ⟨x, hx⟩
    rw [revZ_fix_iff] at hx
    exact ⟨x, by omega⟩
  · rintro ⟨r, hr⟩
    exact ⟨r, by rw [revZ_fix_iff]; omega⟩

/-- **`ℤ` 上没有 `1/2`，所以「`1 − x`」的对合没有中心**（`1` 是奇数）。
    —— 「临界线」在整数上不存在，不是因为公式不对，是因为载体缺 `1/2`。 -/
theorem revZ_one_no_center : ¬ ∃ x : ℤ, revZ 1 x = x := by
  rw [revZ_exists_fix_iff_even]
  decide

/- ------------------------------------------------------------------ -/
/- 4. ℚ 上的反转：中心 = c/2；Re = 1/2 的形状                            -/
/- ------------------------------------------------------------------ -/

/-- **反转**（ℚ 版）。 -/
def revQ (c x : ℚ) : ℚ := c - x

theorem revQ_involutive (c : ℚ) : IsInvolution (revQ c) := by
  intro x
  simp only [revQ]
  ring

/-- **中心恒存在，就是 `c/2`**（因为 ℚ 里 `2` 可逆）。 -/
theorem revQ_fix_iff (c x : ℚ) : revQ c x = x ↔ x = c / 2 := by
  simp only [revQ]
  constructor <;> intro h <;> linarith

/-- **`Re = 1/2` 的形状**：`1 − x = x ⟺ x = 1/2`。

    ζ 的函数方程 `s ↦ 1 − s` 也是这样一个反转对合；它的不动点正是 `Re = 1/2`。
    本定理给的是那个「`1/2`」在张力语言里的样子：**中心 = 对合的不动点**。 -/
theorem revQ_one_fix_iff_half (x : ℚ) : revQ 1 x = x ↔ x = 1 / 2 := by
  rw [revQ_fix_iff]

/- ------------------------------------------------------------------ -/
/- 5. ℕ 上连对合都拿不到                                                -/
/- ------------------------------------------------------------------ -/

/-- **`ℕ` 上「反转」不是对合**：截断减法 `c − x` 在 `x > c` 处爆成 `0`，
    于是 `ι(ι x) ≠ x`。⇒ `ℕ` 连一个可用的中心线都构造不出来。 -/
theorem nat_reversal_not_involutive (c : ℕ) : ¬ IsInvolution (fun x : ℕ => c - x) := by
  intro h
  have hc := h (c + 1)
  simp only [Nat.sub_eq_zero_of_le (Nat.le_succ c), Nat.sub_zero] at hc
  omega

end NODS
