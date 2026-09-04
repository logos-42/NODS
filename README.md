<div align="center">

# NODS — New Object Discovery System

**A Lean 4 + Mathlib formalization of a "new mathematical object discovery system".**

**中文版：[README.zh-CN.md](./README.zh-CN.md)**

</div>

---

> `NODS` formalizes the idea that **discovering a new object = detecting an
> unsatisfiable constraint in the current structure + finding a minimal
> consistent extension** — and it proves, inside the theorem prover, why each
> object *must* appear, rather than just inventing new symbols.

## The core insight

The single most important judgment of the whole formalization (stated at the top
of `Nods/Core/Framework.lean`):

> **"Minimal extension" is not an absolute concept.** It only makes sense
> relative to (a) a background theory `T'` (the category the extension must live
> in) and (b) a forgetful map (refinement) from the current theory `T` to `T'`.
> Otherwise there is no definition of "minimal" at all — you could take either a
> trivial extension or an outrageously large one.

This yields **two mechanisms** that force new objects to appear:

| Mechanism | Meaning | Classic example |
|-----------|---------|-----------------|
| **Refinement** | Move to a stronger background theory | N→Z, Z→Q, Q→R |
| **Extra / Axiom** | Add a new constant + axiom in the same theory | R→C (`j² = -1`) |

Both are unified in the `Demand` structure (`Nods/Core/Demand.lean`).

## Repository layout

```
Nods/
├── Theories/
│   └── Algebraic.lean        # Theory ladder: CS ⊇ CR ⊇ FL ⊇ LOF
├── Core/                     # The six core layers
│   ├── Framework.lean        # Theory · Model · Framework · Refinement
│   ├── Demand.lean           # Requirement · Extension · Extension hom
│   ├── Verdict.lean          # Failure verdict: solved / dead / gap
│   ├── Minimal.lean          # Uniqueness of minimal extension
│   ├── Score.lean            # Generativity score · objective gate
│   └── Engine.lean           # Discovery engine
└── Instances/                # Number-system extension instances
    ├── NatToInt.lean         # N → Z   (subtraction closure)
    ├── IntToRat.lean         # Z → Q   (division closure)
    ├── RatToReal.lean        # Q → R   (completeness)
    └── RealToComplex.lean    # R → C   (j² = -1)  ⚠️ TODO
```

The six core layers recreate the classical chain

> N → Z → Q → R → C

and *explain why each object must appear*, before (in later versions) being
pointed at unknown mathematical structures.

## Status

- The 6 core layers and the instances N→Z, Z→Q, Q→R are formalized.
- **`RealToComplex.lean` (R→C) is currently an empty file** — the natural next
  step, and the best test of the "extra constant + initiality" (`IsMinimal`)
  path.
- **`lake build` currently fails** in `Nods/Theories/Algebraic.lean`
  (lines 87–93): the `Refinement` instances use explicit type casts to forget
  structure, and Lean cannot synthesize the coercion. The likely fix is to
  delegate along the `SemiringLike` refinement path instead of casting.
  See `docs/wiki/current-status.md` for details.

## Getting started

```bash
# Install Lean 4 + mathlib (see https://lean-lang.org)
curl https://raw.githubusercontent.com/leanprover/lean4/master/lean-toolchain \
  > lean-toolchain

lake env lean Nods/Probe.lean      # or: lake build
```

Dependencies are vendored locally under `.lake/` (no network needed at build).

## Project documentation

The project follows a **wiki-first** knowledge system (LLM Wiki v2 schema):

- `docs/wiki/project-overview.md` — what NODS is and the core insight
- `docs/wiki/current-status.md` — what is formalized, what is failing, risks
- `docs/wiki/sources-and-data.md` — source documents and provenance
- `docs/wiki/SCHEMA.md` — the wiki page schema

Run the validation suite:

```bash
python3 scripts/wiki_check.py
python3 scripts/wiki_lint.py --strict=v2
python3 scripts/raw_manifest_check.py
```

## License

[MIT](./LICENSE)