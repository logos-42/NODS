/-
【实例层 0】交换半环状理论：CS ⊇ CR ⊇ FL ⊇ LOF

  CS  = CommSemiring          （N 住在这里）
  CR  = CommRing              （Z 住在这里）
  FL  = Field                 （Q 住在这里）
  LOF = LinearOrderedField    （R 住在这里）

技术要点（很要紧，写错就会卡住）：
`α →+* β` 把两端的 `NonAssocSemiring` 实例作为**类型参数**带着。
所以"忘却结构"之后，同态类型必须**在定义上**还是同一个类型，
否则 `Biframed.forgetHom` 连"恒等函数"都写不出来。

解决办法是 `SemiringLike`：每个理论显式给出"忘到 NonAssocSemiring 的路径"，
并且**规定更强的理论一律沿强化路径委托给更弱的理论**。
这样 `SemiringLike.toNonAssocSemiring (T:=CR) s`
与 `SemiringLike.toNonAssocSemiring (T:=CS) (forgetStr s)`
就是同一个项，`forgetHom` 可以取恒等。
-/

import Mathlib
import Nods.Core.Framework

namespace NODS

/-- "交换半环状"理论：能忘到一个 `NonAssocSemiring`。 -/
class SemiringLike (T : Theory) where
  toNonAssocSemiring : {α : Type u} → T α → NonAssocSemiring α

/-- 只要 T 是交换半环状的，就有现成的语架：同态就是 `→+*`。 -/
instance frameworkOfSemiringLike [SemiringLike T] : Framework T where
  Hom := fun M N => by
    letI : NonAssocSemiring M.carrier := SemiringLike.toNonAssocSemiring (T := T) M.str
    letI : NonAssocSemiring N.carrier := SemiringLike.toNonAssocSemiring (T := T) N.str
    exact (M.carrier →+* N.carrier)
  id := fun M => by
    letI : NonAssocSemiring M.carrier := SemiringLike.toNonAssocSemiring (T := T) M.str
    exact RingHom.id M.carrier
  comp := by
    intro M N P f g
    letI : NonAssocSemiring M.carrier := SemiringLike.toNonAssocSemiring (T := T) M.str
    letI : NonAssocSemiring N.carrier := SemiringLike.toNonAssocSemiring (T := T) N.str
    letI : NonAssocSemiring P.carrier := SemiringLike.toNonAssocSemiring (T := T) P.str
    exact g.comp f
  toFun := fun {M N} f => f
  id_apply := by intros M x; rfl
  comp_apply := by intros M N P f g x; rfl
  ext := by
    intro M N f g h
    exact RingHom.ext h

-- 四个理论
abbrev CS : Theory := fun α : Type => CommSemiring α
abbrev CR : Theory := fun α : Type => CommRing α
abbrev FL : Theory := fun α : Type => Field α
/-- 线性有序域。mathlib 已弃用 `LinearOrderedField` 这一捆绑结构，
    改用 `[Field] + [LinearOrder] + [IsStrictOrderedRing]` 三个实例。
    这里把它重新捆成一个结构，好让 `LOF` 继续作为 Theory 使用。 -/
structure LOF (α : Type) where
  toField : Field α
  toLinearOrder : LinearOrder α
  toIsStrictOrderedRing :
    @IsStrictOrderedRing α toField.toCommRing.toRing.toSemiring toLinearOrder.toPartialOrder

-- 三条规范忘却路径。**全局只此一份**：
-- `SemiringLike` 与 `Refinement` 都必须走这几个函数，
-- 否则忘却后的 `→+*` 类型会与原类型只是同构而不是同一个，
-- `Biframed.forgetHom` 就连恒等函数都写不出来。
def commRingToCommSemiring {α : Type} (s : CommRing α) : CommSemiring α := by
  letI : CommRing α := s
  exact inferInstance

def fieldToCommRing {α : Type} (s : Field α) : CommRing α := s.toCommRing

def lofToField {α : Type} (s : LOF α) : Field α := s.toField

-- 忘到半环的路径：每一级都**委托**给下一级
instance : SemiringLike CS where
  toNonAssocSemiring := fun {α} s => by
    letI : CommSemiring α := s
    exact inferInstance

instance : SemiringLike CR where
  toNonAssocSemiring := fun {α} s =>
    SemiringLike.toNonAssocSemiring (T := CS) (α := α) (commRingToCommSemiring s)

instance : SemiringLike FL where
  toNonAssocSemiring := fun {α} s =>
    SemiringLike.toNonAssocSemiring (T := CR) (α := α) (fieldToCommRing s)

instance : SemiringLike LOF where
  toNonAssocSemiring := fun {α} s =>
    SemiringLike.toNonAssocSemiring (T := FL) (α := α) (lofToField s)

-- 理论强化（忘却）
instance : Refinement CS CR where
  forgetStr := fun s => commRingToCommSemiring s

instance : Refinement CR FL where
  forgetStr := fun s => fieldToCommRing s

instance : Refinement FL LOF where
  forgetStr := fun s => lofToField s

instance : Refinement CR LOF where
  forgetStr := fun s => fieldToCommRing (lofToField s)

instance : Refinement CS FL where
  forgetStr := fun s => commRingToCommSemiring (fieldToCommRing s)

instance : Refinement CS LOF where
  forgetStr := fun s => commRingToCommSemiring (fieldToCommRing (lofToField s))

-- 忘却作用在 RingHom 上是恒等（因为上面把路径对齐了）
instance biframedSelf (T : Theory) [Framework T] : Biframed T T where
  forgetHom := fun f => f
  forget_id := fun M => rfl
  forget_comp := by intros M N P f g; rfl
  forget_toFun := by intros M N f x; rfl

instance : Biframed CS CR where
  forgetHom := fun f => f
  forget_id := fun M => rfl
  forget_comp := by intros M N P f g; rfl
  forget_toFun := by intros M N f x; rfl

instance : Biframed CR FL where
  forgetHom := fun f => f
  forget_id := fun M => rfl
  forget_comp := by intros M N P f g; rfl
  forget_toFun := by intros M N f x; rfl

instance : Biframed FL LOF where
  forgetHom := fun f => f
  forget_id := fun M => rfl
  forget_comp := by intros M N P f g; rfl
  forget_toFun := by intros M N f x; rfl

instance : Biframed CR LOF where
  forgetHom := fun f => f
  forget_id := fun M => rfl
  forget_comp := by intros M N P f g; rfl
  forget_toFun := by intros M N f x; rfl

instance : Biframed CS FL where
  forgetHom := fun f => f
  forget_id := fun M => rfl
  forget_comp := by intros M N P f g; rfl
  forget_toFun := by intros M N f x; rfl

instance : Biframed CS LOF where
  forgetHom := fun f => f
  forget_id := fun M => rfl
  forget_comp := by intros M N P f g; rfl
  forget_toFun := by intros M N f x; rfl

end NODS
