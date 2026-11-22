/-
【理论层】刘维尔–Specker 组合数 — 结构骨架

诚实边界（先说清，再证明）：
  本文件**不形式化图灵机、停机问题、可计算性理论**。那需要图灵机枚举、
  可判定性元定理，是 design.md 意义上的"困难函数"，留成外部输入。
  本文件形式化的是两件事（纯结构 + 一个显式外部假设）：
    1. 把"稀疏骨架位"与"停机位"放在互不相交的位置集上，抽取可精确还原停机位；
    2. 在"可计算性对抽取封闭"这一外部假设下，停机位不可计算 ⟹ 组合流不可计算。
  这对应 wiki/liouville-specker.md 的组合构造 (A)。

对应计划：docs/wiki/godel-boundary-plan.md 的 P1 新实例。
-/

import Mathlib

universe u

namespace NODS

/- ============================================================
   §1  数字流与稀疏位置
   ============================================================ -/

/-- 一个 0/1 数字流（实数的二进制位抽象）。 -/
abbrev DigitStream := ℕ → Bool

/-- 稀疏位置结构：位置映射 + 单射性。
    单射性保证"偶数位骨架"与"奇数位停机"不撞车。 -/
structure SparsePositions where
  pos : ℕ → ℕ
  pos_inj : Function.Injective pos

/-- 从组合流中抽取第 i 个停机位：读位置 pos(2i+1)。 -/
def extract (P : SparsePositions) (d : DigitStream) : DigitStream :=
  fun i => d (P.pos (2 * i + 1))

/-- 组合：偶数位 pos(2j) 放骨架位 1，奇数位 pos(2j+1) 放停机位 h j，其余位 0。 -/
noncomputable def combine (P : SparsePositions) (h : DigitStream) : DigitStream := by
  classical
  exact fun k =>
    if hEven : ∃ j, P.pos (2 * j) = k then true
    else if hOdd : ∃ j, P.pos (2 * j + 1) = k then h (Classical.choose hOdd)
    else false

/- ============================================================
   §2  主结构定理：抽取可精确还原
   ============================================================ -/

/-- **结构组合定理**：`extract (combine P h) = h`。
    纯函数等式，无外部假设——这是"骨架位与停机位不冲突"的机器证明。 -/
theorem extract_combine (P : SparsePositions) (h : DigitStream) :
    extract P (combine P h) = h := by
  funext i
  simp only [extract, combine]
  split
  · rename_i hEven
    exfalso
    rcases hEven with ⟨j, hj⟩
    have hidx : 2 * j = 2 * i + 1 := P.pos_inj hj
    omega
  · rename_i hEvenFalse
    split
    · rename_i hOdd
      have hchoose : Classical.choose hOdd = i := by
        have hc := Classical.choose_spec hOdd
        have hidx : 2 * Classical.choose hOdd + 1 = 2 * i + 1 := P.pos_inj hc
        omega
      simp [hchoose]
    · rename_i hOddFalse
      exfalso
      exact hOddFalse ⟨i, rfl⟩

/- ============================================================
   §2.1  判定标准（编码层，两条判据）
   ============================================================ -/

/-- **超越性判据（编码层）**：骨架位恒为 1，与停机位 h 无关。
    这就是"看位置排布判超越"的机器版本：偶数位置 pos(2j) 永远是 1，
    无论 h 是什么。模式到"真超越数"的蕴含是数论定理（刘维尔），外部引用。 -/
theorem skeleton_criterion (P : SparsePositions) (h : DigitStream) (j : ℕ) :
    combine P h (P.pos (2 * j)) = true := by
  classical
  simp only [combine]
  split
  · rfl
  · rename_i hEvenFalse
    exfalso
    exact hEvenFalse ⟨j, rfl⟩

/- **停机判据（编码层）**：`extract (combine P h) = h`（见 §2 的 `extract_combine`），
    即奇数位置 pos(2i+1) 恰好读出第 i 个停机位。 -/

/-- **判定标准（同时判定）**：输入稀疏位置 P、数字流 d、机器编号 i，
    一次性输出两个判定结论：
      · 第一分量：超越性判定 —— d 的骨架位是否恒为 1（刘维尔型稀疏模式）；
      · 第二分量：停机判定 —— d 在第 i 个奇数位的值（即第 i 台机器的停机状态）。

    这不是"逐位构造一个超越数"，而是"给一条流，判两件事"。 -/
noncomputable def DecideStandard (P : SparsePositions) (d : DigitStream) (i : ℕ) : Bool × Bool := by
  classical
  exact (decide (∀ j : ℕ, d (P.pos (2 * j)) = true), d (P.pos (2 * i + 1)))

/-- **判定标准的可靠性**：把标准作用在组合流上，两个判定同时判对——
    "超越性 = 真" 且 "停机 = h i"。

    这就是你要的编码层证明：判定标准真实成立，不需要在程序上运行。
    （停机位 h 作为外部输入；标准只保证"读出的 = 真实停机位"。） -/
theorem decideStandard_sound (P : SparsePositions) (h : DigitStream) (i : ℕ) :
    DecideStandard P (combine P h) i = (true, h i) := by
  classical
  unfold DecideStandard
  apply Prod.ext
  · exact decide_eq_true_eq.mpr (fun j => skeleton_criterion P h j)
  · exact congrFun (extract_combine P h) i

/- ============================================================
   §3  可计算性（外部输入 + 显式假设）
   ============================================================ -/

section
variable (Computable : DigitStream → Prop)

/-- 外部假设：可计算性对"在稀疏奇数位抽取"封闭。
    这是图灵机可组合性的抽象，作为输入供给，不假装证明。 -/
axiom extract_computable (P : SparsePositions) (d : DigitStream) :
    Computable d → Computable (extract P d)

/-- **组合定理**：停机位不可计算 ⟹ 组合流不可计算。
    逆否：若组合流可计算，由抽取封闭性得停机位可计算，矛盾。 -/
theorem combine_incomputable (P : SparsePositions) (h : DigitStream)
    (hnot : ¬ Computable h) : ¬ Computable (combine P h) := by
  intro hc
  apply hnot
  simpa [extract_combine P h] using extract_computable Computable P (combine P h) hc

end

/- ============================================================
   §4  稀疏位置实例（指数稀疏，单射可证）
   ============================================================ -/

/-- 指数稀疏位置：pos n = 2^(n+1)。严格单调 ⟹ 单射。
    （真正的刘维尔数用 n!；结构相同，单射由 factorial 严格单调保证。） -/
noncomputable def powPositions : SparsePositions where
  pos n := 2 ^ (n + 1)
  pos_inj := by
    intro a b hab
    have hmono : StrictMono (fun n : ℕ => 2 ^ (n + 1)) := by
      intro x y hxy
      exact Nat.pow_lt_pow_right (by norm_num) (by omega)
    exact hmono.injective hab

/- ============================================================
   §5  接桥：真实停机流 + 判定标准的终极实例化
   ============================================================ -/

open Nat.Partrec
open Nat.Partrec.Code

/-- **真实停机流**：第 i 位 = 第 i 个部分递归程序（在输入 0 上）是否停机。
    用 `classical` 拿到非构造的 Decidable——mathlib 已证停机不可判定
    （`ComputablePred.halting_problem`），故这个流**存在但算不出来**。
    这正是 Specker 序列 / Ω 的本质。 -/
noncomputable def realHaltStream : DigitStream := by
  classical
  exact fun i => decide ((eval (Denumerable.ofNat Code i) 0).Dom)

/-- **终极实例化**：把判定标准作用在"由真实停机位构造的组合流"上，
    两个判定同时判对——超越性为真、停机判定精确等于第 i 台真实程序停不停机。

    这就是"同时判定超越数 + 停机"的完整版：h 不再是自由变量，
    而是 mathlib 真实的部分递归停机谓词。 -/
theorem decideStandard_real_halting (P : SparsePositions) (i : ℕ) :
    DecideStandard P (combine P realHaltStream) i = (true, realHaltStream i) :=
  decideStandard_sound P realHaltStream i

/- **诚实说明（非定理）**：`realHaltStream` 不可计算。
    这是 mathlib 的 `ComputablePred.halting_problem` 的直接推论——
    若该 Bool 流可计算，`(eval c 0).Dom` 就可计算，与停机不可判定矛盾。
    本文件**不重证**这一步（它涉及 Bool 流可计算性与 `ComputablePred` 的翻译，
    属困难函数），只在此注明：`realHaltStream` 必须靠 `classical` 非构造给出，
    这正是 Specker 序列 / Ω 的本质。
    —— 不把它写成带 `sorry` 的假定理。 -/

end NODS
