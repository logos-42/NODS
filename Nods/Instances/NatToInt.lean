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
  exact RingHom.eq_natCast' f

/- ------------------------------------------------------------------ -/
/- 失败检测                                                            -/
/- ------------------------------------------------------------------ -/

/-- N 里 `-1` 不存在。 -/
theorem nat_no_neg_one : ¬ ∃ x : ℕ, x + 1 = 0 := by
  rintro ⟨x, hx⟩
  omega

/-- **判定**：N 承载不了"减法闭包"，即这是一个 gap（见下面 `natToInt` 给出见证）。

    注意不能走"ℕ 上不存在 CommRing 结构"这条路——那是假命题：
    ℕ 与 ℤ 可数等势，可沿双射把 `CommRing ℤ` 搬到 ℕ 上（`Equiv.commRing`）。
    真正的约束是 `HasSolution` 里的 `forgetStr s' = natModel.str`，
    它强制环的**半环部分**等于原生半环；据此把环等式 `-1 + 1 = 0`
    里的环 `+` / `0` 改写成原生 `+` / `0`，再交给 `nat_no_neg_one`。 -/
theorem nat_gap : ¬ HasSolution natModel demandRing := by
  rintro ⟨s', hstr, _e, _hax⟩
  letI : CommRing ℕ := s'
  have hneg := neg_add_cancel (1 : ℕ)
  have hbase : commRingToCommSemiring s' = (inferInstance : CommSemiring ℕ) := hstr
  have hcdef : s'.toCommSemiring = commRingToCommSemiring s' := by rfl
  have hadd : s'.toAddGroupWithOne.toAddGroup.toAddZeroClass.toAdd = @instAddNat := by
    calc
      s'.toAddGroupWithOne.toAddGroup.toAddZeroClass.toAdd = s'.toCommSemiring.toAdd := by rfl
      _ = (commRingToCommSemiring s').toAdd := by rw [← hcdef]
      _ = (inferInstance : CommSemiring ℕ).toAdd := by rw [hbase]
      _ = @instAddNat := by rfl
  rw [hadd] at hneg
  have hzeroVal :
      (s'.toAddGroupWithOne.toAddGroup.toSubNegMonoid.toAddMonoid.toAddZeroClass.toZero : Zero ℕ).zero
        = (0 : ℕ) := by
    calc
      (s'.toAddGroupWithOne.toAddGroup.toSubNegMonoid.toAddMonoid.toAddZeroClass.toZero : Zero ℕ).zero
        = (s'.toCommSemiring.toAddZeroClass.toZero : Zero ℕ).zero := by rfl
      _ = ((commRingToCommSemiring s').toAddZeroClass.toZero : Zero ℕ).zero := by rw [← hcdef]
      _ = ((inferInstance : CommSemiring ℕ).toAddZeroClass.toZero : Zero ℕ).zero := by rw [hbase]
      _ = (0 : ℕ) := by rfl
  change (-1 : ℕ) + 1 =
      (s'.toAddGroupWithOne.toAddGroup.toSubNegMonoid.toAddMonoid.toAddZeroClass.toZero : Zero ℕ).zero at hneg
  rw [hzeroVal] at hneg
  exact nat_no_neg_one ⟨(-1 : ℕ), hneg⟩

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
    change (Nat.castRingHom ℤ) a = (Nat.castRingHom ℤ) b at h
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
  letI : NonAssocSemiring natModel.carrier :=
    SemiringLike.toNonAssocSemiring (T := CS) natModel.str
  letI : NonAssocSemiring (Model.forget CS CR F.target).carrier :=
    SemiringLike.toNonAssocSemiring (T := CS) (Model.forget CS CR F.target).str
  have hFemb : F.emb = Nat.castRingHom (Model.forget CS CR F.target).carrier := by
    apply ringHom_nat_unique
  constructor
  · refine ⟨{ hom := Int.castRingHom F.target.carrier,
               over := ?_,
               pres := by rfl }⟩
    intro n
    simp only [Biframed.forget_toFun]
    rw [hFemb]
    show (Int.castRingHom F.target.carrier) ((Nat.castRingHom ℤ) n) =
      (Nat.castRingHom F.target.carrier) n
    exact Int.cast_natCast n
  · intro f g
    apply ExtHom.ext
    intro x
    have hfg : f.hom = g.hom := RingHom.ext_int f.hom g.hom
    rw [hfg]

end NODS
