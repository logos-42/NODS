# forced-objects/ — NODS 设计论文

一句话：**判断「这是发现」该不该信，用三个只能答是/否的问题；然后拿它查了自己的项目，拒了一个、认了一个没做完、搞砸了一个测量。**

## 文件

| 文件 | 说明 |
|---|---|
| `forced-objects.tex` | 英文版《Where the Ladder Must Stand》（无副题，18 页） |
| `forced-objects-zh.tex` | 中文版《台阶何处不可不立》（无副题，11 页） |
| `forced-objects.pdf` / `-zh.pdf` | tectonic 编译产物，双版 0 错误、0 未定义引用 |
| `nods.bib` | 参考文献；数系/范畴/模型论/形式化 10 条 DOI 已核，AI-discovery 4 条只到卷页，Benacerraf/Shapiro 为通行书目待核 |
| `aixiv_meta.json` | 投稿元数据（标题、摘要、分类、关键词、许可） |
| `adversarial-review-cns.md` | 七轮攻防全记录（前六轮 CNS 标准，第七轮发表前终审） |

格式同 `ProjectionPhysics/paper4`（REVTeX 4.2 + ctex/fandol、中英双版、tectonic）。

## 编译

```bash
cd paper/forced-objects && tectonic forced-objects.tex
cd paper/forced-objects && tectonic forced-objects-zh.tex
```

## 结构

1. 问题（√7 改名的故事）→ **背景**（数系多种造法、Benacerraf/结构主义）→ **前人关于必然性说过什么**（初始对象、模型完全）→ 问题表 → 四条结论预告
2. **前人做了什么**（造数系 / 泛性质 / 形式化 / 机器发现 / 哲学 / 本文定位）
3. 三问的检验（同元素 / 最小 / 新）+ 「被迫」四种含义与本文只取哪一种
4. 为什么第二问能钉住对象
5. 查到了什么（三步通过、实数那步只断言、计数不变量被拒）
6. 失败的那次测量（比元素个数 → 闸门自拒）
7. 做不到什么（C0、不生成需求、不能判定、只拒过一个自家候选、裁决相对于三元组）
8. 讨论 / 9. 方法（形式设置、信任基底、核过·论证·假设三分、数据与代码）

## 诚实账本

- 三级证据分开写：**机器检验**（塔三步、四处失败、两个打分的分离）／**手工论证**（计数拒绝）／**断言**（ℝ 的极小性，且无定理消费）。
- 前提 C0（语架必须是标准映射）未形式化，需要它的陈述标"modulo C0"。
- 第三问（是否新）只给规格未实现，第一版实现被本文自己的例子推翻。
- 一条具名公理 O1 + `native_decide`（后者只支撑本文不报告的数值核对）。
- 数据可用性已改实话：计数/振动是 Lean 定义，轨迹里分数手填，仓库另含无关工作，Mathlib 未 pin。

## 发表前清单

文本层与 artifact 层均已就绪：

1. **固定版本**：tag `paper-forced-objects-v1.1`，commit hash 写进三份稿件的数据可用性；`lakefile.pinned.toml` 把 Mathlib 钉在 `56a0058`（本机物化 HEAD）。
2. **能构建**：`.github/workflows/lean.yml` 用 pinned lakefile 跑 `lake update → cache get → build Nods`，并打印 axiom / `native_decide` 清单。
3. **artifact 边界**：`artifact/SCOPE.md` 给白名单，`scripts/export_artifact.sh` 导出并自检——出现 `pu12` 或 `deploy` 直接失败退出；根 README 不随 artifact 分发。

## 发表（2026-10-31）

- **aiXiv EN 首发**：`aixiv.261031.000002`（Under Review，公开；v1.0 → **v1.1** 去掉副题）——
  https://aixiv.science/papers/aixiv.261031.000002
- 标题 *Where the Ladder Must Stand*（**只用主标题，无副题**；v1.1 起）；分类
  `Formal Sciences > Mathematics > Logic`；CC-BY-4.0；8 关键词。
- **只发英文版**：中文版只留仓库（aiXiv 无删除端点）。
- 摘要与 PDF 逐字一致：`aixiv_meta.json` 的 abstract 由 `forced-objects.tex` 的 abstract 反解析生成；
  改摘要必须同时改 tex 并重编译，否则记录与 PDF 分叉。

## 投稿去向（第七轮结论）

- 首选 **Philosophia Mathematica** 一档：材料是「判据 + 两次自我否决 + 一次公开失败」，在概念澄清的评价体系里是资产；在 JAR/ITP 的规模与新意体系里是负债。
- 若愿意在 Lean 上再投 3–6 个月（证掉 O1、加一个非数系塔实例、补 CI 与 pin），可拆出**独立的形式化短文**投 ITP/JAR，本文保留概念部分。
- 不建议现在投 Synthese：它要求更宽的"为什么重要"，而手上独有的是"一个拒绝自家候选的判据"。
