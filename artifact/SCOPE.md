# Artifact scope — 本文用到的代码边界

论文 `paper/forced-objects/` 的 artifact **只包含**下面这些路径。仓库其余部分（PU-12 宇宙模拟、
GPU 部署脚本、wiki、其它论文）与本文无关，不应随 artifact 分发。

## 包含

```
lakefile.pinned.toml          # pin 到具体 Mathlib commit 的构建文件
lean-toolchain                # Lean v4.35.0
lake-manifest.json            # 工作副本的依赖清单（CI 会重新生成）
Nods.lean                     # 主链（import 全部模块）
Nods/Core/                    # Framework, Demand, Verdict, Minimal, Score, Engine
Nods/Instances/               # NatToInt, IntToRat, RatToReal, RealToComplex
Nods/Chain.lean               # 四步轨迹（StepReport，分数为手填）
Nods/Theories/Algebraic.lean  # CS ⊇ CR ⊇ FL ⊇ LOF
Nods/Theories/Radical.lean    # 幂 / 开方（论文第 7.1 节）
Nods/Theories/Tension.lean    # 计数层（含 native_decide，论文只在方法里提到）
Nods/Theories/TensionReading.lean
Nods/Theories/TensionAbstract.lean
Nods/Theories/TensionCarriers.lean
Nods/Theories/Vibration.lean  # 振动坐标（论文第 7.3 节）
paper/forced-objects/         # 论文源码、PDF、审计记录、投稿元数据
```

## 不包含（仓库里存在，但与本论文无关）

```
scripts/pu12_*.py, run_*.sh, logs_*/     # 宇宙模拟（另一项工作）
deploy/                                  # GPU 部署
docs/wiki/                               # 项目 wiki
paper/radical/, paper2/ 等                # 其它论文
scripts/*.py 中的 wiki / ingest 工具
```

理由：artifact 的作用是让审稿人重建论文里的数字与证明，不是交付整个项目。混进模拟代码和内网
部署记录会让人无法判断哪些结果属于本文，也会带来不必要的安全暴露。

## 构建

```bash
cp lakefile.pinned.toml lakefile.toml
rm -f lake-manifest.json
lake update
lake exe cache get
lake build Nods
```

信任基底（论文附录 A）：

```bash
grep -rn "^axiom " Nods/          # 应只有 real_initiality_obligation
grep -rn "native_decide" Nods/    # Tension.lean / TensionCarriers.lean
grep -rn "sorry" Nods/            # 只应命中注释
```

## 导出

```bash
bash scripts/export_artifact.sh            # 输出到 artifact/dist/
```

`artifact/dist/` 已被 `artifact/.gitignore` 忽略，不会进版本库。
