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
    └── RealToComplex.lean    # R → C   (j² = -1)
```

The six core layers recreate the classical chain

> N → Z → Q → R → C

and *explain why each object must appear*, before (in later versions) being
pointed at unknown mathematical structures.

## Status

- All 6 core layers and all four instances — N→Z, Z→Q, Q→R, R→C — are
  formalized, and `lake build` passes (Lean v4.21.0 / mathlib).
- The classical chain N → Z → Q → R → C is fully reconstructed, with a machine
  proof that each step is a *gap* in the previous structure (a failed demand),
  not just an invented symbol.
- One documented obligation remains: `real_initiality_obligation` (**O1**) — the
  uniqueness of the ordered-field homomorphism R → K into any complete
  Archimedean ordered field K. It is recorded as an `axiom` (the ~80-line
  Dedekind-cut analysis is deferred to v0.2); in v0.1 `IsCutGenerated` stands in
  for it. See `docs/wiki/current-status.md` for details.

## Publications (2026-09-07)

- **Radical / power-splitting paper (EN)** — *The radical as a forced structure:
  how to split powers from radicals* (Yuanjie Liu). Lean-verified torsion split
  (kernel / fibers / collapse criterion), certified quadratic + Cardano cubic
  solvers, 0 proof gaps.
  - aiXiv preprint: `aixiv.260907.000001` (v1.0)
  - Ethereum mainnet EAS attestation (schema #405: ipfsCid + title + sha256):
    `0x5e52a523299a348fd61f2264ac735e6bbfd5ecc439c35718432aa5791d53e05d` —
    https://easscan.org/attestation/view/0x5e52a523299a348fd61f2264ac735e6bbfd5ecc439c35718432aa5791d53e05d
  - IPFS: `QmVQDR2MT2fGKkAeUhKTjTmg9boqAnFiaSoMAfdHTys7Ec` (sha256 `d0ddbafc…e15c9`)
  - Source: `paper/radical/` (zh + en, jsfds template)

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