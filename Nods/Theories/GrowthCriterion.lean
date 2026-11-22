/-
【理论层】双增长率判定准则 — 用增长速率判停机（哥德尔翻译 + 有界求值）

诚实边界（先说清，再证明）：
  本文件**不证明停机可计算**。它证明的是：给定一个"增长率"函数 rate
  （每台停机机器在某个步数界内给出结果），编码层的判定准则能精确读出停机。
  这对应搜索到的两条事实：
    · Specker 序列的收敛模数（增长率）编码停机（"no algorithm can certify how close"）；
    · Busy Beaver BB(n) 增长超过所有可计算函数，知道 BB(n) 即可判停机（Radó）。
  rate 本身作为外部输入（困难函数），本文件不构造它。

机制全用 mathlib 现成：
  · Nat.Partrec.Code.evaln : 有界步数、可计算、Option 返回；
  · evaln_mono : 步数单调；evaln_complete : 停机 ⟺ ∃ k, evaln k 出结果。

哥德尔翻译：Denumerable.ofNat Code c 把编号 c 翻译成程序（"词 → 命题"）。
-/

import Mathlib.Computability.Halting

open Denumerable
open Nat.Partrec
open Nat.Partrec.Code

universe u

namespace NODS

/- ============================================================
   §1  两种增长率
   ============================================================ -/

/-- **慢增长率**：可计算的有界步数函数（如 k ↦ 2^k）。对应 evaln 的界。
    这是"超越数骨架"那半边：增长可预测、可计算。 -/
abbrev SlowRate := ℕ → ℕ

/-- **快增长率**：停机模数 —— 对每个程序编号 c，若它停机，则给它一个足够大的
    步数界让 evaln 出结果。这是"停机位"那半边：增长不可预测、不可计算。
    定义成"存在界"而非函数，是诚实做法：不假装能构造这个界。 -/
def IsHaltingModulus (rate : ℕ → ℕ) : Prop :=
  ∀ c : ℕ, (eval (ofNat Code c) 0).Dom →
    ∃ x, x ∈ evaln (rate c) (ofNat Code c) 0

/- ============================================================
   §2  增长判定准则（哥德尔翻译 + 有界求值）
   ============================================================ -/

/-- **增长判定准则**：给定增长率 rate 和程序编号 c，
    用 rate c 作步数界跑 evaln，出结果 ⟺ 判为停机。
    "把词 c 翻译成命题" = Denumerable.ofNat Code c；
    "通过增长判定" = 用 rate c 作 evaln 的界。 -/
def growthCriterion (rate : ℕ → ℕ) (c : ℕ) : Bool :=
  (evaln (rate c) (ofNat Code c) 0).isSome

/-- **准则可靠性（停机 ⟹ 判为停机）**：若 rate 是停机模数，
    则真停机的程序被 growthCriterion 判为 true。 -/
theorem growthCriterion_true_of_halts (rate : ℕ → ℕ) (hm : IsHaltingModulus rate)
    (c : ℕ) (hhalt : (eval (ofNat Code c) 0).Dom) :
    growthCriterion rate c = true := by
  obtain ⟨x, hx⟩ := hm c hhalt
  exact Option.isSome_iff_exists.mpr ⟨x, hx⟩

/-- **准则可靠性（判为停机 ⟹ 真停机）**：evaln 出结果 ⟹ eval 有定义（evaln_sound）。
    这一半不依赖 rate 是模数，是纯可靠性。 -/
theorem growthCriterion_halts_of_true (rate : ℕ → ℕ) (c : ℕ)
    (htrue : growthCriterion rate c = true) :
    (eval (ofNat Code c) 0).Dom := by
  have hsome : ∃ x, x ∈ evaln (rate c) (ofNat Code c) 0 :=
    Option.isSome_iff_exists.mp htrue
  rcases hsome with ⟨x, hx⟩
  exact Part.dom_iff_mem.mpr ⟨x, evaln_sound hx⟩

/-- **增长判定准则的完整可靠性**：rate 是停机模数 ⟹
    准则精确判定停机（两方向都成立）。 -/
theorem growthCriterion_correct (rate : ℕ → ℕ) (hm : IsHaltingModulus rate) (c : ℕ) :
    growthCriterion rate c = true ↔ (eval (ofNat Code c) 0).Dom :=
  ⟨growthCriterion_halts_of_true rate c, growthCriterion_true_of_halts rate hm c⟩

/- ============================================================
   §3  与判定标准的接口：快增长率从何而来的诚实说明
   ============================================================ -/

/-- 慢增长率实例：2^c，可计算、随编号指数增长。对应"超越数骨架"的稀疏位置。 -/
def slowRate : SlowRate := fun c => 2 ^ (c + 1)

/- **诚实说明（非定理）**：不存在可计算的停机模数。
    这是 mathlib `ComputablePred.halting_problem` 的推论：
    若 rate 可计算且是模数，则由 growthCriterion_correct 可计算地判定停机，矛盾。
    本文件不把这条写成带 sorry 的定理；它作为外部已知事实引用。
    这正是"快增长率"必须不可计算的原因——也就是 Specker/BB 那半边。 -/

end NODS
