/-
【实例 2】Z → Q ：除法闭包失败

失败的**具体形式**：在 Z 里 `2x = 1` 无解。

与 N → Z 一样，这一步的真身也是**理论强化**（换到 Field），
不是"添一个元素 1/2"。添 1/2 只能得到 Z[1/2]；
要得到 Q 必须一次要求"所有非零元可逆"，也就是把背景理论换成 Field。

这里额外出现一个技术点，值得记下来：
`Rat.castHom` 需要目标有 `CharZero`。这不是多余的假设 ——
如果允许特征 p 的域，Q 根本映不进去，"极小扩张"也就不存在了。
在 NODS 的框架里，这个假设是**由 `emb_inj` 免费提供的**
（Z 单射进目标 ⇒ 目标特征零）。也就是说：
"扩张必须真的包含旧世界"这条要求，自动排除了特征 p。
-/

import Mathlib
import Nods.Core.Engine
import Nods.Theories.Algebraic
import Nods.Instances.NatToInt

namespace NODS

abbrev ratModel : Model FL := Model.ofType ℚ (inferInstance : Field ℚ)

/-- 需求：换到域。 -/
def demandField : Demand CR FL where
  Extra := fun _ => PUnit
  Axiom := fun _ _ => True
  mapExtra := fun _ e => e
  mapExtra_id := by intros; rfl
  mapExtra_comp := by intros; rfl

/- ------------------------------------------------------------------ -/
/- 失败检测                                                            -/
/- ------------------------------------------------------------------ -/

/-- Z 里 1/2 不存在。 -/
theorem int_no_half : ¬ ∃ x : ℤ, 2 * x = 1 := by
  rintro ⟨x, hx⟩
  omega

/-- Z 上不存在域结构。 -/
theorem no_field_on_int : ¬ Nonempty (Field ℤ) := by
  rintro ⟨s⟩
  letI := s
  exact int_no_half ⟨(2 : ℤ)⁻¹, mul_inv_cancel₀ (by norm_num : (2 : ℤ) ≠ 0)⟩

theorem int_gap : ¬ HasSolution intModel demandField := by
  rintro ⟨s', _hstr, _e, _hax⟩
  exact no_field_on_int ⟨s'⟩

/- ------------------------------------------------------------------ -/
/- 极小扩张：Q                                                         -/
/- ------------------------------------------------------------------ -/

/-- Z → Q 的扩张。 -/
noncomputable def intToRat : Extension intModel demandField where
  target := ratModel
  emb := by
    letI : NonAssocSemiring intModel.carrier :=
      SemiringLike.toNonAssocSemiring (T := CR) intModel.str
    letI : NonAssocSemiring (Model.forget CR FL ratModel).carrier :=
      SemiringLike.toNonAssocSemiring (T := CR) (Model.forget CR FL ratModel).str
    exact Int.castRingHom ℚ
  emb_inj := by
    intro a b h
    exact Int.cast_injective h
  extra := PUnit.unit
  ax := trivial

/-- 从嵌入的单射性推出目标特征零。这一步不平凡：
    它说明 NODS 里"扩张必须真的包含旧世界"（`emb_inj`）
    是一个**有实质内容**的约束，而不是形式过场。 -/
theorem charZero_of_emb_inj (F : Extension intModel demandField) :
    CharZero F.target.carrier := by
  letI : Field F.target.carrier := F.target.str
  letI : NonAssocSemiring intModel.carrier :=
    SemiringLike.toNonAssocSemiring (T := CR) intModel.str
  letI : NonAssocSemiring (Model.forget CR FL F.target).carrier :=
    SemiringLike.toNonAssocSemiring (T := CR) (Model.forget CR FL F.target).str
  have hFemb : F.emb = Int.castRingHom F.target.carrier := by
    apply RingHom.ext_int
  refine ⟨fun a b h => ?_⟩
  apply F.emb_inj
  rw [hFemb]
  change ((a : ℤ) : F.target.carrier) = ((b : ℤ) : F.target.carrier)
  exact_mod_cast h

/-- **Q 是极小扩张**：在"域 + 嵌入 Z"这个范畴里，Q 是初始对象。

    存在性用 `Rat.castHom`（Q 到任何特征零的除环都有唯一同态）；
    唯一性用 `RingHom.ext_rat`。 -/
noncomputable def intToRat_minimal : IsMinimal intModel demandField intToRat := by
  intro F
  letI : Field F.target.carrier := F.target.str
  letI : CharZero F.target.carrier := charZero_of_emb_inj F
  letI : NonAssocSemiring ratModel.carrier :=
    SemiringLike.toNonAssocSemiring (T := FL) ratModel.str
  letI : NonAssocSemiring F.target.carrier :=
    SemiringLike.toNonAssocSemiring (T := FL) F.target.str
  letI : NonAssocSemiring intModel.carrier :=
    SemiringLike.toNonAssocSemiring (T := CR) intModel.str
  letI : NonAssocSemiring (Model.forget CR FL F.target).carrier :=
    SemiringLike.toNonAssocSemiring (T := CR) (Model.forget CR FL F.target).str
  have hFemb : F.emb = Int.castRingHom F.target.carrier := by
    apply RingHom.ext_int
  constructor
  · refine ⟨{ hom := Rat.castHom F.target.carrier
               over := ?_
               pres := by rfl }⟩
    intro z
    simp only [Biframed.forget_toFun]
    change (Rat.castHom F.target.carrier) ((z : ℚ)) = F.emb z
    rw [hFemb]
    simp
  · intro f g
    apply ExtHom.ext
    intro x
    have hfg : f.hom = g.hom := RingHom.ext_rat f.hom g.hom
    rw [hfg]

end NODS
