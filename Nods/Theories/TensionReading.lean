/-
【理论层】张力计数法的读数升级：从 `Finset` 到「序列 / 自由幺半群」
====================================================================

上一层的载体接口是 `supp : X → Finset A`（**有限集分解**）。本层把它降为**读数**：

    读数 := (share : 两条共享多少条, size : 一条总共多少条)

只要求两件事：`share` 对称；`share ≤ size`。没有集合、没有偏序、没有交并差。

于是能当载体的东西一下子多了：有限集、**重集（自由交换幺半群）**、**序列（自由幺半群）**
—— 凡是能回答「两条共享多少条、各自总共多少条」的，都行。

## 本层最要紧的一个结果：塌缩

    τ(a,b) = size a − size b          （张力 = 两边的「条数」之差）

共享的那部分**必须约掉** —— 那正是 T5 自零在做的事。剩下的就只能是两边的**条数差**；
「收敛力 / 发散力」只是把条数差拆成两半的记账。

塌缩一出来，整件事的问法就干净了：

    扩到载体 X   ⟺   给 X 找一个内蕴的**条数** `size`

不必再找集合分解 —— **只要有「条数」。** 反过来，这条塌缩也说清了
「为什么共同点当不了收敛力」：共享项被 T5 强制消去，它进不了张力。

## 本层给出

  1. `AtomicReading`：读数接口（+ 独有 `onlyA`/`onlyB` + 剖面）
  2. `AtomicReading.forced`：任何读数上，张力被逼成 `onlyA − onlyB`（唯一到取向）
  3. `AtomicReading.collapse`：**塌缩定理** —— 张力 = 条数差
  4. `AtomicReading.size_only`：等条数 ⇒ 张力为零（**内容不可见**）
  5. 实例：`ofFinset`（上一层有限集接口 = 本层的一个特例）
     / `listLCP`（**序列 / 自由幺半群**：共享 = 最长公共前缀长度）
-/

import Nods.Theories.TensionCarriers

namespace NODS

/- ------------------------------------------------------------------ -/
/- 1. 读数接口                                                        -/
/- ------------------------------------------------------------------ -/

/-- **原子读数**：`share`（两条共享多少条）+ `size`（一条总共多少条），
    只要求 `share` 对称、`share ≤ size`。

    这就是 TCM 需要的**全部**结构性输入 —— 没有集合、没有交并差、没有序、没有乘法。
    有限集分解（上一层的 `AtomicDecomp`）只是它的一个特例：`share = |S∩T|`、`size = |S|`。 -/
structure AtomicReading (X : Type*) where
  /-- 两条共享多少条 -/
  share : X → X → ℕ
  /-- 一条总共多少条 -/
  size : X → ℕ
  /-- 共享不超过总量 -/
  share_le_size : ∀ a b, share a b ≤ size a
  /-- 共享是对称的 -/
  share_comm : ∀ a b, share a b = share b a

namespace AtomicReading

variable {X : Type*} (R : AtomicReading X)

/-- `a` 的独有条数 = 总条数 − 共享条数。 -/
def onlyA (a b : X) : ℕ := R.size a - R.share a b

/-- `b` 的独有条数。 -/
def onlyB (a b : X) : ℕ := R.size b - R.share a b

/-- 共享不超过**另一方**的总量（由对称性）。 -/
theorem share_le_size_right (a b : X) : R.share a b ≤ R.size b := by
  rw [R.share_comm a b]
  exact R.share_le_size b a

/-- 剖面：喂给逼出定理的三元组 `(共享, a 独有, b 独有)`。 -/
def toProfile (a b : X) : ℕ × ℕ × ℕ := (R.share a b, R.onlyA a b, R.onlyB a b)

/-- **逼出（读数版）**：在任何读数上，满足公理的计数张力只能是 `onlyA − onlyB`（唯一到取向）。 -/
theorem forced (τ : AddTension) (h5 : τ.SelfZero) (h7 : τ.Unit) (h4 : τ.Reciprocal)
    (h3b : τ.NonfullCrit) (a b : X) :
    τ.grade (R.toProfile a b) = ((R.onlyA a b : ℕ) : ℤ) - ((R.onlyB a b : ℕ) : ℤ)
      ∨ τ.grade (R.toProfile a b) = (((R.onlyB a b : ℕ) : ℤ) - ((R.onlyA a b : ℕ) : ℤ)) := by
  rcases AddTension.forced_unique τ h5 h7 h4 h3b with h | h
  · left
    rw [h (R.toProfile a b)]
    simp only [toProfile]
  · right
    rw [h (R.toProfile a b)]
    simp only [toProfile]

/-- **塌缩定理（本层主结果）**：共享条数必须约掉 —— 张力就是两边的**条数差**。

    这是「为什么共同点当不了收敛力」的正解：共享项被 T5 自零强制消去，
    张力只看得见两边的总条数。 -/
theorem collapse (τ : AddTension) (h5 : τ.SelfZero) (h7 : τ.Unit) (h4 : τ.Reciprocal)
    (h3b : τ.NonfullCrit) (a b : X) :
    τ.grade (R.toProfile a b) = ((R.size a : ℕ) : ℤ) - ((R.size b : ℕ) : ℤ)
      ∨ τ.grade (R.toProfile a b) = (((R.size b : ℕ) : ℤ) - ((R.size a : ℕ) : ℤ)) := by
  rcases R.forced τ h5 h7 h4 h3b a b with h | h
  · left
    rw [h]
    have h1 : R.share a b ≤ R.size a := R.share_le_size a b
    have h2 : R.share a b ≤ R.size b := R.share_le_size_right a b
    simp only [onlyA, onlyB]
    omega
  · right
    rw [h]
    have h1 : R.share a b ≤ R.size a := R.share_le_size a b
    have h2 : R.share a b ≤ R.size b := R.share_le_size_right a b
    simp only [onlyA, onlyB]
    omega

/-- **内容不可见**：条数相同 ⇒ 张力为零，不论「是哪些条」差多少。
    （大小相同但内容完全不同的两条，在张力上是平衡的。） -/
theorem size_only (τ : AddTension) (h5 : τ.SelfZero) (h7 : τ.Unit) (h4 : τ.Reciprocal)
    (h3b : τ.NonfullCrit) (a b : X) (h : R.size a = R.size b) :
    τ.grade (R.toProfile a b) = 0 := by
  rcases R.collapse τ h5 h7 h4 h3b a b with h' | h'
  · rw [h', h]; ring
  · rw [h', h]; ring

end AtomicReading

/- ------------------------------------------------------------------ -/
/- 2. 实例 A：有限集读数（上一层接口 = 本层特例）                        -/
/- ------------------------------------------------------------------ -/

/-- **有限集读数**：`share = |S∩T|`、`size = |S|`。
    ⇒ 上一层的 `AtomicDecomp`（`supp : X → Finset A`）是**本层的一个特例**。 -/
def AtomicReading.ofFinset {X A : Type*} [DecidableEq A] (supp : X → Finset A) :
    AtomicReading X where
  share a b := (supp a ∩ supp b).card
  size a := (supp a).card
  share_le_size a b := Finset.card_le_card Finset.inter_subset_left
  share_comm a b := by rw [Finset.inter_comm]

/- ------------------------------------------------------------------ -/
/- 3. 实例 B：序列（自由幺半群）—— 共享 = 最长公共前缀                  -/
/- ------------------------------------------------------------------ -/

/-- **最长公共前缀长度**（自由幺半群上的「共享条数」）。 -/
def lcpLen {α : Type*} [DecidableEq α] : List α → List α → ℕ
  | [], _ => 0
  | _, [] => 0
  | a :: as, b :: bs => if a = b then 1 + lcpLen as bs else 0

theorem lcpLen_le_left {α : Type*} [DecidableEq α] :
    ∀ s t : List α, lcpLen s t ≤ s.length
  | [], _ => by simp [lcpLen]
  | _ :: _, [] => by simp [lcpLen]
  | _ :: as, _ :: bs => by
      simp only [lcpLen]
      split
      · have h := lcpLen_le_left as bs
        simp only [List.length_cons]
        omega
      · exact Nat.zero_le _

theorem lcpLen_comm {α : Type*} [DecidableEq α] :
    ∀ s t : List α, lcpLen s t = lcpLen t s
  | [], [] => rfl
  | [], _ :: _ => rfl
  | _ :: _, [] => rfl
  | a :: as, b :: bs => by
      have ih := lcpLen_comm as bs
      simp only [lcpLen]
      by_cases h : a = b
      · simp [h, ih]
      · have h' : ¬ (b = a) := fun hba => h hba.symm
        simp [h, h']

/-- **序列读数（自由幺半群）**：`share` = 最长公共前缀长度、`size` = 长度。
    ⇒ 序列成了合法载体 —— 这是本轮升级要拿的东西。 -/
def AtomicReading.listLCP {α : Type*} [DecidableEq α] : AtomicReading (List α) where
  share := lcpLen
  size := List.length
  share_le_size := lcpLen_le_left
  share_comm := lcpLen_comm

/-- 序列上的张力：**就是两条序列的长度差** —— LCP 属于共享，被塌缩约掉。 -/
theorem list_tension_is_length_diff {α : Type*} [DecidableEq α] (τ : AddTension)
    (h5 : τ.SelfZero) (h7 : τ.Unit) (h4 : τ.Reciprocal) (h3b : τ.NonfullCrit)
    (s t : List α) :
    τ.grade (AtomicReading.listLCP.toProfile s t) = ((s.length : ℕ) : ℤ) - ((t.length : ℕ) : ℤ)
      ∨ τ.grade (AtomicReading.listLCP.toProfile s t)
          = (((t.length : ℕ) : ℤ) - ((s.length : ℕ) : ℤ)) :=
  AtomicReading.collapse AtomicReading.listLCP τ h5 h7 h4 h3b s t

/- ------------------------------------------------------------------ -/
/- 4. 塌缩在 ℕ 上的样子                                                 -/
/- ------------------------------------------------------------------ -/

/-- **塌缩在 ℕ 上**：张力 = 两边**不同素数的个数**之差 `ω(a) − ω(b)`。

    —— 这就是 §10 那些数值例子的最短算法：**数一数两边的素数条，相减**。
    （`60 vs 45`：`3 − 2 = 1`；`2 vs 3`：`1 − 1 = 0`；`30 vs 7`：`3 − 1 = 2`。） -/
theorem dirTension_grade_eq_omega_diff (a b : ℕ) :
    dirTension.grade a b = ((supp a).card : ℤ) - ((supp b).card : ℤ) := by
  show ((supp a \ supp b).card : ℤ) - ((supp b \ supp a).card : ℤ)
      = ((supp a).card : ℤ) - ((supp b).card : ℤ)
  have h1 : (supp a \ supp b).card = (supp a).card - (supp a ∩ supp b).card := by
    have := Finset.card_sdiff_add_card_inter (supp a) (supp b)
    omega
  have h3 : (supp b \ supp a).card = (supp b).card - (supp a ∩ supp b).card := by
    have := Finset.card_sdiff_add_card_inter (supp b) (supp a)
    rw [Finset.inter_comm (supp b) (supp a)] at this
    omega
  rw [h1, h3]
  have h4 : (supp a ∩ supp b).card ≤ (supp a).card :=
    Finset.card_le_card Finset.inter_subset_left
  have h5 : (supp a ∩ supp b).card ≤ (supp b).card :=
    Finset.card_le_card Finset.inter_subset_right
  omega

end NODS
