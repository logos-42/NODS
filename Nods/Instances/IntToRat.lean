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

/-- **判定**：Z 承载不了"除法闭包"，即这是一个 gap（见下面 `intToRat` 给出见证）。

    注意不能走"ℤ 上不存在 Field 结构"这条路——那是假命题：
    ℤ 与 ℚ 可数等势，可沿双射把 `Field ℚ` 搬到 ℤ 上（`Equiv.field`）。
    真正的约束是 `HasSolution` 里的 `forgetStr s' = intModel.str`，
    它强制域的**交换环部分**等于原生 `CommRing ℤ`；据此把域等式 `2 * 2⁻¹ = 1`
    里的域 `*` / `1` 改写成原生 `*` / `1`，再交给 `int_no_half`。 -/
theorem int_gap : ¬ HasSolution intModel demandField := by
  rintro ⟨s', hstr, _e, _hax⟩
  letI : Field ℤ := s'
  have hring : s'.toCommRing = Int.instCommRing := hstr
  have hzero :
      ((@Field.toSemifield ℤ s').toDivisionSemiring.toGroupWithZero.toMonoidWithZero.toMulZeroOneClass.toMulZeroClass.toZero : Zero ℤ).zero = (0 : ℤ) := by
    calc
      _ = (s'.toCommRing.toSemiring.toNonUnitalSemiring.toNonUnitalNonAssocSemiring.toMulZeroClass.toZero : Zero ℤ).zero := by rfl
      _ = (Int.instCommRing.toSemiring.toNonUnitalSemiring.toNonUnitalNonAssocSemiring.toMulZeroClass.toZero : Zero ℤ).zero := by rw [hring]
      _ = (0 : ℤ) := by rfl
  have h2ne0 : (2 : ℤ) ≠
      ((@Field.toSemifield ℤ s').toDivisionSemiring.toGroupWithZero.toMonoidWithZero.toMulZeroOneClass.toMulZeroClass.toZero : Zero ℤ).zero := by
    intro h
    have : (2 : ℤ) = (0 : ℤ) := by rw [hzero] at h; exact h
    norm_num at this
  have hinv := mul_inv_cancel₀ (a := (2 : ℤ)) h2ne0
  have hmul :
      ((@Field.toSemifield ℤ s').toDivisionSemiring.toGroupWithZero.toMonoidWithZero.toMulZeroOneClass.toMulZeroClass.toMul : Mul ℤ) = @Int.instMul := by
    calc
      _ = (s'.toCommRing.toSemiring.toNonUnitalSemiring.toNonUnitalNonAssocSemiring.toMul : Mul ℤ) := by rfl
      _ = (Int.instCommRing.toSemiring.toNonUnitalSemiring.toNonUnitalNonAssocSemiring.toMul : Mul ℤ) := by rw [hring]
      _ = @Int.instMul := by rfl
  rw [hmul] at hinv
  have hone :
      ((@Field.toSemifield ℤ s').toDivisionSemiring.toGroupWithZero.toMonoidWithZero.toMulZeroOneClass.toMulOneClass.toOne : One ℤ).one = (1 : ℤ) := by
    calc
      _ = (s'.toCommRing.toMonoid.toMulOneClass.toOne : One ℤ).one := by rfl
      _ = (Int.instCommRing.toMonoid.toMulOneClass.toOne : One ℤ).one := by rw [hring]
      _ = (1 : ℤ) := by rfl
  change 2 * (2 : ℤ)⁻¹ =
      ((@Field.toSemifield ℤ s').toDivisionSemiring.toGroupWithZero.toMonoidWithZero.toMulZeroOneClass.toMulOneClass.toOne : One ℤ).one at hinv
  rw [hone] at hinv
  exact int_no_half ⟨(2 : ℤ)⁻¹, hinv⟩

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
    change (Int.castRingHom ℚ) a = (Int.castRingHom ℚ) b at h
    exact Int.cast_injective h
  extra := PUnit.unit
  ax := trivial

/-- 从嵌入的单射性推出目标特征零。这一步不平凡：
    它说明 NODS 里"扩张必须真的包含旧世界"（`emb_inj`）
    是一个**有实质内容**的约束，而不是形式过场。 -/
theorem charZero_of_emb_inj (F : Extension intModel demandField) :
    (letI : Field F.target.carrier := F.target.str; CharZero F.target.carrier) := by
  letI : Field F.target.carrier := F.target.str
  letI : NonAssocSemiring intModel.carrier :=
    SemiringLike.toNonAssocSemiring (T := CR) intModel.str
  letI : NonAssocSemiring (Model.forget CR FL F.target).carrier :=
    SemiringLike.toNonAssocSemiring (T := CR) (Model.forget CR FL F.target).str
  have hFemb : F.emb = Int.castRingHom F.target.carrier := by
    apply RingHom.ext_int
  have hinj : Function.Injective (Int.castRingHom F.target.carrier) := by
    simpa [hFemb] using F.emb_inj
  refine ⟨fun a b h => ?_⟩
  have hz : (a : ℤ) = (b : ℤ) := hinj (by
    simpa [Int.cast_natCast] using h
  )
  exact_mod_cast hz

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
  · refine ⟨{ hom := Rat.castHom F.target.carrier,
               over := ?_,
               pres := by rfl }⟩
    intro z
    simp only [Biframed.forget_toFun]
    rw [hFemb]
    show (Rat.castHom F.target.carrier) ((Int.castRingHom ℚ) z) =
      (Int.castRingHom F.target.carrier) z
    exact map_intCast (Rat.castHom F.target.carrier) z
  · intro f g
    apply ExtHom.ext
    intro x
    have hfg : f.hom = g.hom := RingHom.ext_rat (F := ℚ →+* F.target.carrier) f.hom g.hom
    rw [hfg]

end NODS
