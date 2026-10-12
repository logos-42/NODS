/-
【理论层】张力计数法：数字自身张力的极简公理 · ℕ 实例 · NODS 判定 · **逼出定理**
================================================================================

目标：给「数字自身」的收敛 / 发散力一套极简**计数**公理 —— 不经由任何选定公式，
只由数对自身的算术结构决定，并带一个临界（零张力）流形。本文件落成两代公理：

TCM-0（第 1–4 节）—— 立起来，然后诚实地说明它**不被迫**
  1. 抽象公理层 `Tension D`
       T1 直接性   `K`/`L : D → D → ℤ`，只吃两个数，无外部函数参数（反度量）
       T2 二分力   张力 = 收敛力 `K` − 发散力 `L`
       T3 临界流形  `grade = 0`，真非平凡 / 非全
       T4 方向性   允许 `grade a b ≠ grade b a`
       T5 退化     自临界：`grade a a = 0`
  2. ℕ 实例：radical 张力（`S = rad(a)` 的素因子集）
       `radTension`（wiki 现版）/ `dirTension`（有向）/ `symTension`（∪∩）
  3. NODS 判定（负结论）
       · `radTension_violates_T5`  自张力 = ω(a) ≠ 0 —— wiki 现版违反 T5
       · `metric_not_nontrivial`   单幅度 τ = f∘d 的临界流形恒为对角线
       · `crit_manifold_not_unique` 两个都合规的实例，临界流形却不同
       · `nods_verdict_nat`        ⇒ ℕ 上 TCM-0 是「记号」而非发现

TCM-1（第 5–6 节）—— 加判别公理，把 τ **逼出来**
     T6 计数公理   两个力都是剖面的**可加**函数：每多一条素数多固定的一份力（元计数）
     T7 单位公理   每个素数对每个力**至多贡献一条**（系数 ∈ {0,1}）——「条」不可再分
     T4′ 反号公理  **把数对反着读，张力严格反号**：把 T4 从「允许」升级为「必须」
     T5 自零       数和自身两力皆零（对角剖面 `(t, 0, 0)`）
     T3b 非全      存在张力不为零的数对

  **主定理 `forced_unique`**：满足 T5 + T7 + T4′ + T3b 的几何计数张力，其张力差只能是
  `|S∖T| − |T∖S|` 或其反号 —— **没有第三种可能**。即张力计数法是被公理逼出来的唯一
  对象（到取向为止），与 R→C 的 `(C, i)` / `(C, −i)` 同属「最小 + 刚性」模式。

  最小化副产物：`nontrivialCrit_free` 证 T3a 是**定理**而非公理；
  `T5_needed` 证 T5 不可省（否则同一个张力差可由不同 `(K, L)` 对给出）。

总纲（NODS）：**证明不了「被迫」，就只能说「我选了一个记号」。**
本文件先诚实证出前者在 TCM-0 上的失败，再用 TCM-1 把它补成「被迫」。
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

/- ------------------------------------------------------------------ -/
/- 5. TCM-1：判别公理 —— 把 τ 逼出来（从「记号」到「被迫对象」）        -/
/- ------------------------------------------------------------------ -/

/-- 「剖面」：一对数只有三种素数身份 —— 共享 / a 独有 / b 独有。
    T1 直接性说的就是：张力只吃这个读数。 -/
def profile (a b : ℕ) : ℕ × ℕ × ℕ :=
  ((supp a ∩ supp b).card, (supp a \ supp b).card, (supp b \ supp a).card)

/-- **T6 计数公理**：两个力都是剖面的**可加**函数 —— 每多一条素数就多固定的一份力，
    与其它条无关。这就是「逐素数计数、每素数一条」（元计数）的形式化。
    用 `AddMonoidHom` 表达，可加性内建，不必手写六条公理。 -/
structure AddTension where
  /-- 收敛力 -/
  K : (ℕ × ℕ × ℕ) →+ ℤ
  /-- 发散力 -/
  L : (ℕ × ℕ × ℕ) →+ ℤ

namespace AddTension

variable (τ : AddTension)

/-- T2：张力差 `grade := K − L`。 -/
@[reducible] def grade (u : ℕ × ℕ × ℕ) : ℤ := τ.K u - τ.L u

/-- **T5 自零**：数和自身既无收敛力也无发散力（对角剖面 `(t, 0, 0)`）。 -/
def SelfZero : Prop := ∀ t : ℕ, τ.K (t, 0, 0) = 0 ∧ τ.L (t, 0, 0) = 0

/-- **T7 单位性**：每个素数对每个力**至多贡献一条**（系数 ∈ {0,1}）——
    这就是「数条数」里的那个「条」，也是「不可再分」的形式化。 -/
def Unit : Prop :=
  (τ.K (0, 1, 0) = 0 ∨ τ.K (0, 1, 0) = 1) ∧ (τ.K (0, 0, 1) = 0 ∨ τ.K (0, 0, 1) = 1) ∧
  (τ.L (0, 1, 0) = 0 ∨ τ.L (0, 1, 0) = 1) ∧ (τ.L (0, 0, 1) = 0 ∨ τ.L (0, 0, 1) = 1)

/-- **T4′ 反号**：把数对反着读，张力严格反号。
    这是把 T4 从「可以有方向」升级为「必须反号」—— 逼出唯一性的关键一条。 -/
def Reciprocal : Prop := ∀ u : ℕ × ℕ × ℕ, τ.grade (u.1, u.2.2, u.2.1) = -τ.grade u

/-- **T3b 临界非全**：存在张力不为零的数对（否则处处为零，不成其为力）。 -/
def NonfullCrit : Prop := ∃ u : ℕ × ℕ × ℕ, τ.grade u ≠ 0

/-- T3a 临界非平凡。下面会证它是**定理**而非公理（见 `nontrivialCrit_free`）。 -/
def NontrivialCrit : Prop := ∃ y z : ℕ, y + z > 0 ∧ τ.grade (0, y, z) = 0

/-- **线性化引理**（T6 的确切内容）：力的可加性 ⟹ 力只由三条计数**线性**决定。
    「每多一条素数就多固定一份」 = 可加 = 线性。 -/
theorem K_linear (u : ℕ × ℕ × ℕ) :
    τ.K u = (u.1 : ℤ) * τ.K (1, 0, 0) + (u.2.1 : ℤ) * τ.K (0, 1, 0)
            + (u.2.2 : ℤ) * τ.K (0, 0, 1) := by
  have h : u = u.1 • ((1, 0, 0) : ℕ × ℕ × ℕ) + u.2.1 • (0, 1, 0) + u.2.2 • (0, 0, 1) := by
    ext <;> simp
  conv_lhs => rw [h]
  rw [map_add, map_add, map_nsmul, map_nsmul, map_nsmul,
      nsmul_eq_mul, nsmul_eq_mul, nsmul_eq_mul]

/-- 发散力的线性化（同 `K_linear`）。 -/
theorem L_linear (u : ℕ × ℕ × ℕ) :
    τ.L u = (u.1 : ℤ) * τ.L (1, 0, 0) + (u.2.1 : ℤ) * τ.L (0, 1, 0)
            + (u.2.2 : ℤ) * τ.L (0, 0, 1) := by
  have h : u = u.1 • ((1, 0, 0) : ℕ × ℕ × ℕ) + u.2.1 • (0, 1, 0) + u.2.2 • (0, 0, 1) := by
    ext <;> simp
  conv_lhs => rw [h]
  rw [map_add, map_add, map_nsmul, map_nsmul, map_nsmul,
      nsmul_eq_mul, nsmul_eq_mul, nsmul_eq_mul]

/-- **T5 的推论**：共享条数整个掉出张力差的视野 —— 张力只看见两条「独有」计数。
    这正是自零公理在做的事，也是它不可省的原因（见 `T5_needed`）。 -/
theorem grade_linear (h5 : τ.SelfZero) (u : ℕ × ℕ × ℕ) :
    τ.grade u = (u.2.1 : ℤ) * (τ.K (0, 1, 0) - τ.L (0, 1, 0))
              + (u.2.2 : ℤ) * (τ.K (0, 0, 1) - τ.L (0, 0, 1)) := by
  simp only [grade, K_linear τ u, L_linear τ u]
  rw [(h5 1).1, (h5 1).2]
  ring

/-- **逼出定理（系数版）**：T5 + T7 + T4′ + T3b ⇒ 系数只能取两组值 ——
    `(K_B, K_C; L_B, L_C) = (1, 0; 0, 1)` 或其镜像 `(0, 1; 1, 0)`。**没有第三种**。 -/
theorem forced_coeffs (h5 : τ.SelfZero) (h7 : τ.Unit) (h4 : τ.Reciprocal)
    (h3b : τ.NonfullCrit) :
    (τ.K (0, 1, 0) = 1 ∧ τ.K (0, 0, 1) = 0 ∧ τ.L (0, 1, 0) = 0 ∧ τ.L (0, 0, 1) = 1) ∨
    (τ.K (0, 1, 0) = 0 ∧ τ.K (0, 0, 1) = 1 ∧ τ.L (0, 1, 0) = 1 ∧ τ.L (0, 0, 1) = 0) := by
  obtain ⟨hKB, hKC, hLB, hLC⟩ := h7
  have hrec : τ.K (0, 0, 1) - τ.L (0, 0, 1) = -(τ.K (0, 1, 0) - τ.L (0, 1, 0)) := by
    have h := h4 (0, 1, 0)
    simpa only [grade] using h
  have hne : ¬ (τ.K (0, 1, 0) = τ.L (0, 1, 0) ∧ τ.K (0, 0, 1) = τ.L (0, 0, 1)) := by
    rintro ⟨hb, hc⟩
    obtain ⟨u, hu⟩ := h3b
    exact hu (by rw [grade_linear τ h5 u, hb, hc]; ring)
  by_cases hcase : τ.K (0, 1, 0) = 1
  · left
    refine ⟨hcase, ?_, ?_, ?_⟩ <;> omega
  · right
    refine ⟨by omega, ?_, ?_, ?_⟩ <;> omega

/-- **T3a 是冗余的**：在 T5 + T7 + T4′ + T3b 之下，「临界非平凡」自动成立。
    所以它不必写进公理（HIBS 第 7/8 步：能推的别列，不能推的才是公理）。 -/
theorem nontrivialCrit_free (h5 : τ.SelfZero) (h7 : τ.Unit) (h4 : τ.Reciprocal)
    (h3b : τ.NonfullCrit) : τ.NontrivialCrit := by
  have key : τ.grade (0, 1, 1) = 0 := by
    rw [grade_linear τ h5 (0, 1, 1)]
    rcases forced_coeffs τ h5 h7 h4 h3b with ⟨h1, h2, h3, h4'⟩ | ⟨h1, h2, h3, h4'⟩ <;>
      · rw [h1, h2, h3, h4']; norm_num
  exact ⟨1, 1, by norm_num, key⟩

/-- **逼出定理（张力版，主定理）**：满足 T5 + T7 + T4′ + T3b 的几何计数张力，
    其张力差只能是 `|S∖T| − |T∖S|` 或其反号 —— **没有第三种可能**。

    即：张力计数法不是「选」出来的记号，是被公理逼出来的唯一对象（到取向为止）。 -/
theorem forced_unique (h5 : τ.SelfZero) (h7 : τ.Unit) (h4 : τ.Reciprocal)
    (h3b : τ.NonfullCrit) :
    (∀ u : ℕ × ℕ × ℕ, τ.grade u = (u.2.1 : ℤ) - (u.2.2 : ℤ)) ∨
    (∀ u : ℕ × ℕ × ℕ, τ.grade u = (u.2.2 : ℤ) - (u.2.1 : ℤ)) := by
  rcases forced_coeffs τ h5 h7 h4 h3b with ⟨h1, h2, h3, h4'⟩ | ⟨h1, h2, h3, h4'⟩
  · left; intro u; rw [grade_linear τ h5 u, h1, h2, h3, h4']; ring
  · right; intro u; rw [grade_linear τ h5 u, h1, h2, h3, h4']; ring

end AddTension

/- ------------------------------------------------------------------ -/
/- 6. 落实：被逼出来的那个张力，正是有向支撑差 `|S∖T| − |T∖S|`            -/
/- ------------------------------------------------------------------ -/

/-- 取剖面的第一坐标（共享条数）。 -/
def projA : (ℕ × ℕ × ℕ) →+ ℤ where
  toFun u := (u.1 : ℤ)
  map_zero' := by simp
  map_add' := by intro u v; simp [Nat.cast_add]

/-- 取剖面的第二坐标（a 独有）。 -/
def projB : (ℕ × ℕ × ℕ) →+ ℤ where
  toFun u := (u.2.1 : ℤ)
  map_zero' := by simp
  map_add' := by intro u v; simp [Nat.cast_add]

/-- 取剖面的第三坐标（b 独有）。 -/
def projC : (ℕ × ℕ × ℕ) →+ ℤ where
  toFun u := (u.2.2 : ℤ)
  map_zero' := by simp
  map_add' := by intro u v; simp [Nat.cast_add]

/-- **被逼出来的张力**：`K = |S∖T|`（a 独有 → 收敛），`L = |T∖S|`。 -/
def forcedTension : AddTension where
  K := projB
  L := projC

/-- 逼出来的张力确实满足全部判别公理（⇒ 公理组不空，逼出不是空谈）。 -/
theorem forcedTension_axioms :
    forcedTension.SelfZero ∧ forcedTension.Unit ∧ forcedTension.Reciprocal
      ∧ forcedTension.NonfullCrit := by
  refine ⟨?_, ?_, ?_, ?_⟩
  · intro t
    exact ⟨by simp [AddTension.SelfZero, forcedTension, projB],
           by simp [forcedTension, projC]⟩
  · exact ⟨Or.inr (by simp [forcedTension, projB]),
           Or.inl (by simp [forcedTension, projB]),
           Or.inl (by simp [forcedTension, projC]),
           Or.inr (by simp [forcedTension, projC])⟩
  · intro u
    simp [AddTension.grade, forcedTension, projB, projC]
  · refine ⟨(0, 1, 0), ?_⟩
    simp [AddTension.grade, forcedTension, projB, projC]

/-- 落实：把 `forcedTension` 读回数对上，正是前面那个有向张力 `dirTension`。 -/
theorem forcedTension_to_dirTension (a b : ℕ) :
    forcedTension.grade (profile a b) = dirTension.grade a b := by
  simp [AddTension.grade, Tension.grade, forcedTension, projB, projC, dirTension, profile]

/-- **T5 不可省**：扔掉自零公理，「同一个张力差」能由不同的 `(K, L)` 对给出
    （把共享条数同时加进两个力即可）。所以要逼出 **一对力**，T5 是必需的一条。 -/
theorem T5_needed :
    ∃ τ' : AddTension, (∀ u : ℕ × ℕ × ℕ, τ'.grade u = forcedTension.grade u)
      ∧ τ'.K (1, 0, 0) ≠ forcedTension.K (1, 0, 0) := by
  refine ⟨⟨projB + projA, projC + projA⟩, ?_, ?_⟩
  · intro u
    simp only [AddTension.grade, forcedTension, projB, projC, projA, AddMonoidHom.add_apply]
    ring
  · simp only [forcedTension, projB, projA, AddMonoidHom.add_apply]
    norm_num

/- ------------------------------------------------------------------ -/
/- 7. 最小化审计：每条公理究竟在干什么                                  -/
/- ------------------------------------------------------------------ -/

/-- 剖面的总条数（共享 + a 独有 + b 独有）。 -/
def total (u : ℕ × ℕ × ℕ) : ℤ := (u.1 : ℤ) + (u.2.1 : ℤ) + (u.2.2 : ℤ)

namespace AddTension

variable (τ : AddTension)

/-- **计数界**：力**数不出比东西本身更多的条**（且非负）。
    这比 T7 的四条点态约束更自然，也是「计数」这个字的正经写法。 -/
def CountBound : Prop :=
  (∀ u : ℕ × ℕ × ℕ, 0 ≤ τ.K u ∧ τ.K u ≤ total u) ∧
  (∀ u : ℕ × ℕ × ℕ, 0 ≤ τ.L u ∧ τ.L u ≤ total u)

/-- **T7 是定理，不是公理**：只加「计数界」，单位性自动成立（0 ≤ 系数 ≤ 1）。 -/
theorem Unit_of_bound (h : τ.CountBound) : τ.Unit := by
  obtain ⟨hK, hL⟩ := h
  obtain ⟨hK0, hK1⟩ := hK (0, 1, 0)
  obtain ⟨hK2, hK3⟩ := hK (0, 0, 1)
  obtain ⟨hL0, hL1⟩ := hL (0, 1, 0)
  obtain ⟨hL2, hL3⟩ := hL (0, 0, 1)
  simp only [total] at hK1 hK3 hL1 hL3
  norm_num at hK1 hK3 hL1 hL3
  refine ⟨?_, ?_, ?_, ?_⟩ <;> omega

/-- 反向（在 T5 下两条**等价**）：单位 + 自零 ⇒ 计数界 —— 界是更自然的那条写法。 -/
theorem Bound_of_unit (h5 : τ.SelfZero) (h7 : τ.Unit) : τ.CountBound := by
  obtain ⟨hKB, hKC, hLB, hLC⟩ := h7
  constructor
  · intro u
    have h := K_linear τ u
    rw [(h5 1).1] at h
    rcases hKB with hKB | hKB <;> rcases hKC with hKC | hKC <;>
      · rw [hKB, hKC] at h
        simp only [total] at *
        constructor <;> omega
  · intro u
    have h := L_linear τ u
    rw [(h5 1).2] at h
    rcases hLB with hLB | hLB <;> rcases hLC with hLC | hLC <;>
      · rw [hLB, hLC] at h
        simp only [total] at *
        constructor <;> omega

/-- **分工定理（形式）**：T5 + T4′ + T3b ⇒ 张力被逼成 `c · (|S∖T| − |T∖S|)`
    （`c ≠ 0`）。**形状被完全逼出，只留一个整数单位。** -/
theorem form_up_to_scale (h5 : τ.SelfZero) (h4 : τ.Reciprocal) (h3b : τ.NonfullCrit) :
    ∃ c : ℤ, c ≠ 0 ∧ ∀ u : ℕ × ℕ × ℕ, τ.grade u = c * ((u.2.1 : ℤ) - (u.2.2 : ℤ)) := by
  have hrec : τ.K (0, 0, 1) - τ.L (0, 0, 1) = -(τ.K (0, 1, 0) - τ.L (0, 1, 0)) := by
    have h := h4 (0, 1, 0)
    simpa only [grade] using h
  have hne : τ.K (0, 1, 0) - τ.L (0, 1, 0) ≠ 0 := by
    intro h0
    obtain ⟨u, hu⟩ := h3b
    exact hu (by rw [grade_linear τ h5 u, hrec, h0]; ring)
  refine ⟨τ.K (0, 1, 0) - τ.L (0, 1, 0), hne, ?_⟩
  intro u
  rw [grade_linear τ h5 u, hrec]
  ring

/-- **分工定理（单位）**：再加上 T7，那个自由单位就被钉成 `±1` ——
    **T7 唯一的工作就是定单位**，形状它管不着。 -/
theorem unit_fixes_scale (h5 : τ.SelfZero) (h7 : τ.Unit) (h4 : τ.Reciprocal)
    (h3b : τ.NonfullCrit) :
    τ.K (0, 1, 0) - τ.L (0, 1, 0) = 1 ∨ τ.K (0, 1, 0) - τ.L (0, 1, 0) = -1 := by
  rcases forced_coeffs τ h5 h7 h4 h3b with ⟨h1, _, h3, _⟩ | ⟨h1, _, h3, _⟩
  · left; omega
  · right; omega

/-- T4′ 已蕴含「对角线上张力的**差**为零」—— T5 里的 grade 部分因此冗余。
    T5 真正不可省的是「两个力**各自**为零」（那才管住 `(K, L)` 这一对，见 `T5_needed`）。 -/
theorem diagonal_grade_zero (h4 : τ.Reciprocal) (t : ℕ) : τ.grade (t, 0, 0) = 0 := by
  have h : τ.grade (t, 0, 0) = -τ.grade (t, 0, 0) := h4 (t, 0, 0)
  omega

end AddTension

/- ------------------------------------------------------------------ -/
/- 8. 独立性：每条公理都给一个反模型（HIBS 第 8 步）                     -/
/- ------------------------------------------------------------------ -/

/-- **T4′ 的反模型**：`K = |S∖T| + |T∖S|`、`L = 0`，即 `τ = |S∖T| + |T∖S|`。
    它满足 T5 / T6 / T7 / T3b —— 却**不是力**：那是个对称的「距离」，不反号。
    ⇒ T4′ 不能由其余公理推出；**它正是把「距离」变成「力」的那一条**。 -/
def spreadTension : AddTension where
  K := projB + projC
  L := 0

theorem T4'_independent :
    spreadTension.SelfZero ∧ spreadTension.Unit ∧ spreadTension.NonfullCrit
      ∧ ¬ spreadTension.Reciprocal := by
  refine ⟨?_, ?_, ?_, ?_⟩
  · intro t
    exact ⟨by simp [spreadTension, projB, projC], by simp [spreadTension]⟩
  · exact ⟨Or.inr (by simp [spreadTension, projB, projC]),
           Or.inr (by simp [spreadTension, projB, projC]),
           Or.inl (by simp [spreadTension]),
           Or.inl (by simp [spreadTension])⟩
  · refine ⟨(0, 1, 0), ?_⟩
    simp [AddTension.grade, spreadTension, projB, projC]
  · intro h
    have h1 : spreadTension.grade (0, 0, 1) = -spreadTension.grade (0, 1, 0) := h (0, 1, 0)
    have e1 : spreadTension.grade (0, 0, 1) = 1 := by
      simp [AddTension.grade, spreadTension, projB, projC]
    have e2 : spreadTension.grade (0, 1, 0) = 1 := by
      simp [AddTension.grade, spreadTension, projB, projC]
    omega

/-- **T3b 的反模型**：`K = L = 0` —— 张力处处为零。
    它满足 T5 / T6 / T7 / T4′，却什么都测不出 ⇒ T3b（非全）不可省。 -/
def zeroTension : AddTension where
  K := 0
  L := 0

theorem T3b_needed :
    zeroTension.SelfZero ∧ zeroTension.Unit ∧ zeroTension.Reciprocal
      ∧ ¬ zeroTension.NonfullCrit := by
  refine ⟨?_, ?_, ?_, ?_⟩
  · intro t
    exact ⟨by simp [zeroTension], by simp [zeroTension]⟩
  · exact ⟨Or.inl (by simp [zeroTension]), Or.inl (by simp [zeroTension]),
           Or.inl (by simp [zeroTension]), Or.inl (by simp [zeroTension])⟩
  · intro u
    simp [AddTension.grade, zeroTension]
  · rintro ⟨u, hu⟩
    exact hu (by simp [AddTension.grade, zeroTension])

/-- **T6 的反模型（不可加）**：张力 `|S∖T|² − |T∖S|²`。
    它满足 T5（对角两力皆零）、T7（生成元上系数 ∈ {0,1}）、T4′（反号）、T3b（非全），
    却**不可加**，且不是任何 `c · (|S∖T| − |T∖S|)`。
    ⇒ T6（可加 = 逐素数计数）不能省。 -/
def sqForce (u : ℕ × ℕ × ℕ) : ℤ := (u.2.1 : ℤ) ^ 2 - (u.2.2 : ℤ) ^ 2

theorem additivity_needed :
    (∀ t : ℕ, sqForce (t, 0, 0) = 0)
    ∧ (sqForce (0, 1, 0) = 1 ∧ sqForce (0, 0, 1) = -1 ∧ sqForce (1, 0, 0) = 0)
    ∧ (∀ u : ℕ × ℕ × ℕ, sqForce (u.1, u.2.2, u.2.1) = -sqForce u)
    ∧ (∃ u : ℕ × ℕ × ℕ, sqForce u ≠ 0)
    ∧ (∀ c : ℤ, (∀ u : ℕ × ℕ × ℕ, sqForce u = c * ((u.2.1 : ℤ) - (u.2.2 : ℤ))) → False)
    ∧ (∃ u v : ℕ × ℕ × ℕ, sqForce (u + v) ≠ sqForce u + sqForce v) := by
  refine ⟨?_, ⟨?_, ?_, ?_⟩, ?_, ?_, ?_, ?_⟩
  · intro t; simp [sqForce]
  · simp [sqForce]
  · simp [sqForce]
  · simp [sqForce]
  · intro u; simp [sqForce]
  · exact ⟨(0, 2, 0), by simp [sqForce]⟩
  · intro c hc
    have h1 := hc (0, 1, 0)
    have h2 := hc (0, 2, 0)
    simp [sqForce] at h1 h2
    omega
  · exact ⟨(0, 1, 0), (0, 1, 0), by simp [sqForce]⟩

end NODS
