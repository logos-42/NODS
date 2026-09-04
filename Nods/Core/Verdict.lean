/-
【核心层 3】失败判定 · 失败空间

这是 NODS 的"Closure Failure Detector"的形式化骨架。

关键设计：判定不是二分的，**是三分的**。

    solved —— 当前世界（在同一载体上）已经能承载这个需求 → 不产生新对象
    dead   —— 连一个扩张都没有 → 这个**需求本身是坏的**，不是世界不够
    gap    —— 当前世界承载不了，但确有扩张 → 这才是"结构性缺口"

第三类 `dead` 常被忽略，但它其实很重要：它意味着
"不可解"有两种，一种是缺对象，一种是需求自相矛盾
（例如"在一个非平凡环里要求 0 = 1"，或"要求指数函数处处全纯且有界"）。
把这两种混为一谈，是"新符号制造机"最容易犯的错。
-/

import Nods.Core.Demand

namespace NODS

variable {T T' : Theory} [Framework T] [Framework T'] [Refinement T T'] [Biframed T T']
variable {S : Model T} {D : Demand T T'}

/-- 当前世界是否已经能承载该需求：在**同一个载体**上找一个 T' 结构。
    （"同一个载体"是刻意的：换载体就不叫"已解"，而叫"需要扩张"。） -/
def HasSolution (S : Model T) (D : Demand T T') : Prop :=
  ∃ (s' : T' S.carrier),
    Refinement.forgetStr (T := T) (T' := T') s' = S.str ∧
    ∃ e : D.Extra ⟨S.carrier, s'⟩, D.Axiom ⟨S.carrier, s'⟩ e

/-- 连一个扩张都没有：需求与世界不相容（需求是坏的）。 -/
def IsDead (S : Model T) (D : Demand T T') : Prop := IsEmpty (Extension S D)

/-- 三分类判定。 -/
inductive Verdict (S : Model T) (D : Demand T T') where
  /-- 已解：不需要新对象。 -/
  | solved : HasSolution S D → Verdict S D
  /-- 死的：需求自相矛盾，扩张不存在。 -/
  | dead : IsDead S D → Verdict S D
  /-- 缺口：当前世界承载不了，但确有扩张（`Extension` 就是见证）。 -/
  | gap : ¬ HasSolution S D → Extension S D → Verdict S D

namespace Verdict

/-- dead 与 gap 互斥：若一个扩张都没有，就交不出 gap 所需的见证扩张。
    这条定理是引擎"不追逐死需求"的根据。 -/
theorem dead_not_gap (hd : IsDead S D) (E : Extension S D) : False := hd.false E

/-- solved 与 gap 互斥。 -/
theorem solved_not_gap (hs : HasSolution S D) (hg : ¬ HasSolution S D) : False := hg hs

end Verdict

/-- 一条失败记录：需求 + "这里解不了"的证明 + 一个见证扩张。 -/
structure Failure (S : Model T) (D : Demand T T') where
  notHere : ¬ HasSolution S D
  witness : Extension S D

/-- **失败空间** F：所有"结构性缺口"的集合（design.md §6）。

    注意 v0.1 不负责"生成"这些需求 —— 自动约束生成器是 design.md §11
    的内容，属于 v0.2。v0.1 只把失败空间做成一个**类型**，
    由外部（人或生成器）往里填；引擎负责把填进来的东西
    判定、极小化、打分。 -/
abbrev FailureSpace (S : Model T) (T' : Theory)
    [Framework T'] [Refinement T T'] [Biframed T T'] :=
  Σ D : Demand T T', Failure S D

/-- 从判定里取出失败记录（只对 gap 分支有意义）。 -/
def Failure.ofGap {S : Model T} {D : Demand T T'}
    (h : ¬ HasSolution S D) (E : Extension S D) : Failure S D :=
  ⟨h, E⟩

/-- 一个具体的、可复用的"闭包失败"清单。
    对应 design.md §6 的 Failure Space 文本：
    subtraction / division / root / factorization / symmetry /
    limit / differentiation / integration / topological completion

    v0.1 只把前四项做成了机器证明（见 Instances/*）。
    后几项需要分析学，是 v0.2 的目标。 -/
inductive ClosureFailureKind where
  | subtraction     -- N : x + 1 = 0 无解
  | division        -- Z : 2x = 1 无解
  | root            -- Q : x² = 2 无解 / R : x² = -1 无解
  | limit           -- Q : {q | q² < 2} 无上确界
  | factorization
  | symmetry
  | differentiation
  | integration
  | topologicalCompletion
deriving DecidableEq, Repr

end NODS
