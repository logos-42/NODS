/-
NODS v0.1 — New Object Discovery System
=======================================

"发现新对象 = 发现当前结构中的不可满足约束 + 寻找最小一致扩张"
                                                    —— design.md

这个库把这句话做成了可以编译、可以检查的定理。

目录
----
Core/Framework  理论 · 模型 · 语架 · 理论强化
Core/Demand     需求 · 扩张 · 扩张同态
Core/Verdict    失败判定（三分：solved / dead / gap）· 失败空间
Core/Minimal    极小扩张的唯一性与刚性
Core/Score      生成力评分 · 乘积目标函数 · 相对新颖性
Core/Engine     发现引擎 · 进展定理 · 安全性定理
Theories/       交换半环状理论 CS ⊇ CR ⊇ FL ⊇ LOF
Instances/      N→Z、Z→Q、Q→R、R→C
Chain/Demo      轨迹与打印

已证明的
--------
* N 上不存在交换环结构（x + 1 = 0 无解）
* Z 上不存在域结构（2x = 1 无解）
* Q 不是 Dedekind 完备的（{q | q² < 2} 无上确界）
* R 中 x² = -1 无解
* Z 是 N 在 CommRing 下的极小扩张（初始对象）
* Q 是 Z 在特征零域下的极小扩张（初始对象）
* (C, i) 是 R 在"添一个 j, j² = -1"下的极小扩张（初始对象）
* 两个极小扩张唯一等价；极小扩张没有非平凡自同态
* 重命名 ⇒ 目标函数为 0

刻意留下的洞
------------
* O1：R 在完备 Archimedean 有序域中的初始性（见 Instances/RatToReal）
* 自动约束生成器（design.md §11）
* 评分中 U / R / C / M 的自动化估计
-/

import Nods.Core.Framework
import Nods.Core.Demand
import Nods.Core.Verdict
import Nods.Core.Minimal
import Nods.Core.Score
import Nods.Core.Engine
import Nods.Theories.Algebraic
import Nods.Instances.NatToInt
import Nods.Instances.IntToRat
import Nods.Instances.RatToReal
import Nods.Instances.RealToComplex
import Nods.Chain
