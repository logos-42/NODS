/-
【核心层 2】需求 · 扩张 · 扩张同态

一个 `Demand T T'` 描述"当前世界缺什么"：
    * 换到更强的理论 T'（Refinement），
    * 并/或 在语言里添一个常元（Extra），
    * 并/或 要求一个性质（Axiom）。

三种经典扩张对应三种用法：

    N → Z :  T = CS, T' = CR,  Extra = PUnit, Axiom = True
             → 纯粹是**理论强化**：减法全可解不是"添一个元素"，
               而是"换一个范畴"。把 T' 取成 CS 会得到非群的怪物，
               只有取 CR 时极小扩张才是 Z。
    Z → Q :  T = CR, T' = FL,  Extra = PUnit, Axiom = True
             → 同样是理论强化（除法全可解）。
    Q → R :  T = FL, T' = LOF, Extra = PUnit, Axiom = 完备性
             → 理论强化 + 一个**不具泛性质**的性质。
    R → C :  T = T' = CR,      Extra = 载体,   Axiom = j² = -1
             → 理论不变，只是**添常元**。

一个重要发现（写这一层时才看清的）：

  **Axiom 不要求沿同态前向保持。**

原因是：要求"前向保持"等价于要求该性质是**语言里的等式公理**。
`j*j = -1` 属于这一类（所以 R→C 有真正的泛性质/初始性），
而"Dedekind 完备""Archimedean"不属于（它们不被任意环同态保持，
所以 Q→R **没有**初始性，R 只是"没有真子完备扩张"意义下的极小）。

因此 NODS v0.1 把两类极小性分开：
    IsMinimal      —— 初始性（泛性质），适用于常元型需求
    IsCutGenerated —— 切割生成性，适用于完备化型需求（见 RatToReal）
-/

import Nods.Core.Framework

namespace NODS

universe u

variable [Framework T] [Framework T'] [Refinement T T'] [Biframed T T']

/-- 需求。 -/
structure Demand (T T' : Theory) [Framework T] [Framework T'] [Refinement T T'] where
  /-- 额外数据（要添的常元）。不需要添时取 `PUnit`。 -/
  Extra : Model T' → Type u
  /-- 额外公理/性质。 -/
  Axiom : (M : Model T') → Extra M → Prop
  /-- 同态把见证**向前**搬。这是"初始性"能刻画"最小"的前提：
      只有语言里的常元才能被前向搬运。 -/
  mapExtra : {M N : Model T'} → Framework.Hom (T := T') M N → Extra M → Extra N
  mapExtra_id : ∀ (M : Model T') (e : Extra M),
    mapExtra (Framework.id (T := T') M) e = e
  mapExtra_comp : ∀ {M N P : Model T'} (f : Framework.Hom (T := T') M N)
    (g : Framework.Hom (T := T') N P) (e : Extra M),
    mapExtra (Framework.comp f g) e = mapExtra g (mapExtra f e)

/-- 需求在 M 上的一个解（见证 + 公理证明）。
    （用 `Subtype` 而不是 `Sigma`：公理是 Prop，不是 Type。） -/
def Demand.Inst (D : Demand T T') (M : Model T') := { e : D.Extra M // D.Axiom M e }

/-- 当前世界 S（T-模型）的一个 T'-扩张：
    一个 T' 模型 M、一个从 S 出发的单射嵌入、以及需求在 M 上的解。 -/
structure Extension (S : Model T) (D : Demand T T') where
  target : Model T'
  emb : Framework.Hom (T := T) S (Model.forget T T' target)
  emb_inj : Function.Injective (Framework.toFun emb)
  extra : D.Extra target
  ax : D.Axiom target extra

/-- 扩张之间的态射：保嵌入（在 S 上一致）且保见证。 -/
structure ExtHom (S : Model T) (D : Demand T T') (E F : Extension S D) where
  hom : Framework.Hom (T := T') E.target F.target
  over : ∀ x : S.carrier,
    Framework.toFun (Biframed.forgetHom hom) (Framework.toFun E.emb x) = Framework.toFun F.emb x
  pres : D.mapExtra hom E.extra = F.extra

namespace ExtHom

variable {T T' : Theory} [Framework T] [Framework T'] [Refinement T T'] [Biframed T T']
  {S : Model T} {D : Demand T T'} {E F G : Extension S D}

/-- 扩张态射由底层模型同态决定（其余两个字段是 Prop）。 -/
theorem ext {E F : Extension S D} {f g : ExtHom S D E F}
    (h : ∀ x : E.target.carrier, Framework.toFun f.hom x = Framework.toFun g.hom x) :
    f = g := by
  cases f with
  | mk fh _ _ =>
  cases g with
  | mk gh _ _ =>
  have hhom : fh = gh := Framework.ext h
  subst hhom
  rfl

/-- 恒等态射。 -/
def id (E : Extension S D) : ExtHom S D E E where
  hom := Framework.id (T := T') E.target
  over := by
    intro x
    simp [Biframed.forget_toFun, Framework.id_apply]
  pres := D.mapExtra_id E.target E.extra

/-- 复合。注意 `over` 的证明是"沿 S 的嵌入走一圈"，
    这正是扩张范畴（comma 范畴 S ↓ Mod T'）的复合。 -/
def comp (g : ExtHom S D E F) (h : ExtHom S D F G) : ExtHom S D E G where
  hom := Framework.comp g.hom h.hom
  over := by
    intro x
    calc
      Framework.toFun (Biframed.forgetHom (Framework.comp g.hom h.hom))
          (Framework.toFun E.emb x)
        = Framework.toFun (Framework.comp (Biframed.forgetHom g.hom)
            (Biframed.forgetHom h.hom)) (Framework.toFun E.emb x) := by
            rw [Biframed.forget_comp]
      _ = Framework.toFun (Biframed.forgetHom h.hom)
            (Framework.toFun (Biframed.forgetHom g.hom) (Framework.toFun E.emb x)) := by
            rw [Framework.comp_apply]
      _ = Framework.toFun (Biframed.forgetHom h.hom) (Framework.toFun F.emb x) := by
            rw [g.over x]
      _ = Framework.toFun G.emb x := h.over x
  pres := by
    rw [D.mapExtra_comp, g.pres, h.pres]

end ExtHom

/-- 极小扩张 = 扩张范畴里的**初始对象**。
    注意：这是相对于 (T, T', D) 的极小性，没有绝对意义。 -/
def IsMinimal (S : Model T) (D : Demand T T') (E : Extension S D) : Prop :=
  ∀ F : Extension S D, Nonempty (ExtHom S D E F) ∧ (∀ f g : ExtHom S D E F, f = g)

end NODS
