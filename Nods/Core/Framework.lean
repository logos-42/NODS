/-
NODS v0.1 — New Object Discovery System
========================================
【核心层 1】理论 · 模型 · 语架 · 理论强化

这一层里藏着整个形式化最关键的一个判断，必须先说清楚：

  **"最小扩张"不是绝对概念。**

它只有相对于
    (a) 一个背景理论 T'（扩张必须住在哪个范畴里），
    (b) 一条从当前理论 T 到 T' 的忘却（refinement），
才有意义。否则"最小"根本没有定义：你既可以取一个平凡/混沌的扩张，
也可以取一个大得离谱的扩张，两者之间没有任何"最小"可言。

举三个例子，说明为什么必须把 T' 显式化：
  * N → Z ：需求是"减法全可解"。这在某些交换半环里也能"解"，
            但得到一个非群的怪物。只有把 T' 取成 CommRing，
            极小扩张才是 Z。也就是说：这一步的真身是**理论强化**，
            不是"添一个元素"。
  * Z → Q ：同理，T' 必须取成 Field（且特征零），极小扩张才是 Q。
  * R → C ：T' = CommRing 不变，只是在语言里**添一个常元 j** 并
            要求 j² = -1。这一步才是真正的"添元素"。

所以 NODS 有两种"迫使新对象出现"的机制：
    Refinement  —— 换一个更强的理论（N→Z、Z→Q、Q→R）
    Extra/Axiom —— 在同一理论里添新常元并加公理（R→C）
两者在下面的 `Demand` 结构里是统一的。

作者注：这一层刻意只要求很少的公理（id/comp/toFun/ext），
因为它们恰好就是证明"极小扩张在唯一同构意义下唯一"所需的全部。
-/

import Mathlib

universe u

namespace NODS

/-- 一个"理论"：给每个类型指定"该类型上这种结构"的类型。
    例：`fun α => CommSemiring α`、`fun α => Field α`。 -/
abbrev Theory := Type u → Type u

/-- T-模型 = 载体 + 结构。 -/
structure Model (T : Theory) : Type (u + 1) where
  carrier : Type u
  str : T carrier

namespace Model

/-- 从一个类型 + 其上的结构直接做一个模型。
    （这里刻意不用 instance binder：`T` 是任意理论，
      `T α` 未必是一个 class。） -/
protected def ofType (α : Type u) (s : T α) : Model T := ⟨α, s⟩

end Model

/-- 语架：把 T-模型组织成一个**忠实于 Type 的具体范畴**。
    `toFun` + `ext` 说明同态由底层函数决定，`id_apply`/`comp_apply`
    说明 `toFun` 与恒等、复合相容。 -/
class Framework (T : Theory) where
  Hom : Model T → Model T → Type u
  id : (M : Model T) → Hom M M
  comp : {M N P : Model T} → Hom M N → Hom N P → Hom M P
  toFun : {M N : Model T} → Hom M N → M.carrier → N.carrier
  id_apply : ∀ {M : Model T} (x : M.carrier), toFun (id M) x = x
  comp_apply : ∀ {M N P : Model T} (f : Hom M N) (g : Hom N P) (x : M.carrier),
    toFun (comp f g) x = toFun g (toFun f x)
  ext : ∀ {M N : Model T} {f g : Hom M N}, (∀ x : M.carrier, toFun f x = toFun g x) → f = g

attribute [simp] Framework.id_apply Framework.comp_apply

namespace Framework

variable [Framework T]

/-- 复合的右单位元。 -/
theorem comp_id {M N : Model T} (f : Hom (T := T) M N) :
    comp f (id (T := T) N) = f := by
  apply ext
  intro x
  simp

/-- 复合的左单位元。 -/
theorem id_comp {M N : Model T} (f : Hom (T := T) M N) :
    comp (id (T := T) M) f = f := by
  apply ext
  intro x
  simp

/-- 复合结合律。 -/
theorem comp_assoc {M N P Q : Model T}
    (f : Hom (T := T) M N) (g : Hom (T := T) N P) (h : Hom (T := T) P Q) :
    comp (comp f g) h = comp f (comp g h) := by
  apply ext
  intro x
  simp

end Framework

/-- 理论强化：T' 的结构忘却成 T 的结构，载体不变。
    例：`Field α → CommRing α`、`CommRing α → CommSemiring α`。 -/
class Refinement (T T' : Theory) where
  forgetStr : {α : Type u} → T' α → T α

/-- 把 T'-模型沿忘却看成 T-模型。 -/
def Model.forget (T T' : Theory) [Refinement T T'] (M : Model T') : Model T :=
  ⟨M.carrier, Refinement.forgetStr M.str⟩

/-- 语架对：忘却也作用在**同态**上，并且与 id / comp / toFun 相容。
    在 v0.1 的所有实例里，忘却就是"丢弃一部分结构"，
    同态（RingHom）本身不变，所以 `forgetHom` 一律是恒等函数。 -/
class Biframed (T T' : Theory) [Framework T] [Framework T'] [Refinement T T'] where
  forgetHom : {M N : Model T'} →
    Framework.Hom (T := T') M N →
    Framework.Hom (T := T) (Model.forget T T' M) (Model.forget T T' N)
  forget_id : ∀ (M : Model T'),
    forgetHom (Framework.id (T := T') M) = Framework.id (T := T) (Model.forget T T' M)
  forget_comp : ∀ {M N P : Model T'}
    (f : Framework.Hom (T := T') M N) (g : Framework.Hom (T := T') N P),
    forgetHom (Framework.comp f g) = Framework.comp (forgetHom f) (forgetHom g)
  forget_toFun : ∀ {M N : Model T'} (f : Framework.Hom (T := T') M N) (x : M.carrier),
    Framework.toFun (forgetHom f) x = Framework.toFun f x

attribute [simp] Biframed.forget_toFun

/-- 恒等强化：每个理论忘却到自身。 -/
instance (T : Theory) : Refinement T T where
  forgetStr := fun s => s

/-- 强化的复合：T'' → T' → T。 -/
def Refinement.trans (T T' T'' : Theory) [Refinement T T'] [Refinement T' T''] :
    Refinement T T'' where
  forgetStr := fun s => (Refinement.forgetStr (T := T) (T' := T') (Refinement.forgetStr s))

end NODS
