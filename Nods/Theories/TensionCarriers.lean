/-
【理论层】张力计数法扩到具体载体：实数 · 虚数 · 隐数
========================================================

出关定理（`TensionAbstract.forced_carrier_agnostic`）说：**任何** `supp : X → Finset A`
都给出一套 TCM，张力被同一条公式逼出。于是「扩到载体 X」这个问题，**只剩下一个问号**：

> **X 自己的、内蕴的「原子分解」在哪里？**

本文件逐个回答，并把答案落成可以编译的定理：

  · **虚数 → ℤ[i]（高斯整数）**，不是 ℂ。
    ℂ 是**域**，域里非零元都是单位、没有不可约元（`complex_no_atoms`）——
    乘法结构里根本没有「原子」可言。而 ℤ[i] 是**唯一分解环**，高斯素数就是它的原子。
    ⇒ `gaussDecomp`：一行实例。
  · **ℚ**（ℝ 之前的中转站）：**域也能有原子** —— `num/den` 是典范的，
    原子的读法就是「分子的素因子」+「分母的素因子」（两者必须分开）。
    ⇒ `ratDecomp`。这说明挡路的不是「是不是域」，是「有没有内蕴的有限分解」。
  · **ℝ / ℂ（作为域）**：**乘法路不通（定理）**。域里没有原子
    （`field_no_atoms` / `real_no_atoms`）。所以扩到实数，原子分解不可能来自 ℝ 自己的乘法：
      要么借子结构 ℤ（那就退化成 ℤ 的实例），
      要么换**非乘法**读数（连分数 / 序）—— 但连分数给的是**序列**，不是有限集；
      要截断就引入了选择，破坏 T1（直接性）。
    ⇒ **「ℝ 上的内蕴有限原子分解」是一个真缺口**：不是没找到，是乘法路被定理堵死、
      非乘法路要先把抽象从 `Finset` 升级。这是本文件最诚实的一条结论。
  · **隐数（HIBS）**：`Hidden = ⟨val : ℤ, tag ∈ {S, R, iR}⟩` ⇒ 原子 =
    **`val` 的素因子（左） + 标签本身一条（右）**。⇒ `hiddenDecomp`。
    三条 tag 公理给出的天然读数：标签不是坐标，它是一条**原子**。
-/

import Nods.Theories.TensionAbstract

namespace NODS

/- ------------------------------------------------------------------ -/
/- 1. 接口：原子分解载体（TCM 需要且仅需要的结构）                       -/
/- ------------------------------------------------------------------ -/

/-- **原子分解载体**：载体 `X` + 一个把元素读成「原子有限集」的内蕴分解 `supp`。
    TCM 需要的全部结构性输入就是这一个 —— 不需要环、序、度量、乘法。 -/
structure AtomicDecomp (X : Type*) (A : Type*) where
  /-- 内蕴原子分解：把载体元素读成原子有限集 -/
  supp : X → Finset A

/-- **免费 TCM**：给了原子分解，逼出定理直接可用 —— 不用重证。 -/
theorem AtomicDecomp.forced {X A : Type*} [DecidableEq A] (D : AtomicDecomp X A)
    (τ : AddTension) (h5 : τ.SelfZero) (h7 : τ.Unit) (h4 : τ.Reciprocal)
    (h3b : τ.NonfullCrit) (a b : X) :
    τ.grade (profileOf (D.supp a) (D.supp b)) = setTension (D.supp a) (D.supp b)
      ∨ τ.grade (profileOf (D.supp a) (D.supp b)) = -setTension (D.supp a) (D.supp b) :=
  forced_carrier_agnostic D.supp τ h5 h7 h4 h3b a b

/- ------------------------------------------------------------------ -/
/- 2. 实例：ℕ / ℤ / ℚ                                                -/
/- ------------------------------------------------------------------ -/

/-- ℕ：原子 = 素数（唯一分解）。 -/
def natDecomp : AtomicDecomp ℕ ℕ := ⟨supp⟩

/-- ℤ：原子 = `|z|` 的素数。 -/
def intDecomp : AtomicDecomp ℤ ℕ := ⟨suppZ⟩

/-- ℚ 的原子：`Sum.inl p` = 分子里的素数 `p`，`Sum.inr p` = 分母里的素数 `p`。
    两者**必须分开** —— `1/2` 与 `2/1` 是不同读数。 -/
def suppQ (q : ℚ) : Finset (ℕ ⊕ ℕ) :=
  (q.num.natAbs.primeFactors.image Sum.inl) ∪ (q.den.primeFactors.image Sum.inr)

/-- ℚ：**域也能有内蕴原子**（靠典范的 `num/den`）——
    ⇒ 挡住「扩到实数」的不是「是不是域」，是「有没有内蕴有限分解」。 -/
def ratDecomp : AtomicDecomp ℚ (ℕ ⊕ ℕ) := ⟨suppQ⟩

/- ------------------------------------------------------------------ -/
/- 3. 虚数 → ℤ[i]（高斯整数）：它不是域，是唯一分解环                    -/
/- ------------------------------------------------------------------ -/

/-- ℤ[i] 的原子：Mathlib 的典范分解（高斯素数），去重成集合。 -/
noncomputable def suppG (z : GaussianInt) : Finset GaussianInt :=
  (UniqueFactorizationMonoid.factors z).toFinset

/-- **虚数的正确落点是 ℤ[i]，不是 ℂ。**
    ℤ[i] 是唯一分解环 ⇒ 高斯素数就是它的原子 ⇒ 一行实例。 -/
noncomputable def gaussDecomp : AtomicDecomp GaussianInt GaussianInt := ⟨suppG⟩

/-- 套用（不重证）。 -/
theorem instance_gaussianint (τ : AddTension) (h5 : τ.SelfZero) (h7 : τ.Unit)
    (h4 : τ.Reciprocal) (h3b : τ.NonfullCrit) (a b : GaussianInt) :
    τ.grade (profileOf (suppG a) (suppG b)) = setTension (suppG a) (suppG b)
      ∨ τ.grade (profileOf (suppG a) (suppG b)) = -setTension (suppG a) (suppG b) :=
  forced_carrier_agnostic suppG τ h5 h7 h4 h3b a b

/- ------------------------------------------------------------------ -/
/- 4. 隐数（HIBS）：⟨val : ℤ, tag⟩ ⇒ 原子 = 素因子 + 标签                 -/
/- ------------------------------------------------------------------ -/

/-- 隐数的标签：HIBS 三公理里的三条射线（S = 加性实射线，R = 乘性射线，iR = 虚射线）。
    对应 `~/Downloads/lean/HIBS` 的 `Hidden.tag`。 -/
inductive Tag where
  /-- 加性实射线 -/
  | S
  /-- 乘性射线 -/
  | R
  /-- 虚射线 -/
  | iR
  deriving DecidableEq, Repr

/-- 隐数：`⟨整数部分, 标签⟩` —— HIBS `Hidden = ⟨val : Int, tag⟩` 的极简版。 -/
structure Hidden where
  /-- 整数部分 -/
  val : ℤ
  /-- 所属射线（标签） -/
  tag : Tag

/-- **隐数的原子**：左边是 `val` 的素因子（数的那一部分），
    右边是**标签本身一条** —— 标签不是坐标，它是一条原子。 -/
def suppH (h : Hidden) : Finset (ℕ ⊕ Tag) :=
  (h.val.natAbs.primeFactors.image Sum.inl) ∪ {Sum.inr h.tag}

/-- **隐数的原子分解** ⇒ 免费 TCM。 -/
def hiddenDecomp : AtomicDecomp Hidden (ℕ ⊕ Tag) := ⟨suppH⟩

/-- 同值、不同标签：两边各独有一条（**对方的标签**），扳平 ⇒ 张力为零。
    与数上的 `2` 对 `3` 是同一种平衡 —— 互不相干但势均力敌。 -/
theorem hidden_tag_balanced :
    setTension (suppH ⟨6, Tag.S⟩) (suppH ⟨6, Tag.R⟩) = 0 := by native_decide

/-- 同值、同标签 ⇔ 读数完全相同 ⇒ 张力为零（自零 T5 在隐数上的体现）。 -/
theorem hidden_self_zero (v : ℤ) (t : Tag) :
    setTension (suppH ⟨v, t⟩) (suppH ⟨v, t⟩) = 0 := by
  simp [setTension]

/- ------------------------------------------------------------------ -/
/- 5. 障碍（定理）：ℝ / ℂ 作为域，乘法路没有原子                        -/
/- ------------------------------------------------------------------ -/

/-- **域没有原子**：域里非零元都是单位，故都不是不可约元。
    ⇒ 原子分解**不可能**来自一个域的乘法结构。 -/
theorem field_no_atoms {K : Type*} [Field K] {x : K} (hx : x ≠ 0) : ¬ Irreducible x := by
  intro h
  exact h.not_isUnit (isUnit_iff_ne_zero.mpr hx)

/-- **ℝ 的乘法路障碍**：`x ≠ 0 ⇒ x` 不是原子。 -/
theorem real_no_atoms {x : ℝ} (hx : x ≠ 0) : ¬ Irreducible x := field_no_atoms hx

/-- **ℂ 的乘法路障碍**：同上 —— 这就是「扩到虚数」不能落在 ℂ 上的原因，
    要落到 ℤ[i]（`gaussDecomp`）。 -/
theorem complex_no_atoms {z : ℂ} (hz : z ≠ 0) : ¬ Irreducible z := field_no_atoms hz

/-- **ℝ 上仍然可用的路**：有理点继承 ℚ 的内蕴原子分解（ℝ ⊃ ℚ 那一支）。
    ℝ 自己没有原子，但它的有理性子结构有。 -/
theorem instance_real_on_rationals (τ : AddTension) (h5 : τ.SelfZero) (h7 : τ.Unit)
    (h4 : τ.Reciprocal) (h3b : τ.NonfullCrit) (a b : ℚ) :
    τ.grade (profileOf (suppQ a) (suppQ b)) = setTension (suppQ a) (suppQ b)
      ∨ τ.grade (profileOf (suppQ a) (suppQ b)) = -setTension (suppQ a) (suppQ b) :=
  forced_carrier_agnostic suppQ τ h5 h7 h4 h3b a b

end NODS
