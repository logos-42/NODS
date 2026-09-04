/-
【串联】N → Z → Q → R → C 的完整轨迹

一个必须说清楚的结构性问题：

  **NODS 的主循环在类型层面是依赖类型的。**

每一步之后，世界所在的**理论**变了：
    CS → CR → FL → LOF → CR
所以"世界"的类型本身随步数变化，`step` 不可能写成普通的
`State → State` 递归。这是这个算法的本质特征，不是实现上的偷懒：
**新数学对象的诞生，就是背景范畴的更换。**

v0.1 的处理：用一个 sigma 类型 `AnyWorld` 把"理论 + 模型"打包，
于是循环的类型障碍被显式化而不是被掩盖。
真正的自动主循环（配 design.md §11 的约束生成器）属于 v0.2。
-/

import Mathlib
import Nods.Core.Engine
import Nods.Instances.RealToComplex

namespace NODS

/- ------------------------------------------------------------------ -/
/- 打包世界                                                            -/
/- ------------------------------------------------------------------ -/

/-- 擦掉理论的世界。用于把主循环写成普通递归。 -/
abbrev AnyWorld := Σ (T : Theory), Model T

/-- 打包。 -/
def packWorld (M : Model T) : AnyWorld := ⟨T, M⟩

/-- 报告：擦掉类型信息后的可打印轨迹。 -/
structure StepReport where
  fromWorld : String
  failedConstraint : String
  kind : ClosureFailureKind
  minimalExtension : String
  newObject : String
  canonicalization : String
  extendedStructure : String
  newAxiomCount : Nat
  score : Score
  snapshot : Snapshot
  objectiveText : String

/- ------------------------------------------------------------------ -/
/- 四个步骤                                                            -/
/- ------------------------------------------------------------------ -/

/-- 第 1 步：N → Z（减法闭包失败） -/
def stepNatToInt : StepReport :=
  { fromWorld := "N  (CommSemiring)"
    failedConstraint := "x + 1 = 0"
    kind := ClosureFailureKind.subtraction
    minimalExtension := "introduce α with α + 1 = 0, inside CommRing"
    newObject := "α"
    canonicalization := "α ≡ -1"
    extendedStructure := "Z  (CommRing)"
    newAxiomCount := 1
    score := { coverage := 1, relationDensity := 0.8, closureGain := 1,
               minimality := 1, novelty := 1 }
    snapshot := { novelty := 1, consistency := 1, generativity := 0.86,
                  compression := compressionOf 1 }
    objectiveText := "0.43" }

/-- 第 2 步：Z → Q（除法闭包失败） -/
def stepIntToRat : StepReport :=
  { fromWorld := "Z  (CommRing)"
    failedConstraint := "2 * x = 1"
    kind := ClosureFailureKind.division
    minimalExtension := "theory refinement CommRing → Field"
    newObject := "1/2, 1/3, ... (all of Q)"
    canonicalization := "Z[all inverses] ≅ Q"
    extendedStructure := "Q  (Field)"
    newAxiomCount := 1
    score := { coverage := 1, relationDensity := 0.75, closureGain := 1,
               minimality := 1, novelty := 1 }
    snapshot := { novelty := 1, consistency := 1, generativity := 0.84,
                  compression := compressionOf 1 }
    objectiveText := "0.42" }

/-- 第 3 步：Q → R（极限闭包失败） -/
def stepRatToReal : StepReport :=
  { fromWorld := "Q  (Field)"
    failedConstraint := "sup { q : Q | q² < 2 }"
    kind := ClosureFailureKind.limit
    minimalExtension := "theory refinement Field → LinearOrderedField + DedekindComplete"
    newObject := "√2 及其所有切割"
    canonicalization := "Dedekind completion of Q ≅ R"
    extendedStructure := "R  (LinearOrderedField)"
    newAxiomCount := 3
    score := { coverage := 1, relationDensity := 0.9, closureGain := 1,
               minimality := 0.8, novelty := 1 }
    snapshot := { novelty := 1, consistency := 1, generativity := 0.95,
                  compression := compressionOf 3 }
    objectiveText := "0.238" }

/-- 第 4 步：R → C（代数闭包失败，添常元） -/
def stepRealToComplex : StepReport :=
  { fromWorld := "R  (CommRing)"
    failedConstraint := "x² = -1"
    kind := ClosureFailureKind.root
    minimalExtension := "adjoin a constant j with j² = -1"
    newObject := "j"
    canonicalization := "j ≡ i,  R(j) ≅ C"
    extendedStructure := "C  (CommRing)"
    newAxiomCount := 1
    score := { coverage := 1, relationDensity := 0.95, closureGain := 1,
               minimality := 1, novelty := 1 }
    snapshot := { novelty := 1, consistency := 1, generativity := 0.97,
                  compression := compressionOf 1 }
    objectiveText := "0.485" }

/-- 完整轨迹。 -/
def trace : List StepReport :=
  [stepNatToInt, stepIntToRat, stepRatToReal, stepRealToComplex]

/- ------------------------------------------------------------------ -/
/- 从形式化对象里取回可打印事实                                        -/
/- ------------------------------------------------------------------ -/

/-- 四个世界（打包后就可以放进同一个列表里了）。 -/
def worlds : List AnyWorld :=
  [ packWorld (T := CS) natModel
  , packWorld (T := CR) intModel
  , packWorld (T := FL) ratModel
  , packWorld (T := LOF) realModel
  , packWorld (T := CR) complexModel ]

/-- 四个失败检测的结论。 -/
theorem all_gaps :
    (¬ HasSolution natModel demandRing) ∧
    (¬ HasSolution intModel demandField) ∧
    (¬ HasSolution ratModel demandComplete) ∧
    (¬ HasSolution realModelCR demandSqrtNegOne) :=
  ⟨nat_gap, int_gap, rat_gap, real_gap⟩

/-- 三个真正被证明的极小性（Q→R 是未决义务 O1，见 RatToReal）。 -/
theorem proven_minimality :
    IsMinimal natModel demandRing natToInt ∧
    IsMinimal intModel demandField intToRat ∧
    IsMinimal realModelCR demandSqrtNegOne realToComplex :=
  ⟨natToInt_minimal, intToRat_minimal, realToComplex_minimal⟩

end NODS
