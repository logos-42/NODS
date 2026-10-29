#!/usr/bin/env python3
"""Mini Universe —— 导出并发布到 HuggingFace（leo，2026-10-29）

把 Mini Universe（mini 宇宙）v3.3 的可学习部分（一张 480×6 的聚合 Q 表策略）连同
模拟/评测代码、模型卡，打包成一个 HuggingFace **Model 仓库**。

用法：
  # 仅本地生成发布包（不推送）
  python3 publish_pu12_v33_hf.py --stage hf_mini_universe

  # 推送（需要 HF 凭据：export HF_TOKEN=... 或已 huggingface-cli login）
  HF_TOKEN=xxx python3 publish_pu12_v33_hf.py --stage hf_mini_universe \
      --repo logos42/mini-universe --upload

  # 直接复用已有权重（跳过训练，仅改名字/模型卡时）
  HF_TOKEN=xxx python3 publish_pu12_v33_hf.py --weights /tmp/hf_pu12_v33/model.safetensors \
      --stage hf_mini_universe --repo logos42/mini-universe --upload

模型本质（诚实说明）：Mini Universe 不是标准 transformer，而是一个自定义宇宙模拟器 + 表格 Q-Learning。
可发布权重的就是「聚合 Q 表」（N_STATE=480 网格状态 × N_ACT=6 动作，被所有实体共享的平均策略）。
仓库里附 scripts/pu12_v33.py 与 pu12_v33_mirror.py（模拟与评测），可直接加载复现。
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import torch

from pu12_v33_mirror import (run, Lattice, Learners, N_STATE, N_ACT, N_BANDS,
                             FLOOR_LOG10, CEIL_LOG10, DECADES_PER_BAND)


def aggregate_q(L: Learners) -> torch.Tensor:
    """把逐实体的 (B,480,6) Q 表聚合成单一 (480,6) 平均策略（按访问次数加权）。"""
    w = L.N.sum(dim=0)  # (480,6)
    q = (L.Q * L.N).sum(dim=0) / w.clamp(min=1e-9)
    return q.to(torch.float32)


def load_q_weights(path: str) -> torch.Tensor:
    """从已有权重文件加载聚合 Q 表（跳过训练）。"""
    if path.endswith(".safetensors"):
        from safetensors.torch import load_file
        return load_file(path)["q_table"].float()
    ck = torch.load(path, map_location="cpu")
    return ck["q_table"].float()


def train_policy(B, device, seed, train_ticks, goal_k):
    u = Lattice(B, device, seed=seed)
    L = Learners(B, device)
    gen = torch.Generator().manual_seed(seed + 1)
    t0 = time.time()
    _, ticks, purpose_tick = run(u, L, gen, train_ticks, "goal", goal_k=goal_k, learn=True)
    q = aggregate_q(L)
    cov, cov_tot = L.coverage()
    print(f"[publish] trained goal={goal_k} B={B} ticks={ticks} purpose_tick={purpose_tick} "
          f"coverage={cov}/{cov_tot} q_abs_mean={float(q.abs().mean()):.3f} ({time.time()-t0:.0f}s)",
          flush=True)
    return q, {"purpose_tick": purpose_tick, "coverage": cov, "coverage_tot": cov_tot,
              "ticks": ticks}


def write_config(out: Path, args, meta):
    cfg = {
        "model_type": "mini_universe_q_policy",
        "model_name": "Mini Universe",
        "n_bands": N_BANDS,
        "n_state": N_STATE,
        "n_act": N_ACT,
        "floor_log10": FLOOR_LOG10,
        "ceil_log10": CEIL_LOG10,
        "decades_per_band": DECADES_PER_BAND,
        "trained_goal_band": args.goal_k,
        "trained_ticks": args.train_ticks,
        "trained_entities": args.B,
        "seed": args.seed,
        "framework": "pytorch",
        "task": "frequency-band navigation: reach target band then dwell (table Q-learning)",
        "train_meta": meta,
    }
    (out / "config.json").write_text(json.dumps(cfg, ensure_ascii=False, indent=2))


def write_weights(out: Path, q: torch.Tensor):
    try:
        from safetensors.torch import save_model, save_file
        save_file({"q_table": q}, str(out / "model.safetensors"))
        print("[publish] wrote model.safetensors (safetensors)", flush=True)
    except Exception as e:  # 退回 torch 格式
        torch.save({"q_table": q}, str(out / "pytorch_model.bin"))
        print(f"[publish] safetensors unavailable ({e}); wrote pytorch_model.bin", flush=True)


INFERENCE_PY = '''#!/usr/bin/env python3
"""加载 PU-12 v3.3 发布的聚合 Q 表，在无训练情况下评测策略能否够到目标带。

用法：
  python3 inference.py --goal-k 10 --device cpu
"""
import argparse, json, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import torch
from pu12_v33_mirror import run, Lattice, Learners

def load_q(path):
    if path.endswith(".safetensors"):
        from safetensors.torch import load_file
        return load_file(path)["q_table"].float()
    ck = torch.load(path, map_location="cpu")
    return ck["q_table"].float()

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--weights", default="model.safetensors")
    ap.add_argument("--goal-k", type=int, default=10)
    ap.add_argument("--B", type=int, default=1024)
    ap.add_argument("--device", default="cpu")
    ap.add_argument("--max-ticks", type=int, default=40000)
    args = ap.parse_args()
    q = load_q(args.weights)  # (480,6)
    u = Lattice(args.B, args.device, seed=0)
    L = Learners(args.B, args.device)
    # 把聚合策略广播到所有实体，并令访问计数很大 -> 纯贪心（无探索）
    L.Q[:] = q.unsqueeze(0)
    L.N[:] = 1e9
    _, ticks, purpose_tick = run(u, L, torch.Generator().manual_seed(1),
                                args.max_ticks, "goal", goal_k=args.goal_k, learn=False)
    reached = purpose_tick is not None
    print(json.dumps({"goal_k": args.goal_k, "reached": reached,
                      "ticks": ticks, "purpose_tick": purpose_tick,
                      "band_mean": float(u.band.double().mean())}, ensure_ascii=False))

if __name__ == "__main__":
    main()
'''


README_MD = '''---
license: mit
tags:
- reinforcement-learning
- table-q-learning
- physics-simulation
- custom-simulator
- frequency-bands
library_name: other
---

# Mini Universe — Frequency-Band Navigation Q-Policy

A small, honest artifact from the **Mini Universe** (mini 宇宙) simulator — a custom
multi-agent "expanding lattice" world, *not* a transformer/LLM. The only learned
parameters are a **single aggregated Q-table of shape `(480, 6)`** — 480 grid states
× 6 actions, shared across all agents. This is the "model" that is published here.

## What it is

- **World**: each agent occupies a multi-layer lattice address and chooses among
  6 actions (wait / frequency-up / frequency-down / expand-sub / expand-subs / refine)
  to navigate a logarithmic frequency axis split into `20` bands (floor `1e-19 Hz`,
  ceiling `1e81 Hz`, 5 decades per band).
- **Learning**: tabular Q-learning with UCB exploration and annealing, trained to
  reach a target frequency band and then dwell there.
- **Weights**: `model.safetensors` contains `q_table` `(480, 6)` — the policy
  averaged across agents (weighted by visit counts). This repository's checkpoint
  was trained for the goal **band 10** (see `config.json`).

## Files

- `model.safetensors` / `pytorch_model.bin` — the aggregated Q-table.
- `config.json` — hyperparameters (bands, state/action dims, trained goal & ticks).
- `pu12_v33.py` — the universe simulator (main loop, v3.3).
- `pu12_v33_mirror.py` — the training/evaluation driver (`run`, `Lattice`, `Learners`)
  and the benchmark probes.
- `inference.py` — load the Q-table and evaluate (greedy, no training) whether the
  policy reaches a target band.

## Load & evaluate

```bash
pip install torch
python3 inference.py --goal-k 10 --device cpu
# -> {"goal_k":10,"reached":true,"ticks":...,"purpose_tick":...,"band_mean":...}
```

To retrain / reproduce, run `python3 pu12_v33_mirror.py --B 1024 --train-ticks 80000
--goal-k 10 --device cpu` (writes `logs_mirror/benchmark.json`).

## Benchmark (honest)

A mirrored small-world benchmark scored **0.62 / 1.0**: strong task learning and
perfect internal energy conservation, but **no positive transfer** between goals
(negative few-shot plasticity — catastrophic interference) and no language-level
structure in action sequences. See the companion `current-status.md` / `log.md`
in the source repo (github.com/logos-42/NODS) for the full write-up. Published as
a reproducible baseline, not as a claim of general intelligence.
'''


LICENSE_TXT = '''MIT License

Copyright (c) 2026 the Mini Universe authors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
'''


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--B", type=int, default=1024)
    ap.add_argument("--device", default="cpu")
    ap.add_argument("--seed", type=int, default=0)
    ap.add_argument("--train-ticks", type=int, default=80000)
    ap.add_argument("--goal-k", type=int, default=10)
    ap.add_argument("--stage", default="hf_mini_universe")
    ap.add_argument("--repo", default="logos42/mini-universe")
    ap.add_argument("--weights", default=None,
                    help="加载已有 q_table（.safetensors/.bin）跳过训练，仅改名字/模型卡时")
    ap.add_argument("--upload", action="store_true", help="需要 HF_TOKEN 或已登录")
    ap.add_argument("--private", action="store_true")
    args = ap.parse_args()

    out = Path(args.stage); out.mkdir(parents=True, exist_ok=True)
    if args.weights:
        q = load_q_weights(args.weights)
        meta = {"loaded_from": args.weights}
        print(f"[publish] loaded weights from {args.weights}", flush=True)
    else:
        q, meta = train_policy(args.B, args.device, args.seed, args.train_ticks, args.goal_k)
    write_weights(out, q)
    write_config(out, args, meta)

    # 复制模拟/评测代码
    here = Path(__file__).resolve().parent
    for f in ("pu12_v33.py", "pu12_v33_mirror.py"):
        import shutil
        shutil.copy(here / f, out / f)
    (out / "inference.py").write_text(INFERENCE_PY)
    (out / "LICENSE").write_text(LICENSE_TXT)
    (out / "README.md").write_text(README_MD)
    print(f"[publish] staged repo at {out}/ : "
          f"{sorted(p.name for p in out.iterdir())}", flush=True)

    if args.upload:
        token = os.environ.get("HF_TOKEN")
        try:
            from huggingface_hub import HfApi, HfFolder
            token = token or HfFolder.get_token()
        except Exception:
            token = token
        if not token:
            print("[publish] 未找到 HF 凭据（HF_TOKEN 或 huggingface-cli login）。跳过上传。", flush=True)
            return 0
        from huggingface_hub import HfApi
        api = HfApi(token=token)
        api.create_repo(repo_id=args.repo, repo_type="model", exist_ok=True, private=args.private)
        api.upload_folder(repo_id=args.repo, folder_path=str(out), repo_type="model")
        print(f"[publish] uploaded -> https://huggingface.co/{args.repo}", flush=True)
    else:
        print("[publish] 未上传（--upload 未设）。需要时用 HF_TOKEN=... python3 publish_pu12_v33_hf.py --upload",
              flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
