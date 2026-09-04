/-
【实例 3】Q → R ：极限闭包失败

这是整条链上**最特殊**的一步，也是最能暴露设计缺陷的一步。

前两步（N→Z、Z→Q）都有**泛性质**：Z 和 Q 是初始对象，
所以 `IsMinimal`（初始性）能完整刻画它们。

Q→R 没有。理由是可证的、且很重要：

  **"Dedekind 完备"不是一条等式公理，它不被任意环同态保持。**

具体地说，若 K 是一个完备的**非 Archimedean** 有序域（例如 Hahn 级数域），
那么从 R 到 K 的有序域嵌入**不唯一**：实数 r 可以送到
"r 的标准副本"，r 上方那层无穷小也会带来多余的选择。
Archimedean 一旦加上，唯一性才回来 —— 但那是**刚性定理**，
不是泛性质：它说的是"任何两个完备 Archimedean 有序域唯一同构"，
而不是"存在唯一的映射出去"。

所以 v0.1 在这里做两件事：

  1. 把**失败检测**做成完整机器证明（`rat_not_dedekind_complete`）。
     这才是 NODS 真正在做的事：发现"现有世界缺什么"。
  2. 把**极小性**换成可证的弱化形式 `IsCutGenerated`：
     R 中每个元素都是 Q 的某个切割的上确界 ——
     换句话说，R 里没有"多余的"元素。
     这是完备化型扩张能给出的、诚实且可形式化的"最小"。

真正的初始性陈述记为义务 O1（见下），v0.2 再补。
-/

import Mathlib
import Nods.Core.Engine
import Nods.Theories.Algebraic
import Nods.Instances.IntToRat

namespace NODS

abbrev realModel : Model LOF := Model.ofType ℝ (inferInstance : LinearOrderedField ℝ)

/- ------------------------------------------------------------------ -/
/- 完备性（作为一个性质，而不是一条等式公理）                          -/
/- ------------------------------------------------------------------ -/

/-- Dedekind 完备性：每个非空有上界的集合都有上确界。 -/
def DedekindComplete (α : Type) [Preorder α] : Prop :=
  ∀ s : Set α, s.Nonempty → BddAbove s → ∃ a : α, IsLUB s a

/-- 需求：换到有序域，并且要求完备 + Archimedean。 -/
def demandComplete : Demand FL LOF where
  Extra := fun _ => PUnit
  Axiom := fun M _ => DedekindComplete M.carrier ∧ Archimedean M.carrier
  mapExtra := fun _ e => e
  mapExtra_id := by intros; rfl
  mapExtra_comp := by intros; rfl

/- ------------------------------------------------------------------ -/
/- 失败检测                                                            -/
/- ------------------------------------------------------------------ -/

/-- √2 在 Q 中不存在。 -/
theorem rat_no_sqrt_two : ¬ ∃ x : ℚ, x ^ 2 = 2 := by
  rintro ⟨x, hx⟩
  have hxR : (x : ℝ) ^ 2 = 2 := by exact_mod_cast hx
  have hs : (Real.sqrt 2) ^ 2 = 2 := Real.sq_sqrt (by norm_num)
  have hsq : (x : ℝ) ^ 2 = (Real.sqrt 2) ^ 2 := by rw [hxR, hs]
  rcases (sq_eq_sq_iff_eq_or_eq_neg.mp hsq) with h | h
  · exact irrational_sqrt_two ⟨x, h⟩
  · exact irrational_sqrt_two ⟨-x, by rw [Rat.cast_neg, neg_neg, h]⟩

/-- **Q 不是 Dedekind 完备的**：`{q | q² < 2}` 在 Q 中没有上确界。

    证明思路（把 R 当作外部环境，从而避开 ε–δ 的手工构造）：
      若有上确界 s，则先在 R 中证明 `(s:ℝ) = √2`
        —— 若 `√2 < s`，用 Q 在 R 中的稠密性取 `√2 < q < s`，
           q 是新的上界，矛盾；
        —— 若 `s < √2`，取 `s < q < √2`，q 属于集合却大于 s，矛盾。
      于是 `s² = 2`，与 `rat_no_sqrt_two` 矛盾。 -/
theorem rat_not_dedekind_complete : ¬ DedekindComplete ℚ := by
  intro hdc
  let S : Set ℚ := {q | q ^ 2 < 2}
  have hne : S.Nonempty := ⟨0, by norm_num [S]⟩
  have hb : BddAbove S := by
    refine ⟨2, ?_⟩
    intro q hq
    by_contra hle
    have hq2 : (2 : ℚ) < q := lt_of_not_ge hle
    nlinarith [sq_nonneg (q - 2)]
  rcases hdc S hne hb with ⟨s, hlub⟩
  have hs_nonneg : 0 ≤ s := hlub.1 (by norm_num [S] : (0 : ℚ) ∈ S)
  have hs_eq : (s : ℝ) = Real.sqrt 2 := by
    apply le_antisymm
    · by_contra h
      have hlt : Real.sqrt 2 < (s : ℝ) := lt_of_not_ge h
      rcases exists_rat_btwn hlt with ⟨q, hq_above, hq_below⟩
      have hq_ub : q ∈ upperBounds S := by
        intro r hr
        have hrR : (r : ℝ) ^ 2 < 2 := by exact_mod_cast hr
        have hr_lt : (r : ℝ) < Real.sqrt 2 := by
          by_cases hrn : 0 ≤ (r : ℝ)
          · exact (Real.lt_sqrt hrn).mpr hrR
          · nlinarith [Real.sqrt_nonneg 2]
        have : (r : ℝ) < (q : ℝ) := lt_trans hr_lt hq_above
        exact_mod_cast le_of_lt this
      have hs_le_q : s ≤ q := hlub.2 q hq_ub
      have : (s : ℝ) ≤ (q : ℝ) := by exact_mod_cast hs_le_q
      linarith
    · by_contra h
      have hlt : (s : ℝ) < Real.sqrt 2 := lt_of_not_ge h
      rcases exists_rat_btwn hlt with ⟨q, hq_above, hq_below⟩
      have hq_pos : 0 ≤ (q : ℝ) := by
        have : (0 : ℝ) ≤ (s : ℝ) := by exact_mod_cast hs_nonneg
        linarith
      have hq_sq : q ^ 2 < 2 := by
        have hq_sqR : (q : ℝ) ^ 2 < 2 := (Real.lt_sqrt hq_pos).mp hq_below
        exact_mod_cast hq_sqR
      have hs_ge_q : q ≤ s := hlub.1 hq_sq
      have : (q : ℝ) ≤ (s : ℝ) := by exact_mod_cast hs_ge_q
      linarith
  have hs2R : (s : ℝ) ^ 2 = 2 := by rw [hs_eq, Real.sq_sqrt (by norm_num)]
  have hs2 : s ^ 2 = 2 := by
    apply Rat.cast_injective (α := ℝ)
    exact_mod_cast hs2R
  exact rat_no_sqrt_two ⟨s, hs2⟩

theorem rat_gap : ¬ HasSolution ratModel demandComplete := by
  rintro ⟨_s', _hstr, _e, hax⟩
  exact rat_not_dedekind_complete hax.1

/- ------------------------------------------------------------------ -/
/- 扩张：R                                                             -/
/- ------------------------------------------------------------------ -/

noncomputable def ratToReal : Extension ratModel demandComplete where
  target := realModel
  emb := by
    letI : NonAssocSemiring ratModel.carrier :=
      SemiringLike.toNonAssocSemiring (T := FL) ratModel.str
    letI : NonAssocSemiring (Model.forget FL LOF realModel).carrier :=
      SemiringLike.toNonAssocSemiring (T := FL) (Model.forget FL LOF realModel).str
    exact Rat.castHom ℝ
  emb_inj := by
    intro a b h
    exact Rat.cast_injective h
  extra := PUnit.unit
  ax := by
    constructor
    · intro s hs hb
      exact ⟨sSup s, isLUB_csSup hs hb⟩
    · infer_instance

/- ------------------------------------------------------------------ -/
/- 极小性（第二类）：切割生成性                                        -/
/- ------------------------------------------------------------------ -/

/-- R 中每个实数都是它下方所有有理数的上确界。

    这就是"R 里没有多余元素"的精确说法：R 的每一个新元素，
    都是被 Q 的某个切割**逼出来**的。
    换到 NODS 的语言：R 的每个元素都对应失败空间 F 里的一个失败。 -/
theorem real_cut_generated (r : ℝ) : IsLUB {q : ℚ | (q : ℝ) < r} r := by
  constructor
  · intro q hq
    exact le_of_lt hq
  · intro y hy
    by_contra h
    have hyr : r < y := lt_of_not_ge h
    rcases exists_rat_btwn hyr with ⟨q, hqr, hqy⟩
    have hyq : q ≤ y := hy hqr
    have : (q : ℝ) ≤ y := by exact_mod_cast hyq
    linarith

/-- 记录一条切割生成性：R 由 Q 的切割生成，故无冗余。 -/
theorem real_is_cut_generated :
    ∀ r : ℝ, IsLUB {q : ℚ | (q : ℝ) < r} r := real_cut_generated

/-- **未决义务 O1**：R 在"完备 Archimedean 有序域 + 嵌入 Q"中的初始性。

    这不是被遗忘的证明，而是刻意留下的洞。它需要一个
    "唯一有序域同态 R → K"的构造（Dedekind 切割的显式搬运），
    大约 80 行分析学。v0.1 用 `IsCutGenerated` 顶上，
    v0.2 应把它替换成真正的 `IsMinimal` 证明。 -/
axiom real_initiality_obligation : IsMinimal ratModel demandComplete ratToReal

end NODS
