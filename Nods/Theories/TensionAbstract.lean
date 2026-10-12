/-
【理论层】张力计数法的载体抽象：从 ℕ 出关到「任何带原子分解的载体」
====================================================================

逼出定理（`Tension.AddTension.forced_unique`）其实**一个字都没用到素数、乘法、ℕ**。
它只用到一样东西：一对集合的三条计数

    profileOf S T := (|S ∩ T|, |S ∖ T|, |T ∖ S|)        —— 「原子读数」

于是可以整体出关：

  · **载体不必是 ℕ。** 任何类型 `X` 配一个「原子分解」`supp : X → Finset A`
    （`A` 可以是任何类型）都给出一套 TCM，且张力被同一条公式逼出。
  · **数只是供应商之一。** ℕ 通过**唯一分解**供应原子集合：`supp n = n` 的素因子集。
    换一个载体就换一种「原子」，公式不变。
  · **逼出是载体无关的**（那是定理），而**直接性（T1）要靠分解的内蕴性**：
    ℕ 上 `p ∈ supp n ↔ p 素 ∧ p ∣ n` —— 由整除关系定死，没有任何选择。

本文件给出：
  1. 抽象读数        `profileOf` / `setTension`
  2. **载体无关逼出**  `forced_carrier_agnostic`（主定理）
  3. 三个实例         ℕ（`dirTension` 直读）/ 任意有限集（`supp = id`）/ ℤ（一行套用）
  4. 直接性          `supp_intrinsic`（唯一分解 ⇒ 没有选择）

一句话：**TCM 的载体不是「数」，是「原子集合」；数只是通过唯一分解供应原子集合的一种方式。**
-/

import Nods.Theories.Tension

namespace NODS

/- ------------------------------------------------------------------ -/
/- 1. 抽象读数：TCM 唯一需要的东西                                      -/
/- ------------------------------------------------------------------ -/

/-- **原子读数**：一对原子集合的三条计数（共享 / S 独有 / T 独有）。
    这是 TCM 唯一需要的输入 —— 与「载体是什么」「原子是什么」无关。 -/
def profileOf {A : Type*} [DecidableEq A] (S T : Finset A) : ℕ × ℕ × ℕ :=
  ((S ∩ T).card, (S \ T).card, (T \ S).card)

/-- **原子张力**：`τ(S,T) = |S∖T| − |T∖S|` —— 逼出结果在原子层的写法。 -/
def setTension {A : Type*} [DecidableEq A] (S T : Finset A) : ℤ :=
  ((S \ T).card : ℤ) - ((T \ S).card : ℤ)

/-- ℕ 的 `profile` 就是原子读数（`supp` 取素因子集）—— 抽象与具体在此对接。 -/
theorem profile_eq_profileOf (a b : ℕ) : profile a b = profileOf (supp a) (supp b) := rfl

/-- ℕ 上的张力**就是**支撑集合上的张力。 -/
theorem dirTension_eq_setTension (a b : ℕ) :
    dirTension.grade a b = setTension (supp a) (supp b) := rfl

/- ------------------------------------------------------------------ -/
/- 2. 载体无关的逼出定理（主定理）                                      -/
/- ------------------------------------------------------------------ -/

/-- **载体无关逼出定理**：设 `X` 是**任何**类型，`supp : X → Finset A` 是**任何**原子分解。
    则任何满足 TCM 公理（计数 + 界 / 反号 / 自零 / 非全）的计数张力，其张力只能是

        `|supp a ∖ supp b| − |supp b ∖ supp a|`      （唯一到取向）

    命题里的 `X`、`A`、`supp` 全是自由变量 —— 没有 ℕ、没有素数、没有乘法、没有序。
    也就是说：**逼出这件事跟载体是什么完全无关。** -/
theorem forced_carrier_agnostic {X A : Type*} (supp : X → Finset A) [DecidableEq A]
    (τ : AddTension) (h5 : τ.SelfZero) (h7 : τ.Unit) (h4 : τ.Reciprocal)
    (h3b : τ.NonfullCrit) (a b : X) :
    τ.grade (profileOf (supp a) (supp b)) = setTension (supp a) (supp b)
      ∨ τ.grade (profileOf (supp a) (supp b)) = -setTension (supp a) (supp b) := by
  rcases AddTension.forced_unique τ h5 h7 h4 h3b with h | h
  · left
    rw [h (profileOf (supp a) (supp b))]
    simp [profileOf, setTension]
  · right
    rw [h (profileOf (supp a) (supp b))]
    simp [profileOf, setTension]

/- ------------------------------------------------------------------ -/
/- 3. 三个实例：换载体不换公式                                          -/
/- ------------------------------------------------------------------ -/

/-- **实例 A（ℕ，素因子）**：原子 = 素数，`supp n = n` 的素因子集。
    TCM 的原始实例；数值例子见 `Tension.lean` §10。 -/
theorem instance_nat (τ : AddTension) (h5 : τ.SelfZero) (h7 : τ.Unit) (h4 : τ.Reciprocal)
    (h3b : τ.NonfullCrit) (a b : ℕ) :
    τ.grade (profileOf (supp a) (supp b)) = setTension (supp a) (supp b)
      ∨ τ.grade (profileOf (supp a) (supp b)) = -setTension (supp a) (supp b) :=
  forced_carrier_agnostic supp τ h5 h7 h4 h3b a b

/-- **实例 B（完全不是数）**：载体直接取「原子集合」本身，`supp = id`。
    张力 = 两个有限集的独有差。⇒ 张力计数法**与数无关**，ℕ 只是供应商之一。 -/
theorem instance_finset {A : Type*} [DecidableEq A] (τ : AddTension)
    (h5 : τ.SelfZero) (h7 : τ.Unit) (h4 : τ.Reciprocal) (h3b : τ.NonfullCrit)
    (S T : Finset A) :
    τ.grade (profileOf S T) = setTension S T ∨ τ.grade (profileOf S T) = -setTension S T :=
  forced_carrier_agnostic id τ h5 h7 h4 h3b S T

/-- 实例 C 的原子分解：`suppZ z = |z|` 的素因子集。 -/
def suppZ (z : ℤ) : Finset ℕ := z.natAbs.primeFactors

/-- **实例 C（ℤ）**：一行套用，**不用重证** —— 这就是抽象出来的收益。
    ℤ 有符号、有零、有负元，可原子分解一点没变。 -/
theorem instance_int (τ : AddTension) (h5 : τ.SelfZero) (h7 : τ.Unit) (h4 : τ.Reciprocal)
    (h3b : τ.NonfullCrit) (a b : ℤ) :
    τ.grade (profileOf (suppZ a) (suppZ b)) = setTension (suppZ a) (suppZ b)
      ∨ τ.grade (profileOf (suppZ a) (suppZ b)) = -setTension (suppZ a) (suppZ b) :=
  forced_carrier_agnostic suppZ τ h5 h7 h4 h3b a b

/- ------------------------------------------------------------------ -/
/- 4. 直接性（T1）的内蕴性：原子分解不是选的                            -/
/- ------------------------------------------------------------------ -/

/-- **`supp` 不是选的**：在 ℕ 上它由整除关系定死 ——

        `p ∈ supp n ↔ p 是素数 ∧ p ∣ n`（且 `n ≠ 0`）

    这就是 T1「直接性」为什么不是一条规定：原子分解由载体**自身结构**给出，
    不需要外部参数，也没有第二个选择（唯一分解）。换了载体，同样要找它自己的内蕴分解。 -/
theorem supp_intrinsic (n p : ℕ) : p ∈ supp n ↔ Nat.Prime p ∧ p ∣ n ∧ n ≠ 0 :=
  Nat.mem_primeFactors

end NODS
