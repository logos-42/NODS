import Mathlib

example (α : Type) (s : CommSemiring α) : NonAssocSemiring α := by
  letI : CommSemiring α := s
  inferInstance

example (α : Type) (s : CommRing α) : CommSemiring α := by
  letI : CommRing α := s
  inferInstance

example (α : Type) (s : Field α) : CommRing α := s.toCommRing

example (α : Type) (s : LinearOrderedField α) : Field α := s.toField

#check Semiring.toNonAssocSemiring
#check CommSemiring.toSemiring
