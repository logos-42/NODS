/-
【核心层 4】极小扩张的唯一性

这一层只有两个定理，但它们是整个形式化的**立身之本**：

  1. `IsMinimal.carrierEquiv`
     两个极小扩张的载体典范等价（并且连接它们的态射唯一）。
     → "最小扩张"不是算法拍脑袋的输出，它在**唯一同构意义下唯一**。
       这是 NODS 敢声称"发现了一个对象"而不是"编了一个符号"的依据。

  2. `IsMinimal.rigid`
     极小扩张没有非平凡自同态。
     → 这是"刚性"。C 之所以是 C 而不是"某个带 j 的环"，
       正是因为 (C, i) 的自同构群平凡（而 (C, -i) 是另一个点化结构，
       两者唯一同构 —— 那个同构就是共轭）。

注意这两个定理**在语架层面完全通用**：它们只用到了
id/comp/toFun/ext 四条公理，与具体是环、域还是别的什么无关。
这正是把 Theorem 做在 Core 层、把实例做在 Instances 层的好处。
-/

import Nods.Core.Demand

namespace NODS

universe u

variable {T T' : Theory} [Framework T] [Framework T'] [Refinement T T'] [Biframed T T']
variable {S : Model T} {D : Demand T T'} {E F G : Extension S D}

namespace IsMinimal

/-- 从极小性取出到任意扩张的唯一态射。 -/
noncomputable def homTo (hE : IsMinimal S D E) (F : Extension S D) : ExtHom S D E F :=
  Classical.choice (hE F).1

/-- 任意两个从极小扩张出发的态射相等。 -/
theorem hom_unique (hE : IsMinimal S D E) {F : Extension S D}
    (f g : ExtHom S D E F) : f = g :=
  (hE F).2 f g

/-- **刚性**：极小扩张的自同态只有恒等。
    推论：极小扩张没有非平凡自同构 —— "这个对象被需求唯一钉死"。 -/
theorem rigid (hE : IsMinimal S D E) (f : ExtHom S D E E) : f = ExtHom.id E :=
  (hE E).2 f (ExtHom.id E)

/-- 唯一性（载体层面）：两个极小扩张的载体典范等价。

    证明只用一句话：往两个方向各取唯一态射，
    复合后是 E 的自同态，由刚性知它等于恒等。 -/
noncomputable def carrierEquiv (hE : IsMinimal S D E) (hF : IsMinimal S D F) :
    E.target.carrier ≃ F.target.carrier :=
  let f := homTo (S := S) (D := D) hE F
  let g := homTo (S := S) (D := D) hF E
  { toFun := Framework.toFun f.hom
    invFun := Framework.toFun g.hom
    left_inv := by
      intro x
      have heq : ExtHom.comp f g = ExtHom.id E := rigid (S := S) (D := D) hE (ExtHom.comp f g)
      have hpt := congrArg (fun (k : ExtHom S D E E) => Framework.toFun k.hom x) heq
      simpa [Framework.comp_apply, Framework.id_apply] using hpt
    right_inv := by
      intro x
      have heq : ExtHom.comp g f = ExtHom.id F := rigid (S := S) (D := D) hF (ExtHom.comp g f)
      have hpt := congrArg (fun (k : ExtHom S D F F) => Framework.toFun k.hom x) heq
      simpa [Framework.comp_apply, Framework.id_apply] using hpt }

/-- 上面的等价是**唯一**的连接方式：
    任何从 E 到 F 的扩张态射，底层函数都等于这个等价。 -/
theorem carrierEquiv_unique (hE : IsMinimal S D E) (hF : IsMinimal S D F)
    (f : ExtHom S D E F) (x : E.target.carrier) :
    Framework.toFun f.hom x = carrierEquiv hE hF x := by
  have hfg : f = homTo (S := S) (D := D) hE F := hom_unique hE f _
  rw [hfg]
  rfl

end IsMinimal

/-- 一个扩张是"自由的/泛的"，当且仅当它是初始的。
    v0.1 里 `IsMinimal` 就是这个意思；这条别名只是为了让
    Instances 层的代码读起来更接近数学直觉。 -/
abbrev IsUniversalExtension (S : Model T) (D : Demand T T') (E : Extension S D) : Prop :=
  IsMinimal S D E

end NODS
