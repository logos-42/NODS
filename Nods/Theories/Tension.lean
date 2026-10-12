/-
【理论层】张力计数法 TCM-0：数字自身张力的极简公理 · ℕ 实例 · NODS 判定
========================================================================

TCM-0 想要的是「数字自身」的收敛力 / 发散力——不经由任何选定公式，只由数对
自身的算术结构决定，并带一个临界（零张力）流形。本文件把它落成三件事：

  1. 抽象公理层 `Tension D`
       T1 直接性   `K`/`L : D → D → ℤ`，只吃两个数，无外部函数参数（反度量）
       T2 二分力   张力 = 收敛力 `K` − 发散力 `L`（不是单一幅度）
       T3 临界流形  `grade = 0`，且真非平凡
       T4 方向性   允许 `grade a b ≠ grade b a`
       T5 退化     自临界：`grade a a = 0`

  2. ℕ 实例：radical 张力（`S = rad(a)` 的素因子集）
       `radTension`  `K = |S∩T|`，`L = |SΔT|`   —— wiki 现版
       `dirTension`  `K = |S\T|`，`L = |T\S|`   —— 有向版
       `symTension`  `K = |S∩T|`，`L = |S∪T|`

  3. NODS 判定（诚实的负结论——这才是本文件的价值所在）
       · `radTension_violates_T5`  自张力 = ω(a) ≠ 0：wiki 现版**内部矛盾**，T5 崩
       · `metric_not_nontrivial`   度量型「单幅度」张力的临界流形恒为对角线
                                   ⇒ 借来的结构（metric/order/divisibility）承载不了 T3′
       · `crit_manifold_not_unique` 两个都满足 T5+T3′ 的 intrinsic 实例，临界流形却不同
                                   ⇒ 公理不唯一确定 τ，也**不唯一确定临界流形**
       · `nods_verdict_nat`        汇总：ℕ 上本需求 = `solved`（同一载体可解），**不是 `gap`**

总纲（NODS）：**证明不了「被迫」，就只能说「我选了一个记号」。**
本文件证出的是后者在 ℕ 上的成立——把一个 candidate gap 诚实地降到 `solved`，
顺带暴露 wiki 现版的一条自相矛盾。
-/

import Mathlib

namespace NODS

universe u

/- ------------------------------------------------------------------ -/
/- 1. 抽象公理层：Tension 结构                                        -/
/- ------------------------------------------------------------------ -/

/-- **TCM-0 张力数据**（领域无关）。

    T1 直接性：`K`、`L` 是 `D → D → ℤ`——只吃两个数，没有任何外部函数作参数。
    这正是「反度量」公理：张力不许化名成某个选定的度量。
    T2 二分力：张力不是单一幅度，而是收敛力 `K` 与发散力 `L` 之差。 -/
structure Tension (D : Type u) where
  /-- 收敛力（两数共享的结构条数） -/
  K : D → D → ℤ
  /-- 发散力（两数各自独有的结构条数） -/
  L : D → D → ℤ

namespace Tension

variable {D : Type u}

/-- T2：张力差 `T_grade := K − L`。正 = 收敛主导，负 = 发散主导，零 = 临界。
    标 `reducible`：让 `Decidable`/`native_decide` 能看穿这层包装。 -/
@[reducible] def grade (τ : Tension D) (a b : D) : ℤ := τ.K a b - τ.L a b

/-- **T3 临界流形**：张力差为零的数对。 -/
@[reducible] def crit (τ : Tension D) (a b : D) : Prop := τ.grade a b = 0

/-- **T5 自临界（退化）**：每个数与自身临界。 -/
def SelfCritical (τ : Tension D) : Prop := ∀ a, τ.crit a a

/-- **T3′ 非平凡临界**：存在一对互异数临界。
    （T3 原文只说「非全非空」——对角线也满足，故要用它挡借来的结构必须加强到此。） -/
def NontrivialCrit (τ : Tension D) : Prop := ∃ a b, a ≠ b ∧ τ.crit a b

/-- **T4 方向性**：存在反号的数对——张力是「力」而不是「距离」。 -/
def Directional (τ : Tension D) : Prop := ∃ a b, τ.grade a b ≠ τ.grade b a

end Tension

/- ------------------------------------------------------------------ -/
/- 2. 借来的结构：度量型张力 ⇒ 临界流形 = 对角线（Lemma 1）          -/
/- ------------------------------------------------------------------ -/

/-- **Lemma 1（度量障碍）**：若张力是「单一幅度」的函数 `τ a b = f (d a b)`，
    其中 `d` 是忠实距离（`d a b = 0 ↔ a = b`）、`f` 只在 `0` 处取零，
    则临界成立于且仅成立于对角线。

    这就是「借来的结构」为何失效：metric 只能给出一个标量，标量的零集
    在忠实性下必然退化成 `a = b`——给不出 T3′ 要的非平凡临界流形。 -/
theorem metric_grade_eq_zero_iff {D : Type u} (d : D → D → ℤ)
    (hd : ∀ a b, d a b = 0 ↔ a = b) (f : ℤ → ℤ) (hf : ∀ x, f x = 0 ↔ x = 0) :
    ∀ a b, f (d a b) = 0 ↔ a = b := by
  intro a b
  rw [hf, hd]

/-- **Lemma 1（推论）**：度量型张力没有非对角临界对 ⇒ 承载不了 T3′。
    序结构（`a ≤ b ∧ b ≤ a ⟺ a = b`）与整除偏序（`a ∣ b ∧ b ∣ a ⟺ a = b`）
    同理——它们的「零集」都只是对角线。 -/
theorem metric_not_nontrivial {D : Type u} (d : D → D → ℤ)
    (hd : ∀ a b, d a b = 0 ↔ a = b) (f : ℤ → ℤ) (hf : ∀ x, f x = 0 ↔ x = 0) :
    ¬ ∃ a b : D, a ≠ b ∧ f (d a b) = 0 := by
  rintro ⟨a, b, hab, h⟩
  exact hab ((metric_grade_eq_zero_iff d hd f hf a b).mp h)

/- ------------------------------------------------------------------ -/
/- 3. ℕ 实例：radical 张力                                            -/
/- ------------------------------------------------------------------ -/

/-- 素数支撑：`rad(n)` 的素因子集合。这就是「数自身的结构」在 ℕ 上的读法。 -/
def supp (n : ℕ) : Finset ℕ := n.primeFactors

/-- **wiki 现版 ℕ 张力**：`K = |S∩T|`，`L = |SΔT| = |S∪T| − |S∩T|`。
    `grade = 2|S∩T| − |S∪T|`。 -/
def radTension : Tension ℕ where
  K a b := ((supp a ∩ supp b).card : ℤ)
  L a b := ((supp a ∪ supp b).card : ℤ) - ((supp a ∩ supp b).card : ℤ)

/-- **有向 ℕ 张力**：`K = |S\T|`，`L = |T\S|`。自动满足 T4（反号）与 T5（自差为零）。 -/
def dirTension : Tension ℕ where
  K a b := ((supp a \ supp b).card : ℤ)
  L a b := ((supp b \ supp a).card : ℤ)

/-- **对称 ∪/∩ 张力**：`K = |S∩T|`，`L = |S∪T|`。 -/
def symTension : Tension ℕ where
  K a b := ((supp a ∩ supp b).card : ℤ)
  L a b := ((supp a ∪ supp b).card : ℤ)

/- ------------------------- 3.1 wiki 现版：T5 崩 ------------------------- -/

/-- 自张力 = 支撑条数：`radTension.grade a a = ω(a)`（rad 的素因子个数）。 -/
theorem radTension_grade_self (n : ℕ) :
    radTension.grade n n = ((supp n).card : ℤ) := by
  simp only [Tension.grade, radTension, supp, Finset.inter_self, Finset.union_self]
  ring

/-- 显式反例：`2` 与自身的张力 = 1 ≠ 0。（`supp 2 = {2}`。） -/
theorem radTension_self_two : radTension.grade 2 2 = 1 := by
  rw [radTension_grade_self]
  native_decide

/-- **NODS 判定 A**：wiki 现版 ℕ 实例**违反公理 T5**。
    `T5` 要求自临界，而 `radTension` 在 `a > 1` 上自张力恒正（`= ω(a) > 0`）。
    这不是小瑕疵：它意味着现版把「数与自身的张力」和「数与他数的张力」
    放在了同一个零点约定上，公理与实例至少有一个要改。 -/
theorem radTension_violates_T5 : ¬ radTension.SelfCritical := by
  intro h
  have h2 : radTension.grade 2 2 = 0 := h 2
  rw [radTension_self_two] at h2
  norm_num at h2

/- ------------------------- 3.2 有向版：T4 + T5 都过 ------------------------- -/

/-- 有向版满足 T5（自临界）：`S\S = ∅`，故 `grade a a = 0`。 -/
theorem dirTension_self_critical : dirTension.SelfCritical := by
  intro n
  simp [Tension.crit, Tension.grade, dirTension]

/-- 有向版有非平凡临界（T3′）：`(6,10)` 临界——`{3}` 与 `{5}` 各一条，扳平。 -/
theorem dirTension_nontrivial : dirTension.NontrivialCrit := by
  refine ⟨6, 10, by norm_num, ?_⟩
  native_decide

/-- 有向版方向性（T4）：`12→30` 得 −1，`30→12` 得 +1——张力是力，不是距离。 -/
theorem dirTension_directional : dirTension.Directional := by
  refine ⟨12, 30, ?_⟩
  native_decide

/-- 对称 ∪/∩ 版也满足 T5：`grade a a = |S| − |S| = 0`。 -/
theorem symTension_self_critical : symTension.SelfCritical := by
  intro n
  simp [Tension.crit, Tension.grade, symTension, Finset.inter_self, Finset.union_self]

/-- 对称 ∪/∩ 版有非平凡临界（T3′）：`(2,4)`——`supp 2 = supp 4 = {2}`。 -/
theorem symTension_nontrivial : symTension.NontrivialCrit := by
  refine ⟨2, 4, by norm_num, ?_⟩
  native_decide

/- ------------------------- 3.3 核心负结论：临界流形不唯一 ------------------------- -/

/-- **NODS 判定 B（核心）**：公理 T1–T5 **不唯一确定临界流形**。

    `(6,10)`：`supp 6 = {2,3}`、`supp 10 = {2,5}`。
      · `dirTension`：`|{3}| − |{5}| = 0` → **临界**
      · `symTension`：`|{2}| − |{2,3,5}| = −2` → **不临界**

    两个实例都是 intrinsic（只吃 `a`、`b` 的素数支撑）、都满足 T5 与 T3′，
    却给出不同的临界流形。⇒ 「临界流形」这个中心对象没被公理钉死。 -/
theorem crit_manifold_not_unique :
    dirTension.crit 6 10 ∧ ¬ symTension.crit 6 10 := by
  constructor <;> native_decide

/-- 补一条：`(8,12)` 在 `radTension` 下临界、在 `dirTension` 下不临界
    —— 连「违反 T5 的那版」与「满足 T5 的那版」的临界流形也互不包含。 -/
theorem crit_manifold_not_unique' :
    radTension.crit 8 12 ∧ ¬ dirTension.crit 8 12 := by
  constructor <;> native_decide

/- ------------------------------------------------------------------ -/
/- 4. 汇总：NODS 三分里的哪一支                                        -/
/- ------------------------------------------------------------------ -/

/-- **NODS 总判定（ℕ）**。合起来说三件事：

    (i)  借来的单幅度结构（度量 / 序 / 整除）给不出非平凡临界流形
         —— 三条「外部结构」路线确实死；
    (ii) 但 ℕ 自身算术（素数支撑）定义得出满足 T5 + T3′ 的 intrinsic 张力，
         而且不止一个、临界流形还不一样 —— 同一载体上可解，且非唯一；
    (iii)⇒ 本需求在 ℕ 上是 `solved`，**不是 `gap`**；`τ` 及临界流形都非被迫
         ⇒ 相对已知库 novelty = 0。

    要把它从「一个记号」变成「一个发现」，缺的不是更多实例，而是一条
    **判别公理**（例如 T6 刚性：临界流形必须与某个已知对象典范同构），
    或者换一个**自身算术供不出 τ 的载体**（连续域方向）。 -/
theorem nods_verdict_nat :
    (∀ (d : ℕ → ℕ → ℤ) (f : ℤ → ℤ), (∀ a b, d a b = 0 ↔ a = b) → (∀ x, f x = 0 ↔ x = 0) →
        ¬ ∃ a b : ℕ, a ≠ b ∧ f (d a b) = 0)
      ∧ dirTension.SelfCritical ∧ dirTension.NontrivialCrit
      ∧ symTension.SelfCritical ∧ symTension.NontrivialCrit
      ∧ dirTension.crit 6 10 ∧ ¬ symTension.crit 6 10 := by
  refine ⟨?_, dirTension_self_critical, dirTension_nontrivial,
          symTension_self_critical, symTension_nontrivial, ?_, ?_⟩
  · intro d f hd hf
    exact metric_not_nontrivial d hd f hf
  · native_decide
  · native_decide

end NODS
