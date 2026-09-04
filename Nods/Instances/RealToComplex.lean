/-
【实例 4】R → C ：代数闭包失败（添常元）

这是整条链上**唯一一步真正的"添元素"**：

    N→Z、Z→Q 是换范畴（理论强化）
    Q→R   是换范畴 + 一条不具泛性质的性质（完备化）
    R→C   是理论不变（仍是 CommRing），只在语言里**添一个常元 j**
           并规定 j² = -1

正因为 j 是语言里的常元（能被同态前向搬运），
这一步才有真正的**泛性质**：(C, i) 是
"交换环 A + 嵌入 e : R → A + 满足 j² = -1 的元素 j"这个范畴的初始对象。

一个必须注意的细节：**点化**是本质的。
如果不把 j 作为结构的一部分固定住，(C, i) 就不是初始的 ——
恒等和共轭都是从 C 到 C 的、在 R 上一致的环同态，
两者都"保住了"根的存在，但把 i 送到了不同的地方。
只有把 j 当成结构，唯一性才成立。

这也解释了为什么 NODS 的 `Extension` 必须带 `extra` 字段：
**"找到一个解" ≠ "钉住那个解"**。前者不够产生新数学对象。
-/

import Mathlib
import Nods.Core.Engine
import Nods.Theories.Algebraic
import Nods.Instances.RatToReal

namespace NODS

abbrev realModelCR : Model CR := Model.ofType ℝ (inferInstance : CommRing ℝ)
abbrev complexModel : Model CR := Model.ofType ℂ (inferInstance : CommRing ℂ)

/- ------------------------------------------------------------------ -/
/- 需求：添一个 j 使 j² = -1                                           -/
/- ------------------------------------------------------------------ -/

/-- 在交换环语言里添一个常元 j，并要求 j² = -1。 -/
def demandSqrtNegOne : Demand CR CR where
  Extra := fun M => M.carrier
  Axiom := fun M j =>
    letI : CommRing M.carrier := M.str
    j * j = -1
  mapExtra := fun {M N} f j => Framework.toFun f j
  mapExtra_id := by intros; simp
  mapExtra_comp := by intros; simp

/- ------------------------------------------------------------------ -/
/- 失败检测                                                            -/
/- ------------------------------------------------------------------ -/

/-- R 中 `x² = -1` 无解。 -/
theorem real_no_sqrt_neg_one : ¬ ∃ x : ℝ, x * x = -1 := by
  rintro ⟨x, hx⟩
  nlinarith [sq_nonneg x]

/-- 判定：R 承载不了这个常元 —— gap。 -/
theorem real_gap : ¬ HasSolution realModelCR demandSqrtNegOne := by
  rintro ⟨s', hstr, j, hj⟩
  change s' = realModelCR.str at hstr
  subst s'
  exact real_no_sqrt_neg_one ⟨j, hj⟩

/- ------------------------------------------------------------------ -/
/- 泛构造：R[X]/(X²+1) 的显式实现                                      -/
/- ------------------------------------------------------------------ -/

/-- 显式构造泛同态：把 `a + b·i` 送到 `e a + e b · j`。
    这就是"R[X]/(X²+1) → A"的初等写法。 -/
noncomputable def complexLift {A : Type} [CommRing A]
    (e : ℝ →+* A) (j : A) (hj : j * j = -1) : ℂ →+* A where
  toFun := fun z => e z.re + e z.im * j
  map_zero' := by simp
  map_one' := by simp
  map_add' := by
    intro z w
    simp only [Complex.add_re, Complex.add_im, map_add]
    ring
  map_mul' := by
    intro z w
    simp only [Complex.mul_re, Complex.mul_im, map_add, map_mul, map_sub, map_neg]
    ring_nf
    rw [show j ^ 2 = -1 from by simpa [pow_two] using hj]
    ring

/-- 泛同态确实把 i 送到 j。 -/
theorem complexLift_I {A : Type} [CommRing A]
    (e : ℝ →+* A) (j : A) (hj : j * j = -1) :
    complexLift e j hj Complex.I = j := by
  simp [complexLift]

/-- 泛同态与 e 在 R 上一致。 -/
theorem complexLift_ofReal {A : Type} [CommRing A]
    (e : ℝ →+* A) (j : A) (hj : j * j = -1) (r : ℝ) :
    complexLift e j hj (r : ℂ) = e r := by
  simp [complexLift]

/-- **唯一性**：任何满足这两个条件的同态就是 `complexLift`。 -/
theorem complexLift_unique {A : Type} [CommRing A]
    (e : ℝ →+* A) (j : A) (hj : j * j = -1)
    (f : ℂ →+* A) (he : ∀ r : ℝ, f (r : ℂ) = e r) (hI : f Complex.I = j) :
    f = complexLift e j hj := by
  apply RingHom.ext
  intro z
  calc
    f z = f ((z.re : ℂ) + (z.im : ℂ) * Complex.I) := by
      rw [Complex.re_add_im]
    _ = f (z.re : ℂ) + f (z.im : ℂ) * f Complex.I := by
      rw [map_add, map_mul]
    _ = e z.re + e z.im * j := by
      rw [he z.re, he z.im, hI]

/- ------------------------------------------------------------------ -/
/- 扩张与极小性                                                        -/
/- ------------------------------------------------------------------ -/

/-- C 作为 R 的扩张，点化在 `i` 上。 -/
noncomputable def realToComplex : Extension realModelCR demandSqrtNegOne where
  target := complexModel
  emb := by
    letI : NonAssocSemiring realModelCR.carrier :=
      SemiringLike.toNonAssocSemiring (T := CR) realModelCR.str
    letI : NonAssocSemiring complexModel.carrier :=
      SemiringLike.toNonAssocSemiring (T := CR) complexModel.str
    exact Complex.ofRealHom
  emb_inj := by
    intro a b h
    exact Complex.ofReal_injective h
  extra := Complex.I
  ax := Complex.I_mul_I

/-- **(C, i) 是极小扩张**：在"交换环 + 嵌入 R + 点化根"范畴里是初始对象。

    存在性：`complexLift`。
    唯一性：`complexLift_unique` + `ExtHom.ext`。

    这里能证明唯一性，而 Q→R 不能，根本原因见本文件开头的讨论：
    `j² = -1` 是**等式公理**，`Dedekind 完备`不是。
    这条对比是 NODS 分类器最重要的一课。 -/
noncomputable def realToComplex_minimal :
    IsMinimal realModelCR demandSqrtNegOne realToComplex := by
  intro F
  letI : CommRing F.target.carrier := F.target.str
  letI : NonAssocSemiring realModelCR.carrier :=
    SemiringLike.toNonAssocSemiring (T := CR) realModelCR.str
  letI : NonAssocSemiring complexModel.carrier :=
    SemiringLike.toNonAssocSemiring (T := CR) complexModel.str
  letI : NonAssocSemiring F.target.carrier :=
    SemiringLike.toNonAssocSemiring (T := CR) F.target.str
  letI : CommRing (Model.forget CR CR F.target).carrier := F.target.str
  letI : NonAssocSemiring (Model.forget CR CR F.target).carrier :=
    SemiringLike.toNonAssocSemiring (T := CR) (Model.forget CR CR F.target).str
  constructor
  · refine ⟨{ hom := complexLift F.emb F.extra F.ax,
               over := ?_,
               pres := ?_ }⟩
    · intro r
      simp only [Biframed.forget_toFun]
      simpa using complexLift_ofReal F.emb F.extra F.ax r
    · exact complexLift_I F.emb F.extra F.ax
  · intro f g
    apply ExtHom.ext
    intro z
    have hf : f.hom = complexLift F.emb F.extra F.ax := by
      apply complexLift_unique
      · intro r
        have := f.over r
        simpa [Biframed.forget_toFun] using this
      · exact f.pres
    have hg : g.hom = complexLift F.emb F.extra F.ax := by
      apply complexLift_unique
      · intro r
        have := g.over r
        simpa [Biframed.forget_toFun] using this
      · exact g.pres
    rw [hf, hg]

/-- **刚性推论**：(C, i) 的自同构群平凡。
    对比：不点化时 C 有共轭这个非平凡自同构。
    这说明"钉住见证"这件事本身改变了对象的对称性。 -/
theorem complex_rigid (f : ExtHom realModelCR demandSqrtNegOne
    realToComplex realToComplex) : f = ExtHom.id realToComplex :=
  IsMinimal.rigid realToComplex_minimal f

end NODS
