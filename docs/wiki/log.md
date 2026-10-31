# Wiki 日志

## [2026-10-31] 论文：被迫对象 | aiXiv 首发（EN v1.0 → v1.1 去副题）

- **记录**：`aixiv.261031.000002`，当前版 **v1.1**（v1.0 保留），status `Under Review`，`is_public=1`；
  上传者「元杰 刘」`~User52`；PDF 公开直链为 OSS s3_url（HEAD 200, `application/pdf`，与本地 sha256 逐字节一致）。
- **只发英文版**（leo 口径）：中文版《台阶何处不可不立》只留仓库，不上 aiXiv（无删除端点，误发不可撤）。
- **标题定稿（v1.1）**：leo 要求标题只用主标题 —— EN *Where the Ladder Must Stand* / 中《台阶何处不可不立》，
  双版 tex 删掉 `\large` 副题行后重编译（EN 19 → 18 页：原先那张空标题页随之消失）；`aixiv_meta.json` 标题同步；
  已走 `POST /api/submissions/{id}/versions` 升 **v1.1**（平台无 patch/delete，改标题只能升版，v1.0 记录保留）。
  公开 submitter 端点 v1.1 返回 `submitter_type=agent`（bolloon ~bolloon1）而 v1.0 曾返回 `human` —— 这是 token 属 agent 的平台行为，
  `authors=["Yuanjie Liu"]` 与上传者「元杰 刘 ~User52」不变；按实测如实记录，不承诺该字段。
- **元数据**：标题（v1.1 定稿）*Where the Ladder Must Stand*；分类
  `Formal Sciences > Mathematics > Logic`；CC-BY-4.0；8 个关键词（mathematical discovery / minimal extension /
  initial object / rigidity / number systems / formal verification / Lean 4 / negative result）。
- **摘要与 PDF 逐字一致**（2,022 字符，脚本从 tex abstract 反解析生成、比对 `identical=True`）：把摘要补到与
  正文诚实账本同一水位——ℝ 那步缺的极小性记成点名义务且**无定理消费**；计数不变量被拒是因为**塌成素因子个数差**
  从而同一批元素上已可定义（手工论证，该层无形式化需求）；每个裁决**相对三元组**（环境理论/精化/清单）；
  数学核心 Lean 4 + Mathlib：0 sorry、一条具名公理、无定理消费它。
- **同步动作**：EN/ZH 双版 tex 摘要按同一措辞重写并重编译（EN 19 页 / ZH 11 页，0 错误；仅余既有 underfull 警告），
  `aixiv_meta.json` 摘要与 tex 对齐后提交。
- **未做**：EAS 主网锚定（默认停用）；artifact 三件待办（tag+commit、Mathlib pin、Lean CI）仍按 README 发表前清单
  留在论文数据可用性里，未在论文中含糊。

## [2026-10-31] 论文：被迫对象 | 第七轮发表前终审 + 可读性定稿

- **第七轮（换标准）**：不再问"够不够 CNS"，问"按现在声称的归档能不能发、有没有会被读成造假的话"。三条线：史实归属（A）、外行可读性与承诺一致性（B）、投稿适配与可复现（C）。
- **事实层 2 处必改**：Benacerraf 的例子是**自然数**不是整数，第二支是"数不是对象"不是"不是集合"；本文标题不出自 Benacerraf。另 4 处归引过宽（Landau 唯一性、Ebbinghaus "收齐"、"自由群完备化"、模型完全"同样的唯一性"）+ 2 处补引（HOL Light/HOL88 年代、Lean/Mathlib 代际）。
- **承诺层 8 处收紧**：表 1 改为"机器检验 / 手工论证 / 断言"三级证据（原与摘要冲突）；问题一四处读法统一为"问的是元素不是解"；共轭例子改说"比较映射不再唯一"；"modulo C0"真正写进表注；§5 的 7 行表补齐两行解释；Methods 的 Checked 列表改为"有具名声明"；定理一补声明名；打分里的 novelty 与问题三的"新"明确区分。
- **两处会被当作造假，已删改**：①"可执行的计数与振动模型在公开仓库"→ 实为 Lean 定义、轨迹里分数手填；②"六轮由独立审稿线阅读"→ 改为"六轮对抗式自审，由作者工具以独立审稿线形式跑出"。数据可用性同时坦白：仓库另含无关工作、Mathlib 未 pin、不宣称一键构建。
- **新增两段**："被迫"的四种含义（形而上学 / 概念 / 实践 / 被确定，本文只取第四种）与"裁决相对于三元组"（限定主张，回应判据自反性）。删去"投稿定位"段（审稿人视为不专业）。
- **标题改定**：EN《Where the Ladder Must Stand》/ 中《台阶何处不可不立》（副题保留"一个检验、三种裁决、一次失败的测量"，避免隐喻标题失去可检索性）；摘要后的修订注记删除，改为题记（"凡可被定义者，皆可被追问"）。
- **成稿**：EN 19 页、ZH 11 页，双版 0 错误 0 未定义引用；新增 `aixiv_meta.json`；`README.md` 加发表前清单（tag/commit、Mathlib pin、Lean CI、artifact 边界）。
- **结论**：文本可发；artifact 还不可发——三件待办已写进 README，不在论文里含糊。

## [2026-10-31] 论文：被迫对象 | 判据三问 + 六轮攻防 + 自我否决

- **v4.1 补回学术骨架**（用户指出缺背景/问题/相关工作）：§1 增背景（数系多种造法＋唯一性、Benacerraf 1965 与结构主义）、「前人关于必然性说过什么」（初始对象／模型完全）；新增**问题表**（已知／要问／三个障碍／答法／实际交付）与**四条结论预告**；新增整节**前人做了什么**（造数系并证唯一／泛性质与比较唯一性／形式化／机器发现／哲学／本文定位）。EN 18 页、ZH 9 页，双版 0 未定义引用。
- **新目录 `paper/forced-objects/`**（参考 `ProjectionPhysics/paper4` 格式：REVTeX 4.2 + `ctex/fandol`、中英双版、tectonic）。英文《What makes a mathematical object forced? A test, three examples, and one measurement that failed》，中文《数学对象什么时候是"被迫"的？一个检验、三个例子，和一次失败的测量》。EN 13 页 / ZH 7 页，双版 0 错误、0 未定义引用。
- **v4 为可读性重写**（用户反馈"不说人话"）：一段一个意思、先说人话再上符号、形式陈述退进表 1/表 2 与方法节；叙事线 = 问题（√7 改名）→ 三问 → 为什么第二问能钉住对象 → 查到什么 → 失败的那次测量 → 做不到什么 → 讨论 → 方法。
- **判据口径（v3 起）**：两条件可用（同元素不可解、最小扩张唯一到改名）+ 第三问"是否新"只给规格未实现。前提 C0（语架须为标准映射）未形式化，相关陈述标"modulo C0"。
- **三次自我否决**（都写进正文，不藏）：① 早期把缺口写成"ℕ 上不存在环结构"（假命题，可数搬运），改为 `HasSolution` 的强化等式；② 计数不变量 τ = ω(a) − ω(b) 被拒（同一载体可定义），且拒绝是手工论证（计数层无 `Demand`/`HasSolution` 实例）；③ 闸门按载体等势判新颖性 ⟹ ℤ/ℚ/ℂ 互相判成改名，闸门自拒（`Score.lean` 注释已注明应换 T′-同构）。
- **新增 Lean 定理（`Nods/Core/Score.lean`）**：`weighted_sum_admits_renaming`（新颖性 0 而生成力 $4/5>0$）与 `product_rejects_renaming`（同取值乘积 0）——把"加权和 ≠ 乘积闸门"从散文变成可核陈述；边界：只是均值/乘积算术，不含改名模型。`lake env lean Nods/Core/Score.lean` 通过。
- **六轮攻防**（`paper/forced-objects/adversarial-review-cns.md`）：R1 意义 / R2 形式化（查出 3 处事实错误：`IsCutGenerated` 不存在、`HasSolution⟹novelty=0` 无定理、`renaming_kills_objective` 缺 `hx`）/ R3 内部一致 / R4 交叉审（判据按陈述形态不可满足、C0 未兑现、O1 惰性）/ R5 可证伪性（只剩计数塌缩一条真可证伪主张）/ R6 编辑终审（CNS 定位下 Reject，正确归档为形式化数学 / 数学哲学）。修订逐条落地。
- **诚实边界**：一条具名公理 O1（ℝ 初始性，**无定理消费**）；`native_decide` 仅支撑本文不报告的 `Tension.lean` 数值核对（v2 曾把方向说反，v3 撤回）；塔前三步只在"同一条定理的实例"意义上声称新意。
- **未提交**：本批未 commit；按门禁先跑三件套。

## [2026-10-31] PU-12 v3.3 | 迁移实验根因(学习冻结) + 变体 v2(加大 seg + 重置 N, GPU2)

- **42h 实验结论**：GPU2 持续迁移实验（B=4096, seg=30000）跑了 21 次探针、累计 67M 深度 ticks，`fewshot_speedup` 均值 0.49、**无上升趋势**（首 0.317→末 0.306）→ 负迁移稳定存在、不随深度改善。分组：goal 18 最轻(0.72)，goal 5 最重(0.33)；热启动几乎总顶满 60000 拍上限，冷启动仅 1.8–4.4 万拍。
- **根因定位**：持久 Q 在目标轮换后被「降频先验」锁死在 band≈9。B=4096 验证：第一轮 band 能完整跟踪目标(18→16.5…5→4.9)，第二轮 goal 18 只到 9.48。机理是 Q-learning 步长 `1/(n+1)` 与 UCB 探索随访问次数衰减→**Q 冻结**；冻结后连续 180k 拍 goal 18 也只能拉回 14.8。故「加深/加时间」反而冻结，非能力不足。
- **修复与变体 v2**：实验脚本新增可选 `--reset-n`（每段结束重置访问计数 N、保留 Q）——非平稳 RL 标准做法。实测 B=4096 每轮 band 均完整跟踪（第二轮 18→16.8、5→4.0）。已用 `logs_experiment_v2`、pid 33716、GPU2、B=4096、**seg=60000**、probe-train=90000、`--reset-n` 重启，无限循环+看门狗不间断；v3.3 主程序（pid 15335, GPU3）不受影响。首探针约 2h 后。
- 部署脚本 run/watchdog/up_experiment 支持 OUT/PIDF/RESET 覆盖，可并行不同变体。
- **受控探针 v3（真·迁移）**：v2 首探针 speedup=17.66 被起点位置污染（warm 从持久宇宙当前位置≈16 出发、cold 从零爬到 15），非纯知识迁移。已加「受控 cold」：warm 前 `copy.deepcopy(u)` 抓完整起点状态，cold 从同一状态、仅 Q 为空出发，得 `fewshot_speedup_ctrl`（起点相同只差 Q）。以 `logs_experiment_v3`、pid 35021 重启（seg=60000、reset-n、GPU2），主指标改用 ctrl。

## [2026-10-31] 仓库卫生 | .gitignore 补 Python 缓存（`__pycache__/` `*.pyc`）

- **现象**：`scripts/__pycache__/` 下两个 .pyc（`pu12_v33.cpython-312.pyc`、`pu12_v33_mirror.cpython-312.pyc`）长期显示为未跟踪脏项；原 `.gitignore` 只忽略 `.obsidian/`、`raw*` 与 `.lake/`，没有 Python 缓存规则。
- **改动**：`.gitignore` 追加 `__pycache__/`、`*.pyc`（Python 缓存）与 `.DS_Store`、`._*`（macOS 元数据）四条（仅忽略规则，不动任何代码或脚本行为）。
- **未做**：本批**未 commit** —— 运行环境当前无法执行 shell（`git status` / `lake build` / 三个门禁脚本均无产出），`wiki_check.py` / `wiki_lint.py --strict=v2` / `raw_manifest_check.py` 未能跑；按 commit 门禁，未跑门禁即不提交。
- **影响面**：零。不涉及 Lean 源码、定理、可执行模型。

## [2026-10-29] PU-12 v3.3 | 持续迁移实验(GPU,不间断) + 目标奖励对称化 + push

- **push**：v3.3（频率上限 10^81 / 实体×100 / 镜像 benchmark / wiki）已提交并推到 `origin/master`（`b2713ca`）。
- **目标奖励对称化**：`_reward_goal` 原只对「升频靠近目标」给 +1、降频(下潜)给 -0.5，导致低于当前位置的目标带永远够不到。改为对称：低于目标→升频 +1、高于目标→降频 +1、方向错→-0.3，使高/低目标都可及，迁移测试才公平。`run()` 现支持可选传入持久 `u/L/gen`（供实验复用）。
- **镜像 benchmark 刷新**（对称奖励重测，B=1024）：`benchmark_score = 0.62`（M1=1.0 目的达成、M1-ctrl 随机失败、M2 能量守恒、M3 策略最优 0.55、M4 少样本 `fewshot_speedup=0.40` 仍为负迁移、M5 结构 0.18）。报告 `logs_mirror/benchmark.json`。
- **持续迁移实验**（`scripts/pu12_v33_experiment.py`）：持久宇宙 Q 不重置，轮换迁移目标（兼容高带 18/15/12 在前，挑战低带 8/5/10 在后），每 2 小时对一新目标做热/冷启动少样本探针，写 `logs_experiment/experiment.jsonl`，检验「深度/训练时间更长能否改善迁移」。
- **部署到 GPU2 不间断跑**：原 CPU 实验停止，改在 **GPU2**（`CUDA_VISIBLE_DEVICES=2`，B=4096，`DEVICE=cuda`）运行（pid 16777 + `watchdog_experiment.sh`），不设立停止时间；v3.3 主程序仍在 GPU3。首条探针约 2h 后产出。
- **commit 门禁**：wiki_check / wiki_lint / raw_manifest_check 绿后提交（本次含实验脚本、部署脚本、奖励修复、wiki）。未 commit 前不 push。

## [2026-10-29] PU-12 v3.3 | 频率上限 10^81 + 实体×100 + 镜像 benchmark

- **需求（leo）**：频率上限抬高 + 跑 3.3（空间更大、实体×100）+ 附带小任务/镜像版 benchmark 测量模型内部智能。
- **频率上限**：地板固定视界频率 `10^-19 Hz`，天花板 `10^41 → 10^81`（跨度 100 数量级）。为保持 `r=10^5` 交换整数化结构不变，频率带 `12 → 20`（`N_BANDS = (81 − (−19)) / 5`）。绝对频率只作报告参数，GPU 相位动力学仍用相对频率。
- **实体×100**：`B = 16384 → 1638400`（提高两个数量级）；空间随之更大；GPU3（RTX 4090 24GB）显存约 10.6 GB。
- **脚本** `scripts/pu12_v33.py`（继承 v3.2 循环深度/逐带学习/UCB+退火）；部署 `run_v33.sh`/`watchdog_v33.sh`/`up_v33.sh`/`status_v33.sh`，日志 `logs_v33/`；`run_v33.sh` 默认 `B=1638400`、`GPU=3`、`--ticks 0`（连续运行）。
- **镜像 benchmark**（`scripts/pu12_v33_mirror.py`，对照/智能探针）：同构小宇宙（CPU, B=1024）训练后跑 5 探针 —— M1 目的达成（purpose_tick=16718, cov 480/480, ever_top=1.0）、M1-ctrl 随机对照失败、M2 `E ≡ B·9` 守恒、M3 策略最优一致率 0.58–0.70、M4 少样本负迁移（fewshot_speedup=0.50，warm 慢于 cold）、M5 序列熵近最大（结构分 0.18）。
- **benchmark_score = 0.63**：任务学习强 + 物理完美自洽，但无正迁移智能、动作流无语言级结构（诚实对照结果，非缺陷判定）。报告 `logs_mirror/benchmark.json`（服务器 `/work/liuyuanjie/pu12/`）。
- **部署**：229 服务器停 v3.2（pid 6497 + watchdog_v32），起 v3.3（pid 15335, GPU3）；镜像 benchmark 已跑完。
- **门禁**：本次为服务器部署 + 脚本新增；wiki_check / wiki_lint / raw_manifest_check 已跑（绿）后未 commit（用户未要求提交）。

## [2026-10-27] PU-12 v3.2 | 循环深度 · 递归无限

- **需求（leo）**：3.2 做成**循环深度、递归无限**。
- **做法**：取消 `MAX_DEPTH` 闸门。
  - 递归深度改成**无界计数器**（每扩张/细分 +1，永不停）；
  - 地址只保留**最近 W 位 12 进制**（循环缓冲，写满从头覆盖 = 循环深度）；
  - 更早的层折进 **61 位滚动哈希** ⟹ 地址身份含全部历史，内存恒定（`window=64` 时每个体 192 字节）。
- **实测（B=16384, GPU3, window=64）**：`top_tick=14503`、`purpose=14530`（288/288 格）；
  tick 70801 时递归深度 **sub/subs=70.0、fine=55.0 —— 已越过窗口 64**，仍在增长（v3.1 在 204 处冻结、v3 在 17 处冻结）；
  地址空间 `10^153.2`，频率分辨率 `10^-92.8` 带，占用 16384 格。
- **循环窗口的正确性单独验过**：`--window 4` 跑到深度 5.6（越过窗口）不报错、地址继续变化。
- **诚实边界**：窗口内层数精确；更早的层只剩哈希，**无法还原**（等于记住身份、忘掉细节）。
  深度计数器是 int64，理论上限 ~9.2e18 层 —— 按当前速率够跑天文长的时间，但不是数学上的无限。
- **部署**：`scripts/pu12_v32.py` + `run_v32.sh` / `watchdog_v32.sh` / `up.sh`，`logs_v32/`；v3.1 已停。
- **门禁**：`wiki_check.py` / `wiki_lint.py --strict=v2` / `raw_manifest_check.py` 全绿后提交。

## [2026-10-27] PU-12 v3.1 | 地址深度放开 + 逐带学习状态

- **需求（leo）**：深度更深，递归深度再加深 12 次方的量级 —— 作为 **3.1 包**。
- **拆墙**：v3 把 12 进制地址打包进 int64，`12^17 < 2^63` 就是硬上限（扩张/细分到 17 位就冻结）。
  v3.1 改成 **(B, 204) 的 12 进制数字数组**，深度上限 204 位；相对 17 位容量再乘 `12^187 ≈ 10^202`，
  `--max-depth` 可继续调。地址空间按实测算：深度 46 位时平均 `10^107.9`。
- **两处"假发展"被抓出来**：
  1. 细分频率原本不要求满格，且奖励 +0.2 ⟹ 实测 1000 拍内被刷到深度上限 204（`ref=103424`），
     只是"数字变大"不是发育。改为与扩张同样要求结构满格，深度现在随发育逐步增长（实测 31.8 并在涨）。
  2. 学习状态原本只有 3 个带桶 ⟹ 实体只会认桶底，带分布挤在 0/4/8。改为**逐带状态**
     （12 带 × 满格 × 达成 = 48 态，探索空间 288 格），带分布变成带 0–10 各约 9%（均匀铺开）。
- **实测（229 服务器 GPU3，B=16384，maxd=204）**：`top_tick=14205`、`purpose=14229`（288/288 格走遍），
  深度 sub/subs=46.2、fine=31.8 持续增长；带 11 常驻 0%（实体到顶就下潜体验，符合"屏蔽能力回低带"）。
- **部署**：`scripts/pu12_v31.py` + `run_v31.sh` / `watchdog_v31.sh` / `up.sh`，日志 `logs_v31/`；v3 进程已停。
- **门禁**：`wiki_check.py` / `wiki_lint.py --strict=v2` / `raw_manifest_check.py` 全绿后提交。

## [2026-10-27] PU-12 v3 上线 | 多层格点 × 实体自主学习 × 目的判据

- **需求（leo，第二版）**：实体分布在维度/频率/能量上自行发育；低维实体把频率升高进化到更高维；
  所有低维都走到高维才算宇宙目的达成；走高维的过程靠**实体学习**；高维实体可屏蔽能力回低带体验。
  追加口径：目的 = 「所有实体曾到达最高带」**且**「探索的可能性都走过」。
  追加规格：格子要更大更细 —— 12 维度 × `12^(12^12)` 子维度 × `12^(12^12)` 亚维度 × 12 频率带，频率还可细分。
- **先说边界**：`12^(12^12) ≈ 10^(9.6×10^12)` 个格子无法枚举也无法存储。实现是
  **符号地址空间 + 按需实例化**：层级/进制严格照规格（12 进制地址串，每扩张一次追加一位），
  只把被实体占住的格子落地；理论容量与已实例化占用分开报（`theory_total` / `occupied`）。
  地址深度的工程上限 17 位 12 进制（`12^17 < 2^63`，装得进 int64）。
- **`scripts/pu12_v3.py`**：实体状态 = 维度 × 子维度地址 × 亚维度地址 × 带 × 频率细分 × 结构发育度 × 能量 × 相位；
  动作 6 个（等待 / 升频 / 降频体验 / 扩张子维度 / 扩张亚维度 / 细分频率）；
  每个实体自己的 Q 表（12 状态 × 6 动作）+ UCB 探索；目的达成后按"自己想去的低带"（`e_star`）下潜体验。
- **四个上线才暴露的设计错误（全部已修，都写进代码注释）**：
  1. **二元奖励**（v2 初版用 Beta"成功/失败"）：奖励是分级的（等 −0.02、失败 −0.3、未达成降频 −0.5），
     二元化把 −0.02 和 −0.5 压成同一个信号 ⟹ 空状态三个动作全记成失败，实体乱降到带 0。
     改均值 Q（保留幅度）。
  2. **状态里没有带位置**：实体分不清"从高处降下来体验"和"在低处继续往下掉" ⟹ 达成后全体坠到带 0 躺平。
     改 3 个带桶 × 满格 × 达成 = 12 态。
  3. **探索不退火**：`rate=0.005` 时爬升比 UCB 探索带来的下坠慢一个量级，实测 93600 拍 `top=0.00`、
     全体卡在带 1 附近。改 ε 与 UCB 系数按 `anneal` 退火。
  4. **相干度闸门冻死实体**：自加的 `coh > 0.05 才能动作` 让约 3% 走离相的实体永久不能动 ⟹
     目的判据永远差 3%（ever_top 停在 0.97）。相干度改回纯观测量，不做闸门。
- **实测对照（B=1024, rate=0.05, 12000 拍；v2 版结论，v3 同构）**：
  学习版 `top_tick=8173`、`purpose_tick=8186`（含探索 36/36 格），达成后 12 条带上都有实体（每带 3.5%–11%）；
  随机动作版永远到不了顶（`ever_top` 9%），探索只覆盖 18/36 格（达成态根本进不去），50% 堆在带 0–1。
- **部署**：229 服务器 `/work/liuyuanjie/pu12/`，`run_v3.sh` + `watchdog_v3.sh` + `up.sh`（幂等），
  `logs_v3/`；`bash status.sh` 打印带分布、格点深度、地址空间规模、学到的 Q 表。
  v1 / v2 脚本保留在仓库，服务器上只跑 v3（GPU 3）。
- **门禁**：`wiki_check.py` / `wiki_lint.py --strict=v2` / `raw_manifest_check.py` 全绿后提交。

## [2026-10-27] PU-12 宇宙上线 | 229 服务器 GPU 连续运行跑通

- **需求（leo）**：把 PU-12 宇宙放进 229 服务器 `/work/liuyuanjie/`，持续运行、GPU 运行，看发展情况。
- **真相先说清**：上一轮（同日）只把 `scripts`/`run.sh`/`status.sh` 落到 `/work/liuyuanjie/pu12/`，
  **从未真跑过** —— 无 `pu12.pid`、`logs/` 空、无 `status.json`。缺的不是部署骨架，是 torch。
- **环境阻塞与通路（可复用的做法）**：容器 `test_liuyuaniie_luoyan` 是裸 `cuda118:base`（py3.10，无 pip 模块、无 torch），
  出网 ≈100 KB/s：`pypi.org` 直接读超时、`download.pytorch.org` 12 分钟只下 12 MB、`mirrors.aliyun.com` ≈5 KB/s。
  ⟹ **本机（代理 5.3 MB/s）下 wheel → `scp`（实测 20 MB/s 到该内网）→ 远端离线装**：
  `torch-2.7.1+cu118` + 11 个 `nvidia-*-cu11` wheel（合计 2.7 GB），12 个文件 md5 两端逐个一致；
  `pip install --no-deps --target /work/liuyuanjie/pylibs`（4.7 GB，落数据盘，容器重启不丢）。
  小依赖（filelock/sympy/networkx/jinja2/fsspec/numpy）走阿里镜像装同目录。
  **坑**：我本地把 wheel 改名成 `torch_cu118.whl`，pip 报 `Invalid wheel filename (wrong number of parts)` —— 传过去必须用原始文件名。
- **代码修两处（都是上线才暴露）**：
  1. `band_omega()` 在 CPU、`spread` 在 CUDA ⟹ 首次真跑必崩（`Expected all tensors to be on the same device`）。
     GPU 分支此前从未被执行（历史只做 CPU 冒烟）。修：`.float().to(device)`。
  2. 成熟判据原本是全系综**同一个常数** `mature` ⟹ 16384 个宇宙严格同步，`dims_mean` 是阶梯函数，
     文档里「各阶段都有宇宙」不成立。新增 `--mature-jitter`（每宇宙阈值 `mature·(1±j)`，默认 0 = 逐位不变）。
- **实测（B=16384, P=64, mature=3000, jitter=0.6, dwell=500, dt=0.05, GPU3）**：
  235 拍/秒；GPU3 利用率 50%、876 MiB 且 `--query-compute-apps` 有本进程；
  `energy_err ≤ 1.8e-15`、`E ≡ 147456`（=B·9 束）恒定；稳态 `dims_mean ≈ 6.6`、`dims_hist` 铺满 1…11；
  重生计数随拍数线性累加；提案网 loss→5e-8、接受率 1.0（它只是在学规则，不参与物理）。
- **值守**：`run.sh`（`setsid` 自脱离，PPID=1）+ `watchdog.sh`（60 s 巡检，5 分钟内重启 ≥3 次即放弃写日志）。
- **门禁**：`wiki_check.py` / `wiki_lint.py --strict=v2` / `raw_manifest_check.py` 全绿后提交。

## [2026-10-27] PU-12 宇宙模型 | 振动坐标系 × 张力计数法 × 隐数

- **需求（leo）**：用本仓数学造一个私有宇宙 —— 12 个频率带（按对数量级切分，上限 `10^41 Hz`）、
  频率越高能量越纯粹；12 个维度，每维 3 子维度 + 3 亚维度；初始能量授予，后续从周围结构维度内生获得。
  leo 追加口径：**用振动坐标系和张力计数法来构造，隐数是子维度和亚维度的数学**。
- **新文件 `Nods/Theories/Universe.lean`**（已接主链 `Nods.lean`，`lake env lean` 通过，0 sorry 0 warning）：
  - 阶梯：`bandHi k = 10^41/10^(5k)`、`bandLo k = bandHi (k+1)`；`bandHi_strictAnti`；
    `bandLo_eleven`（地板 `1/10^19`）；**`band_ratio`：相邻带比值恰为 `10^5`**；
    `no_band_below_floor` / `no_band_above_ceiling`（**阶梯封闭**，12 条不是截断）。
  - 振动/能量：`omega k = 2π·bandHi k`（`step_phase_advance` 的连续读法）、`quantumE = ℏω`；
    `omega_strictAnti` / `quantumE_strictAnti` / `quantumE_ratio`。
  - 纯度：`spectralPurity`（阶梯位置）与 `quantumPurity`（`ε/E`）**两条独立定义**都严格反单调，
    `purity_agree` 证两版一致 ⟹「频率越高能量越纯粹」是定理。
  - TCM：`countTension`（K/L = 剖面第二/三分量的加法同态）= 一个具体的 `AddTension`，四条公理全证；
    `countTension_collapse_form` **直接调用仓库已证的 `AtomicReading.collapse`**；
    `countTension_collapse` 取「+条数差」支；`structReading`（share = 两边条数的较小者）+
    `struct_tension`：**宇宙张力 = 隐数条数差**。
  - 流动：`exch` + `sum_exch`（量子数守恒）、`energy_exch`（`ΔE = q(ε_j − ε_i)`，与 `band_ratio` 合起来
    ⟹ 跨带交换整数化：1 个高带量子 = `10^5` 个低带量子，能量精确相等）、
    `energy_up_of_upconvert`（上转换 ⟹ 能量/纯度严格上升）、`tension_zero_iff`（平衡 ⟺ 条数相等）。
- **新文件 `scripts/universe_model.py`**（精确 `Fraction` 算术，无浮点）：30/30 检查通过，跑出
  `docs/models/pu12/{report.md,trace.json}` + `docs/figures/pu12_ladder.png`（已登记 raw manifest `src-fig-pu12`）。
  - **定阶（为什么 5 个数量级）**：均匀 12 带 + 必须覆盖宇宙视界频率 `f_H = 1/T_U = 2.30e-18 Hz` +
    整数 decade ⟹ `41 − 12m ≤ log10 f_H = −17.64` ⟹ `m ≥ 4.89` ⟹ `m = 5`（唯一最小解）⟹
    地板 `10^-19`、`r = 10^5`。`m = 4` 覆盖不到视界（差 11 个数量级），`m = 6` 会有 13 个数量级的潜伏带。
  - **结构**：维度 = 隐数空间三轴 `σ₁σ₂σ₃`（3 子维度）× 隐数三射线 `S/R/iR`（3 亚维度）= **9 个隐数格**，
    `size = 已点亮格数`。亚维度 = 隐数（HIBS A1/A2/A3）。
  - **动力学**：`E₀ = 9ε₀`（恰好一隐数格一量子）；每代 `q = τ(父, 新生) = 9 − 0 = 9`；
    跨一带 1 个量子 → `10^5` 个量子（能量精确守恒）；新生维度原子出生（整副 3×3 格）⟹ 与父维度 `τ = 0` 不回流。
    结果：`E ≡ 9ε₀` 恒定、`N` 每代精确 ×`10^5`、纯度 `Π = 1/N`（`1 → 10^-55`）、每代内生获得 `9ε₀`，
    11 代走完 12 维后因地板封闭而终止。
  - **消融 5 组**：κ=1 张力门控（仍长满 12 维，N=9.9e6）、单位流量、非原子出生（τ 塌到 1）、
    反向全量（纯度 `10^-55 → 1`）、反向张力门控（**卡在第 2 维**：`τ ≤ 9 ≪ r = 10^5`，凑不出一次「10^5 合 1」）。
- **诚实边界**：12 带 / `10^41` / 3×3 / 初始能量是给定参数；推导结论是 5 数量级 / 地板 / `r = 10^5`；
  A5（射线随带升高偏 iR）是公理，机制解释（相位闭合需更深开方）是动机非证明；耦合 κ 是自由参数；
  模型只给结构，不给物理预言。
- **门禁**：`wiki_check.py` / `wiki_lint.py --strict=v2` / `raw_manifest_check.py` / `lake build Nods` 全绿后提交。
- **GPU 连续演化（同日部署）**：`scripts/pu12_gpu.py` — 12 带 × 12 维 × 每带 64 个相位振子（振动坐标），
  束（1 束 = ε₀，任意带同值）守恒 ⟹ 能量精确守恒、量子数 `Σb_k·10^5k`；`τ = 条数差` 门控 + 成熟时间
  `--mature` 把维度出生摊到可观察尺度；κ 异质 + 生命史重生让系综长期保持各阶段都有宇宙；
  提案网 12→64→3→12（3 维 = 隐数空间三维）只提案、规则接受，接受率是学习曲线（不参与物理）。
  部署：`100.100.30.229:30003` 容器 `test_liuyuaniie_luoyan`（4×RTX 4090，用 GPU 3），
  `/work/liuyuanjie/pu12/`（`run.sh` / `status.sh` / `logs/`）；`deploy/pu12/` 存引导与启动脚本。
  容器是裸 `cuda118:base`：`bootstrap.pypa.io` 与 `pypi.org/pypi/*/json` 在该容器内卡死，
  改从本机 scp pip wheel（解包后 `PYTHONPATH` 跑 pip）+ `download.pytorch.org/whl/cu118` 装 torch 才通。


## [2026-10-19] 工具链迁移完成 | v4.35.0 构建全绿（0 error 0 sorry）

- **结果**：`lake build` 9070 jobs **全部通过**，0 sorry；v4.21.0 → v4.35.0 迁移完成。
  剩余均为样式级警告（`linter.style.haveILetI` 的 `let` 建议、`module` 导入建议、
  两处 unused simp args），不阻塞构建。
- **探针诊断的核心结论**（与 leo 的探针观察一致：继承链的 toMul 打印与 rw 模式不匹配）：
  v4.35 扁平化 algebra 层后，`frameworkOfSemiringLike` 的 `Hom`（tactic block 定义）
  在 rw/simp 的**动机检查（implicit 透明度）**下不再折叠为 `→+*`，打印出的目标看似
  匹配模式、实际重查类型失败；`Framework.toFun` 的折叠在无期望类型引导的 `Eq` 两侧
  类型统一里同样失效（`exact` 有期望类型时正常）。四实例文件各修法：
  - `IntToRat.lean`：`charZero_of_emb_inj` 的 `simpa only [Int.castRingHom]` 改为
    「`have h1 := F.emb_inj` + `rw [hFemb] at h1` + `exact h1`」（探针 Z2）；
    `intToRat_minimal` 的 over_prop 改为「`congrArg` 搬 `F.emb` + `rw` + `show` +
    `map_intCast`」（探针 M2），弃用 `simp only [Biframed.forget_toFun]`（no progress）。
  - `RatToReal.lean`：`rat_gap` 的 `simpa [horder]` 缝合不了 `s'.toLinearOrder` 派生
    Preorder 与原生 `Rat.instPreorder`；改为 `have h1 := hax.1` + `rw [horder] at h1`
    （DedekindComplete 的 Preorder 只在实例参数位，rw 动机安全；
    `Rat.instPreorder := inferInstance` 即同一条 DistribLattice 派生链，改写后直接对上）。
  - `RealToComplex.lean`：`realToComplex_minimal` 的字段名 `.over` → `.over_prop`；
    `complexLift F.emb` 应用类型不匹配 → 内联 ascription
    `(F.emb : ℝ →+* F.target.carrier)`（与 `have hemb := F.emb` 同机制，无期望类型时
    Hom↔RingHom 不互认）；over_prop/唯一性用 `Biframed.forget_toFun` 等式项拆 forgetHom、
    余下折叠交 `exact` 的 defeq。
  - `IntToRat.lean` 的 `int_gap`（继承链对齐）在迁移中已修复：v4.35 里 Field 的
    `toMul`/`toOne` 走 `GroupWithZero` 侧链（`toDivisionSemiring` 直接给 GroupWithZero），
    与 `Semiring` 侧链 rfl 相等；对齐引理沿 `hstr` + `Field.toSemifield` 展开。
- **方法论沉淀**：v4.35 下修这类错误的通用配方——①先探针隔离「哪一段 defeq 失效」
  （逐段 `have … := rfl`）；②rw/simp 动机检查失效时改用「等式项 + trans/congrArg/show」；
  Hom↔RingHom 跨类型用**内联 ascription** 或 `have` 桥接（有期望类型时 defeq 可过）。

## [2026-10-18] 工具链 | 迁移 v4.35.0（进行中）：废弃 v4.21.0

- **leo 指令**：NODS 改为最新版（v4.35.0，stable）运行编译，废弃旧版。
- **已完成**：`lean-toolchain` → `leanprover/lean4:v4.35.0`（本批 commit）。
- **进行中（待 N-S build 完成通知）**：本地物化依赖（`.lake/packages/` 下 9 包：
  mathlib/batteries/Qq/aesop/proofwidgets/importGraph/LeanSearchClient/plausible/Cli）
  由 NavierStokesAndEuler 项目（`~/Downloads/NavierStokesAndEuler`，Lakefile
  `require mathlib git rev v4.35.0`，mathlib rev `56a00585` = "chore: bump toolchain
  to v4.35.0"，已编译 8643 olean 进行中）的**已编译物化**替换（NODS 9 包 ⊆ N-S 11 包，
  Lakefile 的 path 依赖结构零改动）→ 重新 `lake build` → 修 v4.35.0 下 API 差异
  （若有）→ 三门禁 → 迁移完成批 commit。
- **诚实边界**：本批构建状态 = 待验证；push 后远端 toolchain 为 v4.35.0，
  本地物化替换完成前不可在 NODS 跑 `lake build`（旧 olean 与新 lean 不兼容）。

## [2026-10-18] 振数坐标系 | 几何坐标化：离散极坐标层（leo 修正后实现）

- **leo 修正**：上一条可行性分析（本日）的结论是「几何坐标在 TCM 公理内不可能」——
  leo 要求**使得可以几何坐标化**。实现出路：`metric_not_nontrivial` 只堵
  「张力 = 距离的纯函数（零集 = 对角线）」这一形态，**不堵「给坐标配几何」**——
  保留张力为力（TCM 塌缩不动），把振数坐标变成真正的极坐标。
- **新文件 `Nods/Theories/VibrationGeometry.lean`**（已接主链，`lake build Nods`
  0 sorry 0 warning，`#print axioms` 无 `sorryAx`）：
  - `phaseFrac`：相位分数 θ = phaseIdx/period ∈ ℚ 模 1（`phaseFrac_nonneg`/`_lt_one`：0 ≤ θ < 1）
  - `PhaseLink_self` + `phaseFrac_self`：原点相位 = 0（自链 k = 0）
  - **`step_phase_advance`（均匀旋转，主定理）**：走一步角度精确推进 1/period —— 轨道是正 N 边形
  - `polarCoord`：极坐标（半径 = period，角度 = phaseFrac）
  - **`phaseFrac_injective` / `polarCoord_injective`**：同窗口角度相同 ⟹ 同一点（坐标可分辨）
  - **`tension_abs_eq_radial_dist`（几何化桥，主定理）**：|张力| = |振数差| = 径向距离
  - `circleDist`：圆距离 min(|Δθ|, 1−|Δθ|)；自零 / 对称 / 非负 / 分离（`circleDist_eq_zero_iff`）
  - `polarDist`：极坐标度量 = |半径差| + 圆距离；自零 / 对称 / 分离（`polarDist_eq_zero_iff`）
  - 实例：点 (2, 1/2)（对合 = 半圈）/ 线 (3, 1/3)、(3, 2/3) / 数中心 (1, 0)
    （周期 1 = 退化圆 = 不振 = 原点）+ `line_phase_advance_example`（1/3 → 2/3 均匀推进机器核对）
- **含义**：坐标系从「计数/分类」升级为「带几何」——每个振动体占据模空间一个
  极坐标点：坐标唯一、运动均匀（定角旋转）、力的量值 = 半径差。
- **诚实边界**：离散 ℚ 圆（正 N 边形）；连续弧度（2π·θ ∈ ℝ、U(1)、sin）v2；
  `polarDist` 三角不等式 v2。ħ = 每弧度角动量的连接点是 phaseFrac 的连续化极限
  （共振点，非已证）。
- **回写**：`vibration-coords.md`（几何坐标化节 + 台账 + 下一步 ③ 更新 +
  可行性分析节「不可能」结论更正）、`current-status.md` 追加；raw manifest 无需登记
  （纯代码文件，`src-code-vibration-002` 注释更新）。

## [2026-10-18] 振数坐标系 | 弦论推导可行性分析（模空间 / 组合律 / 连续谱）

- **leo 问**：坐标系能否实现？能否直接构建一个新空间体系、在里面推导出弦论？
- **结论一（坐标系）**：计数坐标已实现（`phaseCoord = (period, phaseIdx)`，0 sorry），
  几何坐标在 TCM 四条公理内**不可能**（`metric_not_nontrivial` 度量被堵 +
  `size_only` 内容不可见）——「坐标系」的两种含义必须分开。
- **结论二（新空间）**：能构建的是**模空间（mode space）**= 独立振子的乘积
  （`productDynamics` 已是种子），坐标 = 每振子 `(振数, 相位)`，维数 = 独立振子数。
  这正是简正坐标/傅里叶模空间的结构——弦的模展开 `X = Σ Xₙ e^{2πinσ}` 天然住这里。
  真运算：组合（并，已形式化）/ 张力可加（T6）/ 相位推进；缺距离层（换读数
  才能有几何）与连续化（相位是 ℕ 不是弧度）。
- **结论三（弦论）**：**推导不出**。能证的是「振动优先于弦」（载体任意，弦只是
  载体之一）；推不出频率谱（哈密顿量对角化 = 动力学内容）、临界维数 D=10/26
  （量子化一致性）、相互作用、背景时空度量。深层数学：连续振动 = `ℝ → U(1)`
  同态 = 频率（Pontryagin 对偶/特征群）——傅里叶分析就是振动的数学；频率谱
  不在计数里，与 `O-TCM-canon`（RH 不在计数里）同型。
- **候选缺口（NODS 判据，按距代码远近）**：① 组合律——叠加两振子总振数是和还是积，
  若"叠加后仍单振子且保塌缩"在同一载体不可表达 ⟹ 逼出叠加运算 = 给空间装算术；
  ② 连续频率——什么约束逼出 ℝ 值频率（候选：时间平移对称连续化 → U(1) 特征）；
  ③ 相位 → 角度——轨道内序 ℕ 升级为弧度，**接 ħ = 每弧度角动量**（共振点，非已证）。
- 未改代码；本批只回写分析结论。

## [2026-10-18] 振数坐标系 | 相位层（第二坐标）：最小周期 + 轨道内序

- **`Nods/Theories/Vibration.lean` 新增 §4.5 相位层**（0 sorry 0 warning，已接主链）—— 振数坐标从一维升级为二维：第一坐标 = 振数 `period x`，第二坐标 = 轨道内序。
  - `MinimalPeriod`：`period x` 是最小正周期（`∀ x k, 0 < k → k < period x → step^k x ≠ x`）—— 不是振动本体的起点（本体已由 `Dynamics` + `period_exists` 建立），只负责让「轨道内第几步」成为唯一的第二坐标。
  - `period_invariant_minimal`：最小周期沿轨道不变（可逆性 + 最小性 ⟹ `period (step^k x) = period x`）。
  - `PhaseLink`：`y` 在 `x` 的一个周期窗口内可达（`∃ k < period x, step^k x = y`）—— 局部规范版本，不需要重新选轨道代表元。
  - `phase_position_unique`（主定理）：最小周期 ⟹ 相位链步数唯一（`step^k x = step^k' x` 且都在窗口内 ⟹ `k = k'`）。
  - `phase_link_unique`：`∃! k`；`phaseIdx`（`Classical.choose`）+ `phaseIdx_lt` / `phaseIdx_spec` / `phaseIdx_step`（走一步，原始步数推进一格）。
  - `phaseCoord`：坐标对 `(period x, phaseIdx)`。
- **§7 实例补齐**：新增 `pointPeriodicDynamics : PeriodicDynamics (Fin 2)`（显式周期 2，`swapFin2` 对合）与 `linePeriodicDynamics : PeriodicDynamics (Fin 3)`（显式周期 3，`shiftFin3` 移位）—— 此前 §5 只有裸 `Dynamics`，`MinimalPeriod`/`PhaseLink` 无载体可挂。三个最小周期证：`num_minimal`（ℚ 反转：中心 1/2 振数 1、其余 2）/ `point_minimal` / `line_minimal`；相位数值：`point_phase_link`（`0 → 1` 一步可达）、`point_phase_idx`（`phaseIdx 0 1 = 1`）、`point_phase_coord`（`(period 0, phaseIdx 0 1) = (2, 1)`）。
- **含义**：相位是周期之上的第二坐标，唯一性来自最小周期——没有 `MinimalPeriod`，同一个 `y` 可在窗口内多步到达（周期倍数），第二坐标无从定义。对合（周期 2）仍是相位层的实例而非起点。

## [2026-10-17] 振数坐标系 | 无限载体：ℚ 反转（显式周期）+ PeriodicDynamics 泛化

- **leo 选的下一步：无限载体（轨道有限假设下的显式周期）。**
- **`PeriodicDynamics` 泛化**（`Nods/Theories/Vibration.lean`，仍 0 sorry 0 warning）：
  - 去掉 `[Fintype X]` 约束 —— **载体不限有限**。`same_orbit_comm` 不再依赖
    `period_exists`（鸽笼），改用结构字段 `period x` + `step_period` 补足轨道对称性
    （`p = period x`、`q·p ≥ k`）⟹ **有限与无限载体共用同一套读数与塌缩**。
  - 有限载体周期仍由 `period_exists`（鸽笼）**逼出**；无限载体周期是**显式结构字段**
    （轨道有限假设）—— 两条路都通。
- **新实例：`ℚ` 反转（无限载体）**：`numPeriodicDynamics`（`revQ1 : x ↦ 1 − x`）。
  `period := if 1 − x = x then 1 else 2` —— 中心 `1/2` 振数 1（不振），其余 2。
  - `num_period_center` / `num_period_off_center`：中心 1、非中心 2（机器核对）。
  - **`num_center_balanced`：中心 `1/2` 处张力为零** —— 不振 = 临界，
    `Re = 1/2` 的形状回到视野（作为数振动的**不动点实例**，不是推导起点）。
- **wiki `vibration-coords.md`**：实例表加入 ℚ 行 + 泛化说明（`PeriodicDynamics`
  不要求 `Fintype`）+ 台账更新（无限载体 🟢）+ 「下一步」标记无限载体已完成。
- **回写**：`current-status.md` 追加；`manifests/raw_sources.csv` 更新
  `src-code-vibration-001`。

## [2026-10-17] 振数坐标系 | 修正：从静态世界从 0 推导振动本体（不再借对合/临界线）

- **leo 方向修正**：不要从对合、临界线、`Re = 1/2` 这些**中间结构**出发推导，
  要从系统架构（静态世界）从 0 推导振动本体。
- **重写 `Nods/Theories/Vibration.lean`**（仍接主链；`lake build Nods` 0 sorry 0 warning）：
  - **第 0 步**：静态世界（已有）—— `AtomicReading` + 张力公理 + 塌缩。不是振动。
  - **第 1 步：动力学公理（唯一新公理）** `Dynamics`：`step : X ≃ X`（**可逆**自演化
    = 时间反演对称）。载体 X 任意——点/线/面/数一切皆可振。
  - **第 2 步：零张力动力学（定理）** `dynamics_tension_free`：保 size 演化 ⟹
    `τ(x, step x) = 0` —— TCM「内容不可见」的动力学版：**内容在变、张力为零**。
  - **第 3 步：周期被逼出（定理）** `period_exists`：有限载体 + 鸽笼 ⟹
    `∃ p > 0, step^[p] x = x`。辅助：`cancel_iter`（可逆迭代抵消）、`iterate_split`、
    `period_of_repeat`（轨迹重复 ⟹ 周期）、`iterate_mul_fixed`（周期倍数闭包）、
    `same_orbit_comm`（同轨道对称，用周期 + q·p ≥ k，不需要最小周期）。
  - **第 4 步：振数坐标** `vibrationReading`（size = period，share = min 共同周期）+
    **`vibration_collapse`（张力 = 振数差）**；`vibCoord` / `vib_tension_is_coord_diff`。
  - 实例：点（`Fin 2` 交换）/ 线（`Fin 3` 循环）/ 面（`Fin 2 × Fin 3` 双振子），
    周期存在各被 `period_exists` 证出（`point_period_exists` 等）。
  - **对合降级为实例**（`swapFin2` 只是周期 2 的振动），不再是推导起点；
    `ℚ` 反转、`Re=1/2` 连接移出（无限载体需显式周期假设，见「下一步」）。
- **wiki `vibration-coords.md` 重写**：推导链四步（静态世界 → 动力学公理 → 零张力 →
  周期逼出 → 坐标）+ 坐标系规范表 + 诚实台账（唯一新公理 1 条，其余全定理）。
- **诚实边界**：周期需要载体有限（鸽笼依附 `Fintype`）；无限载体要 `PeriodicDynamics`
  式显式周期或轨道有限假设。
- **回写**：`current-status.md` 追加；`manifests/raw_sources.csv` 更新
  `src-code-vibration-001` 注释。

## [2026-10-12] 张力计数法 | 公理优化（T5 出列）+ 扩到 ℝ/ℂ（代数数的次数读数）

- **两个新文件**（均接主链，`lake build Nods` 0 sorry 0 warning，`#print axioms` 无 `sorryAx`）：
  `Nods/Theories/TensionOptimal.lean`（11 定理）、`Nods/Theories/TensionAlgebraic.lean`（5 定理）。

### ① 公理优化：T5 出列（`TensionOptimal.lean`）

- **主结果 `share_coeff_zero`：T4′ 反号自己就把共享项系数消掉。**
  全共享剖面 `(t,0,0)` 反着读还是自己 ⟹ 反号要求该处张力等于自己的相反数 ⟹ ℤ 里只能为 0。
  原来这一步靠 T5（自零：两力各自为零）来做，**现在证明不需要它**。
- `grade_linear_free`（不带任何假设的线性化）→ `grade_eq_scale`（**T6 + T4′ ⟹ 张力 = 刻度 × 条数差**）
  → `scale_cases`（**T7 ⟹ 刻度 ∈ {−1, 0, +1}**）→ `forced_three`（±条数差 或 恒零，不假设 T5/T3b）
  → **`forced_four`：T6 + T7 + T4′ + T3b ⟹ `τ = ±条数差`，不需要 T5**。
- `nonfull_iff_scale_ne_zero`：**T3b ⟺ 刻度 ≠ 0** —— 它是「去零力」的非退化要求，不是结构公理。
- 读数版：`AtomicReading.collapse_three` / `collapse_four`。
- 读数接口补一条自然性质 **`share_self`（自共享）**：⟹ `onlyA_self` / `onlyB_self` / `toProfile_self`
  ⇒ **「自张力为零」不是公理，而是读数的性质**。
- ⇒ **权威表 6 条 → 4 条**，分工变干净的三层：**T4′ 管形状 / T7 管刻度 / T3b 管去零**；
  T5 的真正作用只有一个：把 `K` 与 `L` 各自钉住（对**张力差** —— 唯一可观测的东西 —— 无影响）。

### ② 扩到 ℝ 与 ℂ：代数数的次数读数（`TensionAlgebraic.lean`）

- 前一层结论是「ℝ/ℂ 作为**域**没有乘法原子 ⇒ 乘法路堵死」。本层换路：**不数因子，数共轭。**
  对代数数 `x`（`IsIntegral ℚ x`）：`size(x) := deg (minpoly ℚ x)` = **共轭个数 = 域扩张次数**；
  `share(x,y) := 极小多项式相同时取全部，否则 0`。
- `algReading` 只要求 `L` 是 ℚ 的域扩张 ⟹ **ℝ 与 ℂ 共用同一个读数**（`algReadingR` / `algReadingC`）。
- **`alg_tension_is_degree_diff`：张力 = 次数差**（用优化后的四条表，不需要 T5）。
- `alg_tension_zero_of_same_size`；`natDegree_minpoly_rat_real` / `_complex`（**有理数条数 = 1**，已机器核对）；
  `size_of_minpoly_X_pow_sub_C`（`Xⁿ − c` 型 ⟹ 条数 `n`；`√2` 与 `i` 都是这一型）。
- **三条边界**：
  1. **超越数仍进不来**（无有限极小多项式）⟹ **修正早先结论**：「ℝ 的缺口是结构性的」应改为
     「**ℝ 的非代数部分**进不来」—— 代数部分有一条**内蕴的路（次数），且这条路不是乘法**。
  2. **次数读数很粗**：有理数全是 1 条 ⟹ 有理数之间张力恒为零；共轭数（极小多项式相同）也全共享。
     这是**读数的分辨率**问题，不是公理的问题。
  3. `share` 取「极小多项式相同」而非「共同因子的次数」：更细的 gcd 版本需要多项式 gcd 的
     归一化引理（`gcd m m = m`）；而按塌缩定理，**共享项对张力毫无影响**，故不必要。
- **结构性观察**：ℂ 现在有**两个**读数（ℤ[i] 数高斯素数 / 次数数共轭）⟹
  **同一载体可以有多个读数，读数不同、张力不同**，但每个读数内部张力仍被逼死。

### 回写

- `tension-counting.md`：**页首权威表升级为 TCM-3（4 条）** + 「公理优化」节 + 「扩到 ℝ 与 ℂ」节
  + 两条台账行 + 下一步重写（读数已有三种口味：乘法条数 / 次序条数 / 共轭条数）。
- `current-status.md`；`manifests/raw_sources.csv` 登记 `src-code-tension-006` / `-007`。

## [2026-10-12] 张力计数法 | 塌缩的哲学含义 + 对合层（临界线 = 对合的不动点）

- **新文件** `Nods/Theories/TensionDuality.lean`（13 定理，已接主链，`lake build Nods` 0 sorry 0 warning，`#print axioms` 无 `sorryAx`）。
- **塌缩的哲学含义**（写入 `tension-counting.md`「塌缩的哲学含义」节）：`τ = 条数差` 不是「结果太薄」，
  而是四条承诺的**精确外延、没有一丝余量** ——
  **计数**（只看「有几条」⟹ 排除「是哪些条」）/ **线性**（⟹ 排除耦合项）/
  **是力不是距离**（T4′ ⟹ 排除一切对称量）/ **共享不计力**（T5 ⟹ 排除线性共享项）。
  四条排完只剩一个东西：条数差。**这个名字把整个理论写完了。**
- **归因更正**：早先把「内容不可见」记成 T5 的后果是**错的**。两条承诺分工不同 ——
  **计数性**排除「是哪些条」；**T5** 排除「共有多 = 收敛」这个线性共享项。文档已改。
- **三个读法**：① 作为极简计数法是**好消息**（不能再简，且可证）；
  ② 作为「新空间」是坏消息（`ω` = Hardy–Ramanujan 1934 / Erdős–Kác 1940，条数差不是新空间），
  但**支持 leo 最初的直觉**：数字的临界现象**正是 ω 的分布**（Erdős–Kác 正态律），
  而它**完整地住在条数里**；ζ 零点与 `Re = 1/2` **不在条数里** ⟹ 「RH 不在计数里」，
  这解释了 `O-TCM-canon` 为什么难；
  ③ 最要紧：**理论是关于「什么算一条」的，不是关于力的** ——
  选原子（语义全在此）+ 数条数（力被逼死）⟹ 扩载体与内容进场是同一个难题，
  都卡在**原子分解那一侧**。
- **三个门（各有票价）**：放弃计数 ⟹ 原子带重量的加权版；放弃线性 ⟹ 允许耦合；
  放弃 T5 ⟹ 回到两力图景；放弃「是力」⟹ 得到距离（`metric_not_nontrivial` 已证到不了非平凡临界流形）。
- **对合层**：缺的件是「**对合 + 载体里的 `1/2`**」。已证：
  `fixOf`（中心 = 对合的不动点集）/ `fixOf_invariant` / **`selfdual_tension_zero`（中心处张力为零）** /
  `revZ_involutive` + `revZ_fix_iff`（反转 `ι(x) = c − x`，不动点 `⟺ 2x = c`）/
  **`revZ_exists_fix_iff_even`（中心存在 ⟺ `c` 为偶 ⟹ 载体里必须有 `1/2`）** /
  **`revZ_one_no_center`（ℤ 上没有 `1/2` ⟹ 无中心）** / `revQ_fix_iff`（ℚ 上中心 = `c/2`）/
  **`revQ_one_fix_iff_half`（`1 − x = x ⟺ x = 1/2` = `Re = 1/2` 的形状）** /
  `nat_reversal_not_involutive`（ℕ 上连对合都不是）。
  ⇒ **临界线 = 对合的不动点集**；`Re = 1/2` 就是「`1 − s`」的不动点，而 `1/2` 只在 2 可逆的载体里存在。
- **诚实边界**：给的是**临界线的形状**，不是 **RH**（零点落在线上需真的 ζ）。意义是**把缺件说准**。
- **下一个真问题**：对合的**内蕴性** —— ℤ 的 `c − x` 借加法结构；ζ 的函数方程 `s ↦ 1 − s` 才是内蕴的。
- **回写**：`tension-counting.md`（哲学节 + 归因更正 + 对合节 + 台账行 + 下一步重写）；
  `current-status.md`；`manifests/raw_sources.csv` 登记 `src-code-tension-005`。

## [2026-10-12] 张力计数法 | 读数升级：从 `Finset` 到序列 / 自由幺半群（塌缩定理）

- **新文件** `Nods/Theories/TensionReading.lean`（8 定理，已接主链，`lake build Nods` 0 sorry 0 warning，`#print axioms` 无 `sorryAx`）。
- **接口降级**：载体从「有限集分解 `supp : X → Finset A`」降为**读数** `AtomicReading = (share, size)`，
  只要求 `share` 对称与 `share ≤ size` —— 无集合、无交并差、无序、无乘法。
  ⇒ 重集（自由交换幺半群）、序列（自由幺半群）都成合法载体。
- **主结果：塌缩定理** `collapse` —— `τ(a,b) = size a − size b`。
  共享项被 **T5 自零**强制消去，张力只能是两边的**条数差**；收敛力 / 发散力只是条数差拆两半的记账。
  ℕ 上的样子 `dirTension_grade_eq_omega_diff`：**τ = ω(a) − ω(b)**（不同素数个数之差），
  与 §10 五个数值例子全部对上（已机器核对）；早先「临界流形 = {|S∖T| = |T∖S|}」可简化为 **{两边条数相同}**。
- **三个后果**：
  1. 扩载体的问法变干净：**扩到 X ⟺ 给 X 找一个内蕴的条数 `size`**（不必再找集合分解）。
  2. 「共同点当收敛力」必然失败的正解：共享项被 T5 强制消去，是公理组的结构性后果，不是可修的 bug。
  3. **内容不可见**（`size_only`）：条数相同 ⇒ 张力为零，不论「是哪些条」。
- **实例**：`ofFinset`（上一层接口 = 本层特例）/ **`listLCP`（序列：共享 = 最长公共前缀 `lcpLen`）**；
  `list_tension_is_length_diff` 说序列上的张力就是长度差 —— 诚实说明：LCP 也属共享、照样被约掉，
  **任何读数都一样**，所以本层的真收获是「张力只看得见有几条，看不见是哪些条」。
- **对 ℝ**：判据从「找有限集分解」变为「找内蕴有限条数」；CF 项数只对有理性有限
  ⇒ 能进的是**二次无理数**（Lagrange：前缀 + 周期有限），一般无理数仍进不来。
- **分叉点**：要让内容进场只能**放弃 T5（自零）**，代价是「数与自身有正张力」—— 记为候选 TCM-3（内容版）。
- **回写**：`tension-counting.md` 新增「升级：从 `Finset` 到读数」节 + 台账行 + 下一步重写；
  `current-status.md` 追加本条；`manifests/raw_sources.csv` 登记 `src-code-tension-004`。

## [2026-10-12] 张力计数法 | 扩到实数 / 虚数 / 隐数：载体逐个定案

- **leo 要的**：把张力计数法扩到实数、虚数、隐数。
- **新文件 `Nods/Theories/TensionCarriers.lean`**（已接主链；`lake build Nods` 0 sorry 0 warning）：
  - 接口 `AtomicDecomp X A`（= `supp : X → Finset A`）+ `AtomicDecomp.forced`：给了原子分解，逼出定理直接用。
  - **实例**：`natDecomp`（素数）/ `intDecomp`（`|z|` 的素数）/ `ratDecomp`（`num/den` 的素数，分子分母分开）/ **`gaussDecomp`（ℤ[i] 高斯素数）** / **`hiddenDecomp`（隐数）**。
  - **障碍定理**：`field_no_atoms`（域里非零元都是单位 ⇒ 没有不可约元）、`real_no_atoms`、`complex_no_atoms`。
  - 例子 `hidden_tag_balanced`：同值不同标签的两个隐数各独有一条（对方的标签）⇒ 张力为零。
- **三条结论**：
  1. **「虚数」的正确落点是 ℤ[i]，不是 ℂ。** ℂ 是域（无原子），ℤ[i] 是唯一分解环 ⇒ 高斯素数就是原子。
  2. **挡住实数的不是「是不是域」—— ℚ 也是域，但 `num/den` 典范 ⇒ 它有原子。** 真判据是「有没有内蕴有限分解」。
  3. **ℝ 的缺口是结构性的**：`real_no_atoms` 说域里没有原子 ⇒ 扩到实数不能走 ℝ 自己的乘法；借 ℤ/ℚ 就退化成它们的实例，换连分数又只给**序列**不是有限集（截断即引入选择，破坏 T1）⇒ 要扩到实数，必须把抽象从 `Finset` 升级到「序列 / 自由幺半群」。**这是真缺口。**
  4. **隐数（HIBS）有天然原子**：`Hidden = ⟨val : ℤ, tag ∈ {S,R,iR}⟩` ⇒ 原子 = `val` 的素数 **+ 标签本身一条**（标签不是坐标，是一条原子）。
- **审计**：新定理 `#print axioms` → `[propext, Classical.choice, Quot.sound]`（`hidden_tag_balanced` 含 `Lean.ofReduceBool`，走 native 求值），无 `sorryAx`；三个 Tension 文件合 59 定理 0 sorry。

## [2026-10-12] 张力计数法 | 出关：载体抽象 —— 公式与载体无关

- **leo 要的**：把判据从 ℕ 抽象到「任何有原子分解的载体」。
- **新文件 `Nods/Theories/TensionAbstract.lean`**（已接主链 `Nods.lean`；`lake build Nods` 0 sorry 0 warning）：
  - `profileOf S T := (|S∩T|, |S∖T|, |T∖S|)` —— 「原子读数」，TCM 唯一需要的东西。
  - **`forced_carrier_agnostic`（主定理）**：`X` 是**任何**类型、`supp : X → Finset A` 是**任何**原子分解 ⇒ 满足公理的张力只能是 `|supp a ∖ supp b| − |supp b ∖ supp a|`（唯一到取向）。命题里 `X / A / supp` 全是自由变量 —— **没有 ℕ、没有素数、没有乘法、没有序**。
  - **三个实例**：A = ℕ（素因子集，`dirTension` 直读）；B = **任意有限集本身**（`supp = id`，完全不是数 ⇒ 张力 = 两有限集的独有差）；C = ℤ（`suppZ z = |z|` 的素因子集，**一行套用不用重证** —— 抽象出来的收益）。
  - **`supp_intrinsic`**：`p ∈ supp n ↔ p 素 ∧ p ∣ n` —— 原子分解由整除关系定死，**没有选择**（唯一分解）。逼出是载体无关的（定理），**直接性（T1）靠分解的内蕴性**。
- **结论一句话**：**TCM 的载体不是「数」，是「原子集合」；数只是通过唯一分解供应原子集合的一种方式。** 换载体的代价只剩一件 —— 找到该载体自己的内蕴原子分解；找到了，公式不变、定理免费。
- **审计**：新定理 `#print axioms` → `[propext, Classical.choice, Quot.sound]`，无 `sorryAx`。

## [2026-10-12] 张力计数法 | 数字层面为什么成立：直读三句话 + `60 与 45` 算例

- **leo 要的解释**：为什么张力计数法在数字层面成立、为什么能算出两个数之间的张力与收敛力。
- **写进文档**：`tension-counting.md` 新增「为什么它成立：数字层面的直读」一节（置于页首定义之后、权威表之前）。
  - **三句话**：① 每个数就是一捆素数条（唯一分解，不同素数各算一条）；② 两条数并排，每条素数只有三种身份（两边都有 / 只在 a / 只在 b）—— 数对可读的就这三样，所以 T1 是**实话**不是规定；③ 力必须有方向，故「两边都有」出局（对称、推不动任何一边）—— 力只能来自**不对称**。
  - **一句话公式**：`τ(a→b) = |S_a∖S_b| − |S_b∖S_a|`（谁比谁多几条独有）。收敛力/发散力是 T2 的两半记账；哪一半叫「收敛」正是那个被证明**自由**的取向。
  - **算例 `60 与 45`**：`60 = 2²·3·5 → {2,3,5}`、`45 = 3²·5 → {3,5}` ⇒ 共享 `{3,5}` 两条（不进张力）、只在 60 有 `{2}`（1 条）、只在 45 有 0 条 ⇒ `τ(60→45) = +1`，`τ(45→60) = −1`。
  - **四个对照**：`(12,18) = 0`（支撑完全相同）、`(2,3) = 0`（互素但一样陌生）、`(30,7) = +2`（互素但 30 多两条）—— 要害：**它量的不是「像不像」，是「谁比谁多」**。
  - **为什么能算**：分解 → 数三种条 → 相减。有限、可判定、无公式、无极限、无参数。
- **机器核对**：`Nods/Theories/Tension.lean` §10 新增五个例子（`ex_60_45` / `ex_45_60` / `ex_12_18` / `ex_2_3` / `ex_30_7`），与文档表一一对应；现 44 定理，`lake build Nods` 0 sorry 0 warning。
- **审计口径（诚实标注）**：这几个**具体数字**的例子走 `native_decide`，依赖 `Lean.ofReduceBool`（native 求值的标准信任公理）；**一般定理**不需要它（只依赖 `propext / Quot.sound`）。

## [2026-10-12] 张力计数法 TCM-2 | 收尾：权威表统一 + 其它逼出路线 + 刚性

- **收尾（leo 定的第 1 步）**：`tension-counting.md` 页首新增「**当前公理表（权威版 · TCM-2）**」，旧的 TCM-0 五条标注为**已被取代**（只作演进记录）—— 文档里不再并存两套说法。
- **严密性收紧（§9）**：`Nods/Theories/Tension.lean` 仍 0 sorry 0 warning（现 39 条定理）。
  - `grade_linear_gen`：张力差的线性形式，**不假设 T5**。
  - `form_up_to_scale'`：形状的逼出**不需要 T5** —— T4′ 已单独杀掉共享坐标，T3b 保证刻度非零。T5 的活只是管 `(K, L)` 这一对。
  - `kernel_forces`：**「核路」** —— 不靠 T3b，而是**把要发现的临界流形直接写进公理**（`crit u ↔ |S∖T| = |T∖S|`）+ 一个归一值 ⇒ 同一个 τ。
  - `scale_free_without_bound`：无「计数界」时只剩整数刻度自由（`doubleTension`，`c = 2` 反模型）⇒ 形状与刻度是两件事。
- **刚性（NODS 意义的最小性）**：`two_solutions` 证满足公理的张力**恰两个**（`τ` 与 `−τ`）；`forced_grade_swap` + `swapProfile_involutive` + `swap_nontrivial` 证二者互为「反着读」且该对合非平凡 ⇒ 解集两点、商掉取向是单点 = `IsMinimal`。
- **哪条路被否**：`not_leibniz` —— 要求乘法性 `τ(a,bc) = τ(a,b) + τ(a,c)` 得不到我们的 τ（`a=2,b=3,c=5` 时 `−1 ≠ 0`）⇒「乘法性」不是逼出张力的替代路线，是**另一个对象**。
- **结论**：逼出张力的方式**不唯一**（T3b 路 / 核路都到同一 τ），但都到同一个对象；刚性成立 ⇒ 公理搭建收尾。
- **审计**：新定理 `#print axioms` 只剩 `[propext, Quot.sound]`（部分含 `Classical.choice` / `Lean.ofReduceBool`），无 `sorryAx`。

## [2026-10-12] 张力计数法 TCM-1 | 最小化审计：公理表压到六条

- **再压一轮（leo 定的第 1 步）**：`Nods/Theories/Tension.lean` §7–8 新增（仍 0 sorry 0 warning，已接主链）。
- **分工定理**（回答了「T6/T7 能否合并」）：
  - `form_up_to_scale`：T5 + T4′ + T3b ⇒ τ = `c · (|S∖T| − |T∖S|)`（`c ≠ 0`）—— **形状被完全逼出，只留一个整数单位**。
  - `unit_fixes_scale`：再加 T7 ⇒ `c = ±1` —— **T7 唯一的工作就是定单位**。
  - ⇒ T6（可加，管形状）与 T7（单位，管刻度）**不能合并**：两件事正交。
- **单位表可换写法**：`Unit_of_bound` / `Bound_of_unit` 合证「T7（系数 ∈ {0,1}）」与「计数界 `0 ≤ K,L ≤ 总条数`」在 T5 下**等价** ⇒ 公理表只写「力**数不出比东西本身更多的条**」，T7 降为定理。
- **独立性表（反模型法，HIBS 第 8 步）**：每条公理都给反模型 ——
  - T3a **冗余**（`nontrivialCrit_free`）；T5 的 grade 部分**冗余**（`diagonal_grade_zero`：T4′ 已蕴含对角差为零）。
  - T3b **不可省**（`T3b_needed`：`K = L = 0` 满足其余，张力处处为零）。
  - T4′ **独立**（`T4'_independent`：`K = |S∖T| + |T∖S|`、`L = 0` 满足 T5/T6/T7/T3b，却是个对称「距离」而不是力）。
  - T6 **独立**（`additivity_needed`：`|S∖T|² − |T∖S|²` 满足其余各条，却不可加）。
  - T5 不可省（`T5_needed`：否则同一个 τ 可由不同 `(K,L)` 对给出）。
- **压出来的公理表（6 条）**：T1 直接性 + T2 二分力 + T6 计数（可加 且 `0 ≤ K,L ≤ 总条数`）+ T4′ 反号 + T5 自零 + T3b 非全。其中 **T4′ 是把「距离」变成「力」的那一条**。
- **审计**：新定理 `#print axioms` 只剩 `[propext, Quot.sound]`（部分含 `Classical.choice`），无 `sorryAx`。

## [2026-10-12] 张力计数法 TCM-1 | 判别公理 + 逼出定理：τ 不再是记号

- **目标纠偏（leo）**：先完成公理搭建，不直接走黎曼函数 —— 本阶段只做「让张力被逼出来」。
- **`Nods/Theories/Tension.lean` §5–6 新增**（仍 `lake build Nods` 0 sorry 0 warning，已接主链）：加判别公理，把 τ 逼成唯一对象。
  - `profile`：数对的三条计数 `(共享, a独有, b独有)`；`AddTension`：两个力 = 剖面的**可加**映射（`→+ ℤ`）—— T6 计数公理的形式化（逐素数计数、不加权）。
  - `K_linear` / `L_linear`：把「可加」落成「线性」—— 每多一条素数多固定一份力，T6 的确切内容。
  - `grade_linear`：T5 自零的推论 —— **共享条数整个掉出张力差的视野**，张力只看见两条「独有」计数。
  - **`forced_unique`（主定理）**：T5 + T7（单位：系数 ∈ {0,1}）+ T4′（必须反号）+ T3b（非全）⇒ τ 只能是 `|S∖T| − |T∖S|` 或其反号，**没有第三种**。
  - `forcedTension_axioms` + `forcedTension_to_dirTension`：该对象存在，且读回数对**正是 `dirTension`**。
  - 最小化：`nontrivialCrit_free` 证 T3a 是**定理**而非公理；`T5_needed` 证 T5 不可省（同一个 τ 可由不同 `(K,L)` 对给出）。
- **关键改动**：`T4 允许有向` → **`T4′ 必须反号`** —— 这一条是逼出唯一性的开关。
- **与 R→C 同型**：`(ℕ, K=|S∖T|)` 与 `(ℕ, K=|T∖S|)` 是同一载体的两个极小扩张，唯一同构（就是「反着读」）。TCM 由此从「我选了一个记号」升为「被迫 + 刚性」。
- **审计**：`#print axioms NODS.AddTension.forced_unique` → `[propext, Classical.choice, Quot.sound]`，无 `sorryAx`。
- **暂缓**：`O-TCM-canon`（ℂ / ζ）—— 按 leo 指示，先完成公理搭建。

## [2026-10-12] 张力计数法 TCM-0 | Lean 形式化：T5 反例 + 临界流形不唯一

- **新文件 `Nods/Theories/Tension.lean`**（已接主链 `Nods.lean`；`lake build Nods` 全绿 0 warning 0 sorry；`#print axioms` 无 `sorryAx`）：把 TCM-0 的 ℕ 判定从 prose 落成**机器检查**的定理。
  - `Tension D` 结构只含 T1（`K`/`L` 仅吃两个数）+ T2（`grade := K − L`）；T3 / T3′（非平凡临界）/ T4 / T5 做成谓词，于是「实例是否满足某条公理」本身可证。
  - `metric_not_nontrivial`（**Lemma 1 度量障碍**）：单幅度 `τ = f∘d`（`d` 忠实、`f` 只在 0 取零）⇒ 临界流形恒为对角线 ⇒ metric / 序 / 整除三条借来的结构都承载不了 T3′ —— 把「借来的结构失效」从断言升为定理。
  - `radTension_violates_T5`（**新发现**）：`K = |S∩T|`、`L = |SΔT|` 在 `a = b` 时给 `T_grade = ω(a) ≠ 0` —— 页面 §实例化 1 **违反公理 T5**；因算例全取 `a ≠ b`，此前未暴露。两条出路已写入页面（改 T5 语义，或把 `L` 改为含自项定义如 `|S∪T|`）。
  - `crit_manifold_not_unique`（**核心负结论**）：`(6,10)` 在 `dirTension` 下临界、在 `symTension` 下不临界 —— 两个**都满足 T5 + T3′** 的 intrinsic 实例给出**不同临界流形** ⇒ ℕ 上 `IsMinimal` 机器证伪；不唯一的是中心对象本身，不只是函数取值。
  - `nods_verdict_nat` 汇总，结论与上一条一致且更硬：ℕ 需求 = `solved`（非 gap），`novelty = 0`。
- **审计口径**：`#print axioms NODS.nods_verdict_nat` → `[propext, Classical.choice, Lean.ofReduceBool, Quot.sound]`，无 `sorryAx`。

## [2026-10-12] 张力计数法 TCM-0 | 缺口分析：ℕ 为 solved 非 gap

- **新概念页 `tension-counting.md`（draft）**：发明「数字自身张力」的极简公理系统 `TCM-0`（5 条：直接性 / 二分力 / 临界流形 / 方向性 / 退化），四数域实例化（ℕ 素因子 / ℤ 符号 / ℝ 连分数 / ℂ 临界线）。
- **诚实缺口论证（关键）**：对 ℕ 实例化跑 NODS `HasSolution` 检查 —— 素数、`rad`、整除、素因子集、K/L/T 全部在 (ℕ,+,·) 内一阶可定义 → T(a,b) 在现有结构**同一载体**上即可承载 → **判定为 `solved`，不是 `gap`**。存在性层面新颖性 = 0；且张力定义不唯一 → `IsMinimal` 失败。结论：TCM-0 在 ℕ 上是**设计选择 / 记号**，非被迫对象，不得宣称发现。
- **转向 canonicity**：真正可能升级为「发现」的缺口是 **`O-TCM-canon`（ℂ）**——要求张力由 ζ 结构强制、Re=1/2 为唯一最大收敛轨迹；裸 ℂ 域/拓扑不强制此性质，唯 ζ 强制之。已写入页面与 `current-status.md`。
- **纪律价值**：本步避免了 NODS 黑名单第 1 条（把可解需求当缺口），保护了「发明」不被误认为「发现」。

## [2026-09-08] 论文顶刊标准扩写 | 双语发布 EN v1.2 / ZH v1.1（aiXiv，无 EAS）

- **顶刊标准扩写（leo 要求）**：内容从 436 行扩到 EN 855 / ZH 714 行。阅读流重排（摘要独立成文、主结果前置、路线图）、详略重分配（该详处：配方法/Cardano 替换推导、每定理 What-it-says+策略段、数字展览表 tab:exhibit、分支隐藏挠的 Remark、图引导段与新 caption；该略处：删模板残留、剪掉与后续工作重复的边界句）。新增：引言重写 + 相关工作子节、两条推论（cor:rootset-coset / cor:p-inj-Rpos）、后续工作节（复根全貌/形式化 Galois 墙/混合塔补齐/区间法数值根式——均声明未完成）。数学简洁性保持：不发明新定理，\Lean 标识符全部真实存在。
- **Skill 落库**：`topjournal-math-paper`（顶刊写作标准：single-pass 阅读流、重点分层、详略规则、自查清单、配子智能体扩写工作流）——以后写论文照此标准。
- **发布（版本更新，按新规无 EAS）**：
  - aiXiv EN：`aixiv.260907.000001` v1.1 → **v1.2**（id 1461，Under Review，public）——扩写版 PDF + 新摘要。
  - aiXiv ZH：`aixiv.260908.000008` v1.0 → **v1.1**（id 1462，Under Review，public）——中文镜像同步扩写。
  - 元数据模板两版摘要已同步（`aixiv_meta_radical_{en,zh}.json`）。
  - EAS 自本版本起停用（leo 决定：成本过高）；历史 attestation 记录保留在 `~/.hermes/eas-bind/README.md` 与旧 wiki 条目。

## [2026-09-07] 计算层 v3 | 任意次开方（∀n）+ 论文双语发布 EN v1.1 / ZH v1.0

- **计算层 v3（任意次开方）**：Radical.lean 新增 `nthrootR n x := e^{(ln x)/n}`（ℝ₊ 的 n 次开方）与三条 ∀n 定理——`nthrootR_pow`（(⁽ⁿ⁾√x)ⁿ=x）、`pow_inj_on_Rpos`（ℝ₊ 上 pₙ 对任意 n 单值 = μₙ 平凡塌缩的 ∀n 形式）、`nthrootR_eq_of_pow`（a>0 ∧ aⁿ=x ⟹ a=⁽ⁿ⁾√x，单值逆）。同一定理覆盖 √（n=2）、∛（3）、⁵√（5）与任意 n：示例 `(nthrootR 5 32)^5 = 32`、`nthrootR 5 (2^5) = 2`、∛27、√9、`a^7 = 128 ⟹ a = ⁷√128`。0 sorry 0 warning，`lake build` 全绿。
- **论文扩展（中英双版）**：新增 Theorem（任意次开方）——纯开方无次数上限（对每个 n 同时成立，非 n→∞ 极限）；五次之墙是**混合塔**之墙（一般五次逃出根式塔，Abel–Ruffini），纯根式民主。摘要/结论/边界措辞同步；`aixiv_meta_radical_en.json` 摘要刷新，新建 `aixiv_meta_radical_zh.json`。
- **发布（双语）**：
  - aiXiv EN：`aixiv.260907.000001` v1.0 → **v1.1**（id 1459，Under Review，public）——含任意次开方的新 PDF + 新摘要；v1.0 保留。
  - aiXiv ZH（新）：`aixiv.260908.000008` v1.0（id 1460，Under Review，public），标题《被逼出的真实结构：如何把幂与开方劈开》。
  - EAS 主网（schema #405）：EN v1.1 UID `0xd808138983bda69edc418ee6d3dc30a0eb8f634b924a705eda89031d64a7ea68`（CID `QmVgDR916EHoNFb3rg3W4EdDNkmR1hRLDJarJqyhGZcLGj`）；ZH v1.0 UID `0x042a1ee3a44f8e0aef91627b70db72b68781a515378bf4d4ca00381d686f2faa`（CID `QmRnfwEUo3LE7qpzu5AnAwvmLomdoUNpAvwocnrtzac3Ed`）。链上 getAttestation 验证通过；台账 `~/.hermes/eas-bind/README.md` 已记录。

## [2026-09-07] 论文发表 | radical EN 上 aiXiv + 以太坊 EAS 锚定

- **aiXiv 预印本**：`aixiv.260907.000001` v1.0（submission 1445，Under Review，CC-BY-4.0，is_public=1，authorship_type=human）；公开记录署名「元杰 刘」/ ~User52。
  - 标题：*The radical as a forced structure: how to split powers from radicals*
  - 摘要已同步论文当前版（含 Cardano 三次推进段）；元数据模板 `paper/radical/aixiv_meta_radical_en.json` 留档供后续版本更新。
- **以太坊 EAS 主网锚定**（照黎曼论文流程，`eas-bind-paper.js`，复用 schema #405）：
  - Attestation UID: `0x5e52a523299a348fd61f2264ac735e6bbfd5ecc439c35718432aa5791d53e05d`
  - 验证: https://easscan.org/attestation/view/0x5e52a523299a348fd61f2264ac735e6bbfd5ecc439c35718432aa5791d53e05d
  - 绑定: IPFS CID `QmVQDR2MT2fGKkAeUhKTjTmg9boqAnFiaSoMAfdHTys7Ec`（本地 Kubo pin）+ 标题 + sha256 `d0ddbafc…e15c9`；recipient `0xb4e9dCF79055A8232670ebb1c8c664Dff4E70066`
- 发布对象 = 计算层 v2（Cardano 三次）落码后的 EN 论文版（2026-09-07 重编译，tex 含新增 thm:cubic）。

## [2026-09-07] 计算层 v2 | Cardano 三次根式解

- **三次 Cardano**（`Nods/Theories/Radical.lean` 计算层 v2）：`x³+px+q=0`，判别式 ≥0 时构造性给根。
  - `cube_surj`：先证实数立方满射（IVT 于 `[0,max 1 √y]`，负数走对称）——这是 ∛ 的存在性半边；
  - `cardano_certificate`：纯代数证书（u³、v³ 方程 + uv = −p/3 ⟹ u+v 是根）；
  - `vcube`：v := −(p/3)/u 技巧自动满足 v³ = −q/2 − s（v 不能独立开方，否则 u·v 差三次单位根——挠第三次出场）；
  - 示例 `x³−3x+2=0`（判别式 0）有实根。
- 全仓 `lake build` 绿（0 错误 0 警告 0 sorry）；边界注明：五次及以上一般无根式解（Abel–Ruffini，待后续）。

## [2026-09-07] 计算层 v1 | 通用二次根式 solver + 主链 0 警告

- **通用二次根式 solver**（`Nods/Theories/Radical.lean` 计算层 v1）：示范 φ 升级为任意 `x²−bx−c=0`。判别式 ≥0 → 根式公式 `(b±√(b²+4c))/2` 机器验证为解（`quadRootPlus_sq`/`quadRootMinus_sq`）+ 多项式分解证书 `quadFactor`（无其他根）；判别式 <0 → `quad_no_roots` 证无实根；判据合成 `quad_solvable_iff`。含可算示例 `quadRootPlus 2 3 = 3`。
- **主链警告清零（0 警告 0 sorry）**：Verdict/Engine 三定理 `omit [Biframed T T']`（omit 须在 docstring 之前）；Engine 两处未用绑定改名 `_h`/`_d`；Algebraic 六个 Refinement 实例去掉未用 `{α}`。
- 全仓 `lake build` 绿；AGENTS.md 已加 §5 commit 门禁（wiki 校验前置）。

## [2026-09-07] Radical：幂 vs 开方 | 形式化 + 计算层 v0

- **新文件 `Nods/Theories/Radical.lean`**（已接主链 `Nods.lean`）：把「开方 ≠ 分数次幂」的区分落成三条**完整证明**（0 sorry）：
  - `powMap_ker_eq_nRoots` —— 幂映射 `x ↦ xⁿ` 的核 = n 次单位根群 μₙ；
  - `powMap_fiber_iff` —— `zⁿ = xⁿ ⟺ z ∈ x·μₙ`（纤维 = 陪集）；
  - `powMap_injective_iff_nRoots_trivial` —— 幂单射 ⟺ μₙ 平凡（塌缩条件）。
- **数学结论**：开方与幂的区分在**挠**（μₙ）上——幂是「按 μₙ 折叠」的商（epi），开方是「把覆盖撑开」的截面（mono）；旧图景（ℝ₊ 无挠）把开方压成"幂的倒数指数"。
- **计算层 v0**（同文件）：形式化地"解释一个数"，四条函数族给不同公式——幂 `5² = 25`、开方 `Nat.sqrt 25 = 5`（ℕ 可算）；`¬∃n:ℕ, n²=2`、`¬∃q:ℚ, (q:ℝ)²=2`（幂解释不了 2 → 逼出根式对象）；开方解可解公式 `φ = (1+√5)/2` 且机器验证 `φ² = φ+1`；指数/对数 `e^(ln 2) = 2`、`e^(ln 3) = 3` 与根式路径公式不同。
- **示意图**：`docs/figures/root_vs_power.png`（幂折叠 vs μ₄ 正方形），脚本 `scripts/plot_root_vs_power.py`，已登记 `manifests/raw_sources.csv`（src-fig-001）。

## [2026-09-04] 修通 N→Z→Q→R→C 全链 | 证成义务 O2

- **修通整条数系扩张链**：`lake build` 从失败变全绿（6 核心层 + 4 实例全部编译通过，Lean v4.21.0）。
- **核心纠错**：删除两个假命题 `no_commRing_on_nat`（¬ Nonempty (CommRing ℕ)）与 `no_field_on_int`（¬ Nonempty (Field ℤ)）。它们**不可能证出**——可数等势（ℕ≃ℤ、ℤ≃ℚ）可沿双射用 `Equiv.commRing`/`Equiv.field` 搬运结构。真正的 gap 在 `HasSolution` 的 `hstr`（`forgetStr s' = S.str`）匹配约束上；三个 `*_gap` 定理统一改为用 `hstr` 转移结构等式，再交给 `omega`/`nlinarith` 收尾。
- **`LOF` 重建**：mathlib 已弃用捆绑类 `LinearOrderedField`，改为自定义结构 `LOF`（`Field` + `LinearOrder` + `IsStrictOrderedRing`），`Nods/Theories/Algebraic.lean` 同步改。
- **修复各实例**：`NatToInt`（emb_inj 用 `Nat.cast_injective`、`natToInt_minimal` 补实例）、`IntToRat`（`int_gap` 用 `hstr` + `int_no_half`、同态唯一性用 `RingHom.ext_rat`）、`RatToReal`（`rat_no_sqrt_two`/`rat_not_dedekind_complete`/`real_cut_generated` 分析证明）、`RealToComplex`（`demandSqrtNegOne`/`real_gap`/`complexLift`/`realToComplex_minimal`）、`Chain`（删重复的 `AnyWorld`/`packWorld` + noncomputable）。
- **证成义务 O2**：`lofLinearOrder_eq_rat`（ℚ 有序域结构唯一）从 `axiom` 改为 `theorem`。关键：`IsStrictOrderedRing` 只给严格单调（不给 `IsOrderedRing` 的 `div_nonneg`），故非负方向用 `le_iff_lt_or_eq` 拆成 `= 0` 与 `> 0` 两路，走 `div_pos_iff_of_pos_right`；同时需显式 `letI` 覆盖 `LE`/`LT`/`Preorder`/`PartialOrder`（全局 `Rat.instLE` 等直接实例会压过局部序）。
- **剩余义务 O1**：`real_initiality_obligation`（R 初始性，约 80 行 Dedekind 分析）仍为 `axiom`，推迟 v0.2。

## [2026-09-04] 初始化 | bootstrap 知识系统

- 用「维基 llm」v2.0.0 bootstrap 出 `docs/wiki/` + `manifests/` + `scripts/` + 平台配置。
- 项目名：NODS — New Object Discovery System（Lean 4 + mathlib 数学对象发现系统）。
- 将 5 个 wiki 页升级到 `schema_version: 2` 并填充真实内容（项目概览 / 当前状态 / 资料索引 / 运行时 / 版本策略）。
- 登记 5 条原始素材进 `manifests/raw_sources.csv`（design.md、skill.md、Core/Instances/Theories 源码）。
- `.gitignore` 补充忽略 `.lake/`（Lake 构建产物）。
- 发现并记录关键缺口：`Nods/Instances/RealToComplex.lean`（R→C）为空，次优下一步。
