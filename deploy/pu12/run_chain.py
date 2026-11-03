#!/usr/bin/env python3
"""run_chain —— 突破方向 1→2→3 的无人值守接龙驱动器。

阶段与判定：
  1. b4_vanilla（自发涌现测试）  涌现 = 连续两轮 probe.rel_minus_abs ≥ 0.2
  2. b5_aux（辅助头压力）        同上；vanilla 涌现则跳过 2/3
  3. b5_her（重标注压力）        同上
  4. b6_skill（技能发现+组合）   成功 = 全部训练目标与未见目标均到达
任一阶段「涌现/成功」即停链；全部失败也停链并如实记录。
产物：logs_chain/chain_report.jsonl（逐阶段判定）+ chain_status.json（最终状态）。
方向 4（升维世界）需新模拟器，不在本链自动跑，链尾标注 pending。
"""
import json
import os
import subprocess
import sys
import time
from pathlib import Path

PY = sys.executable or "python3"
ROOT = Path(os.environ.get("CHAIN_ROOT", "/work/liuyuanjie/pu12"))
OUT = ROOT / "logs_chain"
OUT.mkdir(parents=True, exist_ok=True)
GPU = os.environ.get("CHAIN_GPU", "1")
EMERGE_DELTA = 0.2      # 涌现判据：rel_cons − abs_cons
MAX_SEGS = 120          # 每阶段段数上限（超过判失败进入下一阶段）
POLL_S = 60

STAGES = [
    {"name": "b4_vanilla", "kind": "probe",
     "cmd": [PY, "-u", "scripts/pu12_v33_b4_emerge.py", "--pressure", "vanilla",
             "--B", "4096", "--device", "cuda", "--out", str(OUT / "b4_vanilla")]},
    {"name": "b5_aux", "kind": "probe",
     "cmd": [PY, "-u", "scripts/pu12_v33_b4_emerge.py", "--pressure", "aux",
             "--B", "4096", "--device", "cuda", "--out", str(OUT / "b5_aux")]},
    {"name": "b5_her", "kind": "probe",
     "cmd": [PY, "-u", "scripts/pu12_v33_b4_emerge.py", "--pressure", "her",
             "--B", "4096", "--device", "cuda", "--out", str(OUT / "b5_her")]},
    {"name": "b6_skill", "kind": "skill",
     "cmd": [PY, "-u", "scripts/pu12_v33_b6_skill.py",
             "--B", "4096", "--device", "cuda", "--out", str(OUT / "b6_skill")]},
]


def last_seg(outdir: Path) -> int:
    f = outdir / "segments.jsonl"
    if not f.exists():
        return 0
    try:
        with f.open() as fh:
            lines = fh.readlines()
        return json.loads(lines[-1]).get("seg", 0) if lines else 0
    except Exception:
        return 0


def probe_verdict(outdir: Path):
    """涌现判定：最近两条 probe 记录 rel_minus_abs ≥ 阈值。"""
    f = outdir / "evals.jsonl"
    probes = []
    if f.exists():
        with f.open() as fh:
            for line in fh:
                try:
                    row = json.loads(line)
                except Exception:
                    continue
                if "probe" in row:
                    probes.append(row["probe"])
    info = probes[-1] if probes else None
    if len(probes) >= 2 and all(
            p.get("rel_minus_abs", -9) >= EMERGE_DELTA for p in probes[-2:]):
        return True, info
    return False, info


def skill_verdict(outdir: Path):
    f = outdir / "summary.json"
    if not f.exists():
        return False, None
    try:
        s = json.loads(f.read_text())
        return bool(s.get("all_reached")), s
    except Exception:
        return False, None


def run_stage(st, report_f, overall):
    """跑单个阶段直到涌现/成功/段数上限。"""
    name, kind, cmd = st["name"], st["kind"], st["cmd"]
    outdir = Path(cmd[-1])
    outdir.mkdir(parents=True, exist_ok=True)
    env = dict(os.environ, CUDA_VISIBLE_DEVICES=GPU,
               PYTHONPATH=os.environ.get("PYTHONPATH", "") + ":" + str(ROOT / "scripts"))
    proc = subprocess.Popen(cmd, cwd=ROOT, env=env,
                            stdout=(outdir / "stdout.log").open("a"),
                            stderr=subprocess.STDOUT)
    t0 = time.time()
    while True:
        time.sleep(POLL_S)
        rc = proc.poll()
        seg = last_seg(outdir)
        if kind == "probe":
            ok, info = probe_verdict(outdir)
        else:
            ok, info = skill_verdict(outdir)
        if ok:
            return {"stage": name, "verdict": "success", "probe": info,
                    "segs": seg, "wall_s": round(time.time() - t0, 1)}
        if rc is not None:  # 进程自己退出（如 b6 跑完或崩溃）
            ok2, info2 = (probe_verdict(outdir) if kind == "probe" else skill_verdict(outdir))
            return {"stage": name, "verdict": "success" if ok2 else f"exited(rc={rc})",
                    "probe": info2, "segs": seg, "wall_s": round(time.time() - t0, 1)}
        if seg >= MAX_SEGS:
            proc.terminate()
            time.sleep(10)
            if proc.poll() is None:
                proc.kill()
            return {"stage": name, "verdict": f"no-emergence(>={MAX_SEGS}segs)",
                    "probe": info, "segs": seg, "wall_s": round(time.time() - t0, 1)}


def main() -> int:
    report_f = (OUT / "chain_report.jsonl").open("a")
    print(f"[chain] root={ROOT} gpu={GPU} stages={[s['name'] for s in STAGES]}", flush=True)
    overall = {"emerged_stage": None, "stages": []}
    for st in STAGES:
        name = st["name"]
        outdir = Path(st["cmd"][-1])
        # 幂等：断点重启时若该阶段已有成功判定则跳过
        ok0, info0 = (probe_verdict(outdir) if st["kind"] == "probe"
                      else skill_verdict(outdir))
        if ok0:
            rec = {"stage": name, "verdict": "success(pre-existing)", "probe": info0}
            report_f.write(json.dumps(rec, ensure_ascii=False) + "\n"); report_f.flush()
            overall["stages"].append(rec)
            overall["emerged_stage"] = name
            break
        rec = run_stage(st, report_f, overall)
        rec["finished"] = time.strftime("%F %T")
        report_f.write(json.dumps(rec, ensure_ascii=False) + "\n"); report_f.flush()
        overall["stages"].append(rec)
        print(f"[chain] <== {name}: {rec['verdict']} probe={rec.get('probe')}", flush=True)
        if rec["verdict"] == "success":
            overall["emerged_stage"] = name
            break
    overall["direction4"] = "pending（升维世界需新模拟器，链外人工设计）"
    overall["finished"] = time.strftime("%F %T")
    (OUT / "chain_status.json").write_text(json.dumps(overall, ensure_ascii=False, indent=1))
    print(f"[chain] DONE emerged={overall['emerged_stage']}", flush=True)
    report_f.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
