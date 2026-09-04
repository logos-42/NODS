/-
【实例 1】N → Z ：减法闭包失败

失败的**具体形式**：在 N 里 `x + 1 = 0` 无解。

但要注意这一步的真实性质：它不是"添一个元素"，
而是**换一个范畴**。如果只是往 N 里丢一个符号 ε 并规定 ε + 1 = 0，
得到的不是 Z，而是某个加法非群的交换半环怪物。
只有把背景理论取成 `CommRing` 时，"最小扩张"才是 Z。

这一点写不进框架就会出错，所以 `Demand` 里 T' 是显式参数。
-/

import Mathlib
import Nods.Core.Engine
import Nods.Theories.Algebraic

namespace NODS

/- ------------------------------------------------------------------ -/
/- 世界与需求                                                          -/
/- ------------------------------------------------------------------ -/

abbrev natModel : Model CS := Model.ofType ℕ (inferInstance : CommSemiring ℕ)
abbrev intModel : Model CR := Model.ofType ℤ (inferInstance : CommRing ℤ)

/-- 需求：换到交换环。Extra 为空 —— 这一步纯粹是理论强化。 -/
def demandRing : Demand CS CR where
  Extra := fun _ => PUnit
  Axiom := fun _ _ => True
  mapExtra := fun _ e => e
  mapExtra_id := by intros; rfl
  mapExtra_comp := by intros; rfl

/-- 从 N 出发的半环同态是唯一的（N 是半环范畴的初始对象）。
    这条引理在下面证明"Z 是极小的"时要用到。 -/
theorem ringHom_nat_unique {α : Type} [NonAssocSemiring α] (f : ℕ →+* α) :
    f = Nat.castRingHom α := by
  apply RingHom.ext
  intro n
  induction n with
  | zero => simp
  | succ n ih =>
      show f (n + 1) = ((n + 1 : ℕ) : α)
      calc
        f (n + 1) = f n + f 1 := by rw [map_add]
        _ = (n : α) + 1 := by rw [ih, map_one]
        _ = ((n + 1 : ℕ) : α) := by rw [Nat.cast_add, Nat.cast_one]

/- ------------------------------------------------------------------ -/
/- 失败检测                                                            -/
/- ------------------------------------------------------------------ -/

/-- N 里 `-1` 不存在。 -/
theorem nat_no_neg_one : ¬ ∃ x : ℕ, x + 1 = 0 := by
  rintro ⟨x, hx⟩
  omega

/-- N 上不存在交换环结构。 -/
theorem no_commRing_on_nat : ¬ Nonempty (CommRing ℕ) := by
  rintro ⟨s⟩
  letI := s
  exact nat_no_neg_one ⟨(-1 : ℕ), by simp⟩

/-- **判定**：N 承载不了"减法闭包"，即这是一个 gap（见下面 `natExt` 给出见证）。 -/
theorem nat_gap : ¬ HasSolution natModel demandRing := by
  rintro ⟨s', _hstr, _e, _hax⟩
  exact no_commRing_on_nat ⟨s'⟩

/- ------------------------------------------------------------------ -/
/- 极小扩张：Z                                                         -/
/- ------------------------------------------------------------------ -/

/-- Z 作为 N 的扩张。 -/
noncomputable def natToInt : Extension natModel demandRing where
  target := intModel
  emb := by
    letI : NonAssocSemiring natModel.carrier :=
      SemiringLike.toNonAssocSemiring (T := CS) natModel.str
    letI : NonAssocSemiring (Model.forget CS CR intModel).carrier :=
      SemiringLike.toNonAssocSemiring (T := CS) (Model.forget CS CR intModel).str
    exact Nat.castRingHom ℤ
  emb_inj := by
    intro a b h
    exact Nat.cast_injective h
  extra := PUnit.unit
  ax := trivial

/-- **Z 是极小扩张**：在"交换环 + 嵌入 N"这个范畴里，Z 是初始对象。

    存在性用 `Int.castRingHom`（Z 到任何环都有唯一的环同态）；
    唯一性用 `RingHom.ext_int`。
    注意 `over` 这一步必须先把 `F.emb` 识别成 `Nat.castRingHom`
    （用上面的 `ringHom_nat_unique`），否则无从比较。 -/
noncomputable def natToInt_minimal : IsMinimal natModel demandRing natToInt := by
  intro F
  letI : CommRing F.target.carrier := F.target.str
  letI : NonAssocSemiring intModel.carrier :=
    SemiringLike.toNonAssocSemiring (T := CR) intModel.str
  letI : NonAssocSemiring F.target.carrier :=
    SemiringLike.toNonAssocSemiring (T := CR) F.target.str
  have hFemb : F.emb = (by
      letI : NonAssocSemiring natModel.carrier :=
        SemiringLike.toNonAssocSemiring (T := CS) natModel.str
      letI : NonAssocSemiring (Model.forget CS CR F.target).carrier :=
        SemiringLike.toNonAssocSemiring (T := CS) (Model.forget CS CR F.target).str
      exact Nat.castRingHom F.target.carrier) := by
    apply ringHom_nat_unique
  constructor
  · refine ⟨{ hom := Int.castRingHom F.target.carrier
               over := ?_
               pres := by rfl }⟩
    intro n
    simp only [Biframed.forget_toFun]
    change (Int.castRingHom F.target.carrier) ((Nat.castRingHom ℤ) n) = F.emb n
    rw [hFemb]
    simp
  · intro f g
    apply ExtHom.ext
    intro x
    have hfg : f.hom = g.hom := RingHom.ext_int f.hom g.hom
    rw [hfg]

end NODS
