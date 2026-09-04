/-
【演示】把 NODS v0.1 的轨迹打印出来

输出格式对齐 design.md §10 的要求：

    测试标准不是"它能不能生成这些符号"，
    而是"它能不能解释为什么这个对象必须出现"。

所以每一段的核心不是 New Object，而是 **Failed Constraint + Minimal Extension**。
-/

import Nods.Chain

namespace NODS

/-- 渲染单步。 -/
def renderStep (r : StepReport) : String :=
  "Current Structure:\n    " ++ r.fromWorld ++ "\n\n" ++
  "Failed Constraint:\n    " ++ r.failedConstraint ++ "\n\n" ++
  "Failure Type:\n    " ++ toString (repr r.kind) ++ "\n\n" ++
  "Minimal Extension:\n    " ++ r.minimalExtension ++ "\n\n" ++
  "New Object:\n    " ++ r.newObject ++ "\n\n" ++
  "Canonicalization:\n    " ++ r.canonicalization ++ "\n\n" ++
  "Extended Structure:\n    " ++ r.extendedStructure ++ "\n\n" ++
  "New Axioms:\n    " ++ toString r.newAxiomCount ++ "\n\n" ++
  "Objective (N x C x G x P):\n    " ++ r.objectiveText ++ "\n"

/-- 完整报告。 -/
def report : String :=
  "NODS v0.1 — New Object Discovery System\n" ++
  "=======================================\n\n" ++
  "Calibration run: re-derive N -> Z -> Q -> R -> C\n\n" ++
  (trace.map renderStep |>.foldl (· ++ ·) "")

/-- 打印。 -/
def main : IO Unit := IO.println report

end NODS

#eval NODS.report
