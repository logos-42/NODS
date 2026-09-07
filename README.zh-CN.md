<div align="center">

# NODS — New Object Discovery System（新数学对象发现系统）

**一个用 Lean 4 + mathlib 形式化的"新数学对象发现系统"。**

**English: [README.md](./README.md)**

</div>

---

> `NODS` 把下面这个想法形式化：**发现新对象 = 发现当前结构中的不可满足约束 + 寻找最小一致扩张**——并且它在定理证明器内部证明"每个对象**为什么必须出现**"，而不是随便发明新符号。

## 核心洞察

整个形式化最关键的一个判断（写在 `Nods/Core/Framework.lean` 顶部）：

> **"最小扩张"不是绝对概念。** 它只有相对于 (a) 一个背景理论 `T'`（扩张必须住在哪个范畴里）和 (b) 一条从当前理论 `T` 到 `T'` 的忘却（refinement），才有意义。否则"最小"根本没有定义——你既可以取一个平凡扩张，也可以取一个大得离谱的扩张。

由此区分出**两种迫使新对象出现的机制**：

| 机制 | 含义 | 经典例子 |
|------|------|----------|
| **Refinement（理论强化）** | 换一个更强的背景理论 | N→Z、Z→Q、Q→R |
| **Extra / Axiom（添常元）** | 在同一理论里添新常元并加公理 | R→C（`j² = -1`） |

两者在 `Nods/Core/Demand.lean` 的 `Demand` 结构里统一。

## 目录结构

```
Nods/
├── Theories/
│   └── Algebraic.lean        # 理论阶梯：CS ⊇ CR ⊇ FL ⊇ LOF
├── Core/                     # 六个核心层
│   ├── Framework.lean        # 理论 · 模型 · 语架 · 理论强化
│   ├── Demand.lean           # 需求 · 扩张 · 扩张同态
│   ├── Verdict.lean          # 失败判定：solved / dead / gap
│   ├── Minimal.lean          # 极小扩张的唯一性
│   ├── Score.lean            # 生成力评分 · 目标函数门
│   └── Engine.lean           # 发现引擎
└── Instances/                # 数系扩张实例
    ├── NatToInt.lean         # N → Z   （减法闭包）
    ├── IntToRat.lean         # Z → Q   （除法闭包）
    ├── RatToReal.lean        # Q → R   （完备性）
    └── RealToComplex.lean    # R → C   （j² = -1）
```

六个核心层重演经典扩张链

> N → Z → Q → R → C

并**解释"为什么每个对象必须出现"**，之后（在后续版本中）再指向未知的数学结构。

## 构建状态

- 6 个核心层以及四个实例 N→Z、Z→Q、Q→R、R→C 全部完成形式化，`lake build` 全绿（Lean v4.21.0 / mathlib）。
- 经典扩张链 N → Z → Q → R → C 已完整重建，每一步都有机器证明：**它是在上一结构中的"缺口"（一条失败的 demand），而不是凭空发明的符号**。
- 仍留一条文档化义务：`real_initiality_obligation`（**O1**）——对任意完备 Archimedean 有序域 K，有序域同态 R → K 的唯一性。它以 `axiom` 记录（约 80 行的 Dedekind 切割分析推迟到 v0.2）；v0.1 用 `IsCutGenerated` 顶上。细节见 `docs/wiki/current-status.md`。

## 论文发表（2026-09-07）

- **开方/幂分离论文（英文版）**——*The radical as a forced structure: how to split powers from radicals*（Yuanjie Liu）。Lean 验证挠分离（核/纤维/塌缩判据）+ 带证书二次与 Cardano 三次求解器，0 证明缺口。
  - aiXiv 预印本：`aixiv.260907.000001`（v1.0）
  - 以太坊主网 EAS 存证（schema #405：ipfsCid + title + sha256）：
    `0x5e52a523299a348fd61f2264ac735e6bbfd5ecc439c35718432aa5791d53e05d` —
    https://easscan.org/attestation/view/0x5e52a523299a348fd61f2264ac735e6bbfd5ecc439c35718432aa5791d53e05d
  - IPFS：`QmVQDR2MT2fGKkAeUhKTjTmg9boqAnFiaSoMAfdHTys7Ec`（sha256 `d0ddbafc…e15c9`）
  - 源码：`paper/radical/`（中英双版，jsfds 模板）

## 快速开始

```bash
# 安装 Lean 4 + mathlib（见 https://lean-lang.org）
curl https://raw.githubusercontent.com/leanprover/lean4/master/lean-toolchain \
  > lean-toolchain

lake env lean Nods/Probe.lean      # 或：lake build
```

依赖在 `.lake/` 下本地物化（构建时无需联网）。

## 项目文档

本项目遵循 **wiki-first** 知识系统（LLM Wiki v2 schema）：

- `docs/wiki/project-overview.md` — NODS 是什么、核心洞察
- `docs/wiki/current-status.md` — 已/未形式化、构建失败点、风险
- `docs/wiki/sources-and-data.md` — 原始素材与来源追踪
- `docs/wiki/SCHEMA.md` — wiki 页面 schema

运行校验套件：

```bash
python3 scripts/wiki_check.py
python3 scripts/wiki_lint.py --strict=v2
python3 scripts/raw_manifest_check.py
```

## 开源协议

[MIT](./LICENSE)