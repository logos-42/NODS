/-
【理论层】哥德尔边界 — 哥德尔现象在 NODS 里的结构骨架

诚实边界（先说清，再证明）：
  本文件**不形式化哥德尔不完备定理本身**。那需要语法编码、可证性谓词、
  对角线引理与一致性元定理，是 design.md 意义上的"困难函数"，留成输入。
  本文件形式化的是：把哥德尔定理**保证存在的那种结构**（一个句子在理论中
  不可判定，且有两个一致补全）做成 NODS 的 Model / Demand，然后证明：

    这种补全在 NODS 判据下 = gap，但 `IsMinimal` 失败、且按"载体等价=改名"
    的 novelty 口径过不了 objective 闸门 ⟹ 不构成 NODS 意义上的"发现"。

  因此本文件证明的是"哥德尔现象在 NODS 里如何被分类"，不是"哥德尔定理为真/为假"。

对应计划：docs/wiki/godel-boundary-plan.md 的 P2 / P3 / P4。
-/

import Nods.Core.Engine

universe u

namespace NODS

/- ============================================================
   §1  理论："肯定/否定 + 一致性"结构
   ============================================================ -/

/-- 一个决策理论：在每个句子上标记"可证(yes)" / "可反驳(no)"，并要求两者不交。
    一致性被放进结构本身，所以不一致的理论根本不是本范畴的对象。 -/
structure Decision (α : Type u) where
  yes : Set α
  no : Set α
  consistent : Disjoint yes no

/-- 把它注册成 NODS 的理论（Theory = Type → Type）。 -/
abbrev Dec : Theory := Decision

/- ============================================================
   §2  Framework 实例：同态 = 保 yes / 保 no 的函数
   ============================================================ -/

instance : Framework Dec where
  Hom M N := { f : M.carrier → N.carrier //
    (∀ x, x ∈ M.str.yes → f x ∈ N.str.yes) ∧
    (∀ x, x ∈ M.str.no → f x ∈ N.str.no) }
  id M := ⟨id, by constructor <;> intro x hx <;> exact hx⟩
  comp f g := ⟨fun x => g.1 (f.1 x), by
    constructor
    · intro x hx
      exact g.2.1 (f.1 x) (f.2.1 x hx)
    · intro x hx
      exact g.2.2 (f.1 x) (f.2.2 x hx)⟩
  toFun f := f.1
  id_apply := by intro M x; rfl
  comp_apply := by intro M N P f g x; rfl
  ext := by
    intro M N f g h
    cases f with
    | mk f hf =>
      cases g with
      | mk g hg =>
        have hfg : f = g := funext h
        subst hfg
        rfl

/- §2.1  恒等强化 Dec → Dec 的 Biframed。
   Model.forget Dec Dec M 与 M 定义相等，forgetHom 取恒等。 -/

instance : Biframed Dec Dec where
  forgetHom := fun {M N} f => f
  forget_id := by intro M; rfl
  forget_comp := by intro M N P f g; rfl
  forget_toFun := by intro M N f x; rfl

/- ============================================================
   §3  需求："决定某个句子" —— Extra = 一个已被决定的句子
   ============================================================ -/

/-- 需求 D：在当前理论上添加一个"被决定的句子"见证。
    Axiom 取 True：见证自带 yes/no 的证明，所以不需要额外约束。
    与 R→C 同型（Extra = 常元，Axiom = 性质），但这里同态前向搬运见证。 -/
def decideDemand : Demand Dec Dec where
  Extra M := { x : M.carrier // x ∈ M.str.yes ∨ x ∈ M.str.no }
  Axiom M e := True
  mapExtra f e := ⟨Framework.toFun f e.1, by
    rcases e.2 with h | h
    · exact Or.inl (f.2.1 e.1 h)
    · exact Or.inr (f.2.2 e.1 h)⟩
  mapExtra_id := by
    intro M e
    apply Subtype.ext
    simp [Framework.id_apply]
  mapExtra_comp := by
    intro M N P f g e
    apply Subtype.ext
    simp [Framework.comp_apply]

/- ============================================================
   §4  哥德尔骨架：不可判定句子 + 两个一致补全
   ============================================================ -/

abbrev Sent := Nat
def godelSent : Sent := 0

/-- 当前世界：句子 godelSent 既不可证也不可反驳（yes = no = ∅）。
    这正是哥德尔句子在基础理论中的状态。 -/
def base : Model Dec :=
  ⟨Sent, { yes := ∅, no := ∅, consistent := by simp }⟩

/-- 补全 "+": godelSent 可证。 -/
def completionPlus : Model Dec :=
  ⟨Sent, { yes := ({godelSent} : Set Sent), no := ∅, consistent := by simp }⟩

/-- 补全 "-": godelSent 可反驳。 -/
def completionMinus : Model Dec :=
  ⟨Sent, { yes := ∅, no := ({godelSent} : Set Sent), consistent := by simp }⟩

/- §4.1  base 到两个补全的嵌入（同一载体，恒等函数）。 -/

def embPlus : Framework.Hom (T := Dec) base (Model.forget Dec Dec completionPlus) :=
  ⟨id, by
    constructor
    · intro x hx
      simp [base] at hx
      exact hx.elim
    · intro x hx
      simp [base] at hx
      exact hx.elim⟩

def embMinus : Framework.Hom (T := Dec) base (Model.forget Dec Dec completionMinus) :=
  ⟨id, by
    constructor
    · intro x hx
      simp [base] at hx
      exact hx.elim
    · intro x hx
      simp [base] at hx
      exact hx.elim⟩

/-- 两个补全都是同一需求 D 的扩张。 -/
def plusExt : Extension base decideDemand where
  target := completionPlus
  emb := embPlus
  emb_inj := Function.injective_id
  extra := ⟨godelSent, Or.inl (by
    show godelSent ∈ completionPlus.str.yes
    exact Set.mem_singleton_iff.mpr rfl)⟩
  ax := trivial

def minusExt : Extension base decideDemand where
  target := completionMinus
  emb := embMinus
  emb_inj := Function.injective_id
  extra := ⟨godelSent, Or.inr (by
    show godelSent ∈ completionMinus.str.no
    exact Set.mem_singleton_iff.mpr rfl)⟩
  ax := trivial

/- ============================================================
   §5  P3 主定理：两个补全之间无 ExtHom ⟹ 极小性失败
   ============================================================ -/

/-- 力学支点：由于嵌入是恒等、载体相同，over_prop 强制任何 ExtHom 的底层
    函数在 godelSent 上为恒等；而恒等不保 yes（godelSent 在 + 中可证、在 - 中不可证）。 -/
theorem no_extHom_plus_minus : IsEmpty (ExtHom base decideDemand plusExt minusExt) := by
  constructor
  intro h
  have hp : Framework.toFun h.hom godelSent = godelSent := by
    have hx := h.over_prop godelSent
    rw [show Framework.toFun plusExt.emb godelSent = godelSent from rfl,
        show Framework.toFun minusExt.emb godelSent = godelSent from rfl] at hx
    rw [show Biframed.forgetHom h.hom = h.hom from rfl] at hx
    exact hx
  have hyes : Framework.toFun h.hom godelSent ∈ completionMinus.str.yes :=
    h.hom.2.1 godelSent (by
      show godelSent ∈ completionPlus.str.yes
      exact Set.mem_singleton_iff.mpr rfl)
  rw [hp] at hyes
  simp [completionMinus] at hyes
  exact hyes.elim

/-- **P3 结论**：哥德尔补全不是极小扩张。
    这是 NODS 对哥德尔现象的核心裁决：它是 gap，但不是"被迫发现的对象"。 -/
theorem godel_completion_not_minimal : ¬ IsMinimal base decideDemand plusExt := by
  intro hmin
  have hne : Nonempty (ExtHom base decideDemand plusExt minusExt) := (hmin minusExt).1
  obtain ⟨f⟩ := hne
  exact no_extHom_plus_minus.false f

/- ============================================================
   §6  闸门：载体等价 ⟹ novelty = 0 ⟹ objective = 0
   ============================================================ -/

/-- 补全 + 与 base 载体相同，故相对任何包含 base 的库都是改名。 -/
theorem completion_is_renaming_of_base (L : Library Dec) (i : L.Index)
    (hLi : L.get i = base) : IsRenamingOf L completionPlus := by
  refine ⟨i, ?_⟩
  rw [hLi]
  exact ⟨Equiv.refl Sent⟩

/-- 因此任何忠实记录 novelty 的快照，目标函数都为 0 —— 过不了准入闸门。 -/
theorem godel_completion_objective_zero (L : Library Dec) (i : L.Index)
    (hLi : L.get i = base) (x : Snapshot)
    (hx : x.novelty = noveltyAgainst L completionPlus) :
    x.objective = 0 :=
  renaming_kills_objective L completionPlus x
    (completion_is_renaming_of_base L i hLi) hx

/- ============================================================
   §7  P4 对照：已决定的句子 ⟹ solved，不产生新对象
   ============================================================ -/

/-- 若理论已经决定了 godelSent（如 e、π 的超越性已在 ZFC 中证明），
    需求在同一载体上已解，按 Verdict.solved 分支不产生新对象。 -/
theorem decided_is_solved : HasSolution completionPlus decideDemand := by
  refine ⟨completionPlus.str, rfl, ?_⟩
  exact ⟨⟨godelSent, Or.inl (by
    show godelSent ∈ completionPlus.str.yes
    exact Set.mem_singleton_iff.mpr rfl)⟩, trivial⟩

end NODS
