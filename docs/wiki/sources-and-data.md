---
title: 资料与数据
source: session
created: 2026-09-04
last_confirmed: 2026-09-04
schema_version: 2
audience: self
stage: current
confidence: high
entity_type: meta
tags: [data, raw]
---

NODS 的"原始资料"不是 pdf/xlsx 那类业务原件，而是本项目自己的**构思文档与源码**。它们目前就住在 repo 内：

| source_id | 类型 | 内容 | 编译到 |
|-----------|------|------|--------|
| `src-design-001` | thinking | `design.md` — 新数发现器构思；结构闭包清单；评分函数 D(X)；Mathematical Object Discovery Engine | [project-overview.md](./project-overview.md) |
| `src-skill-001` | thinking | `skill.md` — 算法第一版；四个核心模块；诚实四函数；(伪)原型伪码 | [project-overview.md](./project-overview.md) |
| `src-code-core-001` | code | `Nods/Core/*.lean` — 6 个核心层 | [current-status.md](./current-status.md) |
| `src-code-instances-001` | code | `Nods/Instances/*.lean` — 数系扩张实例（R→C 待做） | [current-status.md](./current-status.md) |
| `src-code-theories-001` | code | `Nods/Theories/Algebraic.lean` — 理论阶梯 | [current-status.md](./current-status.md) |

## 维护流程

本项目源文件（design.md / skill.md / Nods/）直接进 Git，与"raw 只放本地"的通用策略不同——因为对数学研究项目来说，**源码本身就是可版本化的编译产物**。真正的"不复现的气象/会议/闲聊原始记录"若存在，应放 `../nods_raw/`。

清单登记与核对：

```bash
python3 scripts/raw_manifest_check.py
python3 scripts/stale_report.py
python3 scripts/delta_compile.py --write-drafts   # 只生成草稿，不覆盖
```
