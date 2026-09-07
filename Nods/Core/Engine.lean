/-
【核心层 6】发现引擎

design.md §9 把 NODS 的核心写成四个"困难函数"：

    solve_in_structure()
    synthesize_new_object()
    minimality()
    consistent()

v0.1 对它们的处理是**诚实的**：不假装实现，而是把它们做成
**证明义务（输入）**。引擎负责的是它们之外的全部结构：
判定分支、唯一性、评分闸门、以及"新世界确实更强"这些定理。

这样设计的好处是：引擎的**正确性定理是可以证明的**，
而"困难函数"的正确性由每个实例单独负责。
把困难的东西显式留成洞，比假装它不存在要好。
-/

import Nods.Core.Score
import Nods.Core.Verdict
import Nods.Core.Minimal

namespace NODS

variable {T T' : Theory} [Framework T] [Framework T'] [Refinement T T'] [Biframed T T']
variable {S : Model T} {D : Demand T T'}

/-- 一次发现：判定 + 候选扩张 + 极小性证明 + 评分。 -/
structure Discovery (S : Model T) (D : Demand T T') where
  verdict : Verdict S D
  candidate : Extension S D
  minimal : IsMinimal S D candidate
  snapshot : Snapshot

namespace Discovery

/-- **进展定理**：不管判定是哪一个分支，候选扩张都真的解决了需求。
    （这条不需要任何假设 —— 它是 `Extension` 结构自带的事实。） -/
theorem solves (d : Discovery S D) : D.Axiom d.candidate.target d.candidate.extra :=
  d.candidate.ax

/-- **真进展定理**：在 gap 分支下，新世界里存在一个旧世界承载不了的见证。 -/
theorem gap_progress (d : Discovery S D) (_h : ¬ HasSolution S D) :
    ∃ (M : Model T') (e : D.Extra M), D.Axiom M e :=
  ⟨d.candidate.target, d.candidate.extra, d.candidate.ax⟩

/-- **无进展定理**：已解分支不产生新对象 —— 存在一个与旧世界
    **同载体**的 T'-模型。也就是说这一步没换来任何新元素。
    配合 `Score.renaming_kills_objective`，这就是"不许把重命名当发现"。 -/
theorem solved_no_new_world (_d : Discovery S D) (h : HasSolution S D) :
    ∃ (M : Model T'), Nonempty (M.carrier ≃ S.carrier) := by
  rcases h with ⟨s', _hstr, _e, _hax⟩
  exact ⟨⟨S.carrier, s'⟩, ⟨Equiv.refl S.carrier⟩⟩

/-- 极小扩张的唯一性直接继承到 Discovery：
    两次独立的"发现"如果都是极小的，得到的世界典范等价。 -/
noncomputable def worldsEquiv (d₁ d₂ : Discovery S D) :
    d₁.candidate.target.carrier ≃ d₂.candidate.target.carrier :=
  IsMinimal.carrierEquiv d₁.minimal d₂.minimal

end Discovery

/-- 引擎的一步。

    四个输入中，`v` / `E` / `hmin` 就是 design.md 的四个困难函数；
    `snap` 是评分。v0.1 让它们由实例层显式供给。 -/
def step (S : Model T) (D : Demand T T')
    (v : Verdict S D) (E : Extension S D) (hmin : IsMinimal S D E)
    (snap : Snapshot) : Discovery S D :=
  ⟨v, E, hmin, snap⟩

/-- 引擎的分派：按判定分支走不同的路。

    * solved → 世界不变，新颖性必须为 0（否则就是自欺）
    * dead   → 世界不变，并且**记录这个需求是坏的**
    * gap    → 换到候选扩张

    v0.1 里"换世界"就是把 `S` 换成 `forget candidate.target`。 -/
inductive StepResult (S : Model T) (D : Demand T T') where
  | unchanged : Verdict S D → StepResult S D
  | extended (E : Extension S D) : IsMinimal S D E → StepResult S D

/-- 分派的实现。 -/
noncomputable def dispatch (S : Model T) (D : Demand T T')
    (v : Verdict S D) (E : Extension S D) (hmin : IsMinimal S D E) : StepResult S D :=
  match v with
  | Verdict.solved _ => StepResult.unchanged v
  | Verdict.dead _ => StepResult.unchanged v
  | Verdict.gap _ _ => StepResult.extended E hmin

/-- **安全性定理**：引擎永远不会把一个"死需求"当成缺口扩张出去。
    这防止了 NODS 去追逐自相矛盾的目标（例如"非平凡环里 0 = 1"）。 -/
theorem dispatch_safe_dead (v : Verdict S D) (E : Extension S D) (hmin : IsMinimal S D E)
    (hdead : IsDead S D) : ∃ h, dispatch S D v E hmin = StepResult.unchanged h := by
  cases v with
  | solved hs => exact ⟨Verdict.solved hs, rfl⟩
  | dead hd => exact ⟨Verdict.dead hd, rfl⟩
  | gap hn hw => exact False.elim (hdead.false hw)

/-- 缺口分支下一定真的扩张了。 -/
theorem dispatch_gap_extends (hn : ¬ HasSolution S D) (E : Extension S D)
    (hmin : IsMinimal S D E) :
    ∃ h, dispatch S D (Verdict.gap hn E) E hmin = StepResult.extended E h := by
  exact ⟨hmin, rfl⟩

/-- **主循环的类型障碍**（这一点很重要，值得单独说）：

    每扩张一次，世界所在的**理论**就变了（CS → CR → FL → LOF → CR）。
    所以"世界"的类型本身随步数变化，`step` 不可能写成
    普通的 `State → State` 递归。

    这不是实现上的偷懒，而是算法的本质：
    **新数学对象的诞生，就是背景范畴的更换。**

    v0.1 用一个 sigma 类型把"理论 + 模型"打包，把障碍显式化；
    真正的自动主循环（配 design.md §11 的约束生成器）属于 v0.2。 -/
abbrev AnyWorld := Σ (T : Theory), Model T

/-- 打包一个世界。 -/
def packWorld (M : Model T) : AnyWorld := ⟨T, M⟩

/-- 一轮发现后，新世界 = 把候选扩张的目标忘却回当前理论。 -/
def newWorld (E : Extension S D) : Model T := Model.forget T T' E.target

omit [Biframed T T'] in
/-- **单调性**：新世界永远包含旧世界（`emb` 是单射）。
    这保证 NODS 不会在扩张中"丢掉"已发现的对象。 -/
theorem newWorld_contains_old (E : Extension S D) :
    ∃ f : S.carrier → (newWorld E).carrier, Function.Injective f :=
  ⟨Framework.toFun E.emb, E.emb_inj⟩

end NODS
