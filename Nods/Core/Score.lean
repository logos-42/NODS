/-
【核心层 5】生成力评分 · 目标函数 · 新颖性

design.md 里给了两个评分：
    §5  G = w₁U + w₂R + w₃C + w₄M + w₅N   （加权和）
    §末 Novelty × Consistency × Generativity × Compression （乘积）

这两个**不矛盾，但用途不同**，v0.1 把它们都保留并说清楚：

  * 加权和 `generativity` 用来**排序**候选：它回答"这个对象有多大用"。
  * 乘积 `objective` 用来**闸门**：它回答"这个对象值不值得被叫做发现"。

区别是决定性的：加权和允许"新颖性 0 但其他分很高"的候选混进来
（一个重命名 √7 的"新数"可以拿到很高的 U/R/C/M）。
乘积不行 —— **任何一项为 0，总分就是 0**。

这就是 `objective_eq_zero_of_*` 那几条定理的意义：
它们是"防新符号污染"的形式化闸门。
-/

import Mathlib
import Nods.Core.Demand

namespace NODS

/-- 生成力评分的五分量（design.md §5），取值约定在 [0,1]。 -/
structure Score where
  /-- U：Unsolved Coverage —— 让多少原本不可解的问题变得可解。 -/
  coverage : ℝ
  /-- R：Relation Density —— 与已有对象产生多少非平凡关系。 -/
  relationDensity : ℝ
  /-- C：Closure Gain —— 一次解决掉多少个 closure failure。 -/
  closureGain : ℝ
  /-- M：Minimality —— 是不是最小必要扩张。 -/
  minimality : ℝ
  /-- N：Novelty —— 是不是已有对象的重命名。 -/
  novelty : ℝ

namespace Score

/-- 五个分量都落在单位区间内。 -/
def InUnit (s : Score) : Prop :=
  s.coverage ∈ Set.Icc (0 : ℝ) 1 ∧
  s.relationDensity ∈ Set.Icc (0 : ℝ) 1 ∧
  s.closureGain ∈ Set.Icc (0 : ℝ) 1 ∧
  s.minimality ∈ Set.Icc (0 : ℝ) 1 ∧
  s.novelty ∈ Set.Icc (0 : ℝ) 1

/-- 生成力（等权平均；v0.1 不做权重学习）。 -/
def generativity (s : Score) : ℝ :=
  (s.coverage + s.relationDensity + s.closureGain + s.minimality + s.novelty) / 5

theorem generativity_nonneg (s : Score) (hs : s.InUnit) : 0 ≤ s.generativity := by
  rcases hs with ⟨hc, hr, hg, hm, hn⟩
  dsimp [generativity]
  nlinarith [hc.1, hr.1, hg.1, hm.1, hn.1]

theorem generativity_le_one (s : Score) (hs : s.InUnit) : s.generativity ≤ 1 := by
  rcases hs with ⟨hc, hr, hg, hm, hn⟩
  dsimp [generativity]
  nlinarith [hc.2, hr.2, hg.2, hm.2, hn.2]

end Score

/-- 目标函数四分量（design.md 末尾）。 -/
structure Snapshot where
  /-- Novelty：不是已有对象的重命名。 -/
  novelty : ℝ
  /-- Consistency：扩张与已有理论不矛盾。 -/
  consistency : ℝ
  /-- Generativity：引入它之后是否长出一整片新结构。 -/
  generativity : ℝ
  /-- Compression：解释很多现象所需的新公理有多少（越少越高）。 -/
  compression : ℝ

namespace Snapshot

/-- **乘积**目标函数。任何一项为 0，总分为 0。 -/
def objective (x : Snapshot) : ℝ :=
  x.novelty * x.consistency * x.generativity * x.compression

theorem objective_eq_zero_of_novelty_zero (x : Snapshot) (h : x.novelty = 0) :
    x.objective = 0 := by
  simp [objective, h]

theorem objective_eq_zero_of_inconsistent (x : Snapshot) (h : x.consistency = 0) :
    x.objective = 0 := by
  simp [objective, h]

theorem objective_eq_zero_of_no_generativity (x : Snapshot) (h : x.generativity = 0) :
    x.objective = 0 := by
  simp [objective, h]

theorem objective_eq_zero_of_no_compression (x : Snapshot) (h : x.compression = 0) :
    x.objective = 0 := by
  simp [objective, h]

theorem objective_nonneg (x : Snapshot)
    (hn : 0 ≤ x.novelty) (hc : 0 ≤ x.consistency)
    (hg : 0 ≤ x.generativity) (hp : 0 ≤ x.compression) :
    0 ≤ x.objective := by
  dsimp [objective]
  positivity

theorem objective_le_one (x : Snapshot)
    (hn : x.novelty ∈ Set.Icc (0 : ℝ) 1) (hc : x.consistency ∈ Set.Icc (0 : ℝ) 1)
    (hg : x.generativity ∈ Set.Icc (0 : ℝ) 1) (hp : x.compression ∈ Set.Icc (0 : ℝ) 1) :
    x.objective ≤ 1 := by
  dsimp [objective]
  have h1 : x.novelty * x.consistency ≤ 1 := by
    calc
      x.novelty * x.consistency ≤ (1 : ℝ) * 1 := mul_le_mul hn.2 hc.2 hc.1 (by norm_num)
      _ = 1 := by norm_num
  have h2 : x.novelty * x.consistency * x.generativity ≤ 1 := by
    calc
      x.novelty * x.consistency * x.generativity ≤ (1 : ℝ) * 1 :=
        mul_le_mul h1 hg.2 hg.1 (by norm_num)
      _ = 1 := by norm_num
  calc
    x.novelty * x.consistency * x.generativity * x.compression ≤ (1 : ℝ) * 1 :=
      mul_le_mul h2 hp.2 hp.1 (by norm_num)
    _ = 1 := by norm_num

end Snapshot

/-- 压缩率：用 d 条新公理解释旧现象时的压缩分。
    d = 0 时压缩率为 1（没有新公理 —— 那就不是发现了）。 -/
def compressionOf (d : ℕ) : ℝ := (1 : ℝ) / (d + 1)

/-- 已知数学库：一组已经存在的模型。

    **关键认识**：新颖性不是系统内部的性质，它是相对于
    "人类已经知道什么"的。所以 NODS 必须把库当作**输入**。
    不把库形式化，"Novelty" 这一项就无处安放。 -/
structure Library (T' : Theory) where
  Index : Type
  get : Index → Model T'

/-- 与库中某个已知模型载体等价 → 只是重命名。
    （v0.1 用载体等价近似同构；v0.2 应换成真正的 T'-同构。） -/
def IsRenamingOf (L : Library T') (M : Model T') : Prop :=
  ∃ i : L.Index, Nonempty (M.carrier ≃ (L.get i).carrier)

/-- 相对新颖性：重命名 = 0，否则 = 1。 -/
noncomputable def noveltyAgainst [Framework T'] (L : Library T') (M : Model T') : ℝ :=
  if IsRenamingOf L M then 0 else 1

/-- **闸门定理**：一个候选如果只是在给已知对象改名，
    那么无论它的 U / R / C / M 有多高，目标函数都是 0。

    这条定理是 design.md 最后那段话的形式化：
    "一个优秀的新数学对象，应该用很少的新公理/新定义，解释很多原来分散的现象。"
    而"新"本身不是目标，"新且压缩"才是。 -/
theorem renaming_kills_objective [Framework T'] (L : Library T') (M : Model T')
    (x : Snapshot) (h : IsRenamingOf L M)
    (hx : x.novelty = noveltyAgainst L M) :
    x.objective = 0 := by
  have hv : noveltyAgainst L M = 0 := by
    simp [noveltyAgainst, h]
  exact Snapshot.objective_eq_zero_of_novelty_zero x (by simpa [hx] using hv)

end NODS
