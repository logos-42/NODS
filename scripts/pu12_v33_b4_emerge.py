#!/usr/bin/env python3
"""b4/b5 —— 自发涌现测试 + 最小归纳偏置搜索（突破方向 1 & 2，可接龙）

核心问题：不给人工相对表征，网络能否**自己发现** rel = band − goal 的抽象？
观测 = onehot(绝对band) ⊕ onehot(目标) ⊕ [满充, 已达成]——相对结构可表示但未被标注。

--pressure 三种条件（方向 2 的「最小压力搜索」）：
  vanilla  纯 TD/回归压力（方向 1：裸涌现测试）
  aux      +辅助头：强制隐层线性预测 (band−goal)/10（显式结构压力）
  her      +经验回放 & 目标重标注（多目标经验共享压力；重算奖励用 mirror._reward_goal）

判定探针（对所有 20×20 (band,goal) 状态、full=1/achieved=0）：
  rel_cons —— 按 rel=band−goal 分组的组内 Q 余弦相似（→1 = 发现相对抽象）
  abs_cons —— 按 band 分组对照（相对结构下应显著更低）
  涌现判据（链驱动用）：连续两轮 rel_cons − abs_cons ≥ 0.2

用法：
  python3 pu12_v33_b4_emerge.py --pressure vanilla --B 4096 --device cuda --out logs_chain/b4_vanilla
  python3 pu12_v33_b4_emerge.py --B 64 --device cpu --seg-ticks 300 --eval-every 2 \
      --eval-budget 300 --max-seconds 8 --out /tmp/b4s   # 冒烟
"""
import argparse
import copy
import json
import time
from pathlib import Path

import torch
import torch.nn as nn
import torch.nn.functional as F

from pu12_v33 import Lattice, Learners, N_BANDS, N_ACT, CELLS
import pu12_v33_mirror as mirror

SCHED = [18, 15, 12, 8, 5, 10]
EVAL_GOALS = [5, 8, 10, 12, 15, 18]
OBS_DIM = N_BANDS * 2 + 2  # onehot(band) + onehot(goal) + full + achieved


class QNet(nn.Module):
    """MLP 主干 + Q 头；aux 条件下附加 (band−goal) 回归头（辅助压力的载体）。"""

    def __init__(self, hidden=64, aux=False):
        super().__init__()
        self.l1 = nn.Linear(OBS_DIM, hidden)
        self.l2 = nn.Linear(hidden, hidden)
        self.q = nn.Linear(hidden, N_ACT)
        self.aux = nn.Linear(hidden, 1) if aux else None

    def trunk(self, obs):
        h = F.relu(self.l1(obs))
        return F.relu(self.l2(h))

    def forward(self, obs):
        return self.q(self.trunk(obs))


class _ShimU:
    """HER 重标注用的轻量宇宙替身：只带 _reward_goal 用到的 band/g/e。"""

    def __init__(self, band, g, device):
        self.band = band
        self.g = g
        self.e = torch.ones(band.shape[0], device=device)


class NeuralLearners(Learners):
    """与 Learners 接口兼容（act/learn_from），Q 由共享 MLP 参数化。

    cur_goal 由驱动方每段设置；goal 只是观测的一个分量，如何使用由网络自己决定。
    """

    def __init__(self, B: int, device: str, lr: float = 1e-3, hidden: int = 64,
                 anneal: int = 4000, pressure: str = "vanilla", replay_ticks: int = 2000,
                 her_every: int = 1, her_batch: int = 8192, aux_lambda: float = 1.0):
        assert pressure in ("vanilla", "aux", "her")
        self.device = device
        self.pressure = pressure
        self.net = QNet(hidden, aux=(pressure == "aux")).to(device)
        self.opt = torch.optim.Adam(self.net.parameters(), lr=lr)
        self.anneal = anneal
        self.cur_goal = 10
        self.n_updates = 0
        self.aux_lambda = aux_lambda
        if pressure == "her":  # 环形回放：band/act/full/ach/goal 各 1 字节/实体/tick
            self.ring = {k: torch.zeros(replay_ticks, B, dtype=torch.uint8)
                         for k in ("band", "act", "full", "ach", "goal")}
            self.ring_i = 0
            self.ring_n = 0
            self.her_every = her_every
            self.her_batch = her_batch

    def _obs(self, s: torch.Tensor, goal: int) -> torch.Tensor:
        band = (s >> 2).long()
        full = (s & 1).float().unsqueeze(1)
        ach = ((s >> 1) & 1).float().unsqueeze(1)
        g = torch.full_like(band, int(goal))
        return torch.cat([F.one_hot(band, N_BANDS).float(),
                          F.one_hot(g, N_BANDS).float(), full, ach], dim=1)

    def act(self, u: Lattice, s: torch.Tensor, explore: float, learn: bool, t: int,
            greedy: bool = False) -> torch.Tensor:
        with torch.no_grad():
            q = self.net(self._obs(s, self.cur_goal))
        if greedy:
            return q.argmax(dim=1)
        if not learn:
            return torch.randint(0, N_ACT, (u.B,), device=u.device)
        act = q.argmax(dim=1)
        eps = explore / (1.0 + t / self.anneal)
        if eps > 0:
            hit = torch.rand(u.B, device=u.device) < eps
            act = torch.where(hit, torch.randint(0, N_ACT, (u.B,), device=u.device), act)
        return act

    def learn_from(self, s, a, r, learn):
        if not learn:
            return
        obs = self._obs(s, self.cur_goal)
        self._regress(obs, a, r)
        if self.pressure == "her":
            self._ring_push(s, a)
            self._her_step()
        self.n_updates += 1

    def _regress(self, obs, a, r):
        q = self.net(obs)
        pred = q.gather(1, a.unsqueeze(1)).squeeze(1)
        loss = F.mse_loss(pred, r.float())
        if self.pressure == "aux" and self.net.aux is not None:
            band = obs[:, :N_BANDS].argmax(dim=1).float()
            goal = obs[:, N_BANDS:2 * N_BANDS].argmax(dim=1).float()
            h = self.net.trunk(obs)
            loss = loss + self.aux_lambda * F.mse_loss(
                self.net.aux(h).squeeze(1), (band - goal) / 10.0)
        self.opt.zero_grad()
        loss.backward()
        self.opt.step()

    @torch.no_grad()
    def _ring_push(self, s, a):
        band = (s >> 2).to(torch.uint8)
        i = self.ring_i
        self.ring["band"][i].copy_(band)
        self.ring["act"][i].copy_(a.to(torch.uint8))
        self.ring["full"][i].copy_((s & 1).to(torch.uint8))
        self.ring["ach"][i].copy_(((s >> 1) & 1).to(torch.uint8))
        self.ring["goal"][i].fill_(int(self.cur_goal))
        self.ring_i = (i + 1) % self.ring["band"].shape[0]
        self.ring_n = min(self.ring_n + 1, self.ring["band"].shape[0])

    def _her_step(self):
        n = self.ring_n
        if n == 0:
            return
        B = self.ring["band"].shape[1]
        idx = torch.randint(0, n * B, (self.her_batch,), device=self.device)
        t, e = idx // B, idx % B
        band = self.ring["band"][t, e].long().to(self.device)
        act = self.ring["act"][t, e].long().to(self.device)
        full = self.ring["full"][t, e].long().to(self.device)
        goal_old = self.ring["goal"][t, e].long().to(self.device)
        # 目标重标注：50% 保留原目标，50% 均匀换随机目标（多目标经验共享）
        goal_new = torch.where(torch.rand_like(goal_old.float()) < 0.5, goal_old,
                               torch.randint(0, N_BANDS, goal_old.shape, device=self.device))
        # 由 (band, act, full) 重推动作结果旗标（与 mirror.run 语义一致）
        at_top = band == N_BANDS - 1
        up = act == 1
        up_ok = up & (full == 1) & ~at_top
        up_fail = up & ~up_ok
        dn = act == 2
        exp_sub = (act == 3) & (full == 1)
        exp_subs = (act == 4) & (full == 1)
        ref_fine = (act == 5) & (full == 1)
        shim = _ShimU(band, torch.where(full == 1, float(CELLS), 0.0).to(self.device),
                      self.device)
        r = mirror._reward_goal(up_ok, up_fail, dn, exp_sub, exp_subs, ref_fine,
                                shim, goal_new, False)  # achieved 恒 False（重标注近似）
        s_re = band * 4 + full  # achieved=0
        obs = torch.cat([F.one_hot(band, N_BANDS).float(),
                         F.one_hot(goal_new, N_BANDS).float(),
                         full.float().unsqueeze(1),
                         torch.zeros(band.shape[0], 1, device=self.device)], dim=1)
        self._regress(obs, act, r)


@torch.no_grad()
def probe_representation(L: NeuralLearners) -> dict:
    """核心探针：网络是否自发收敛到 rel = band − goal 的抽象。"""
    bands = torch.arange(N_BANDS, device=L.device)
    goals = torch.arange(N_BANDS, device=L.device)
    bg, gg = torch.meshgrid(bands, goals, indexing="ij")
    band_f, goal_f = bg.reshape(-1), gg.reshape(-1)
    obs = torch.cat([F.one_hot(band_f, N_BANDS).float(),
                     F.one_hot(goal_f, N_BANDS).float(),
                     torch.ones(N_BANDS * N_BANDS, 1, device=L.device),
                     torch.zeros(N_BANDS * N_BANDS, 1, device=L.device)], dim=1)
    q = F.normalize(L.net(obs), dim=1)
    rel = band_f - goal_f

    def group_cons(group_id):
        sims = []
        for g in group_id.unique().tolist():
            idx = (group_id == g).nonzero(as_tuple=True)[0]
            k = idx.numel()
            if k < 2:
                continue
            sim = q[idx] @ q[idx].T
            sims.append(sim[~torch.eye(k, dtype=torch.bool, device=L.device)].mean())
        return float(torch.stack(sims).mean()) if sims else float("nan")

    rel_cons = group_cons(rel)
    abs_cons = group_cons(band_f)
    return {"rel_cons": round(rel_cons, 4), "abs_cons": round(abs_cons, 4),
            "rel_minus_abs": round(rel_cons - abs_cons, 4)}


def greedy_eval(u_ref, L_ref, gen, goal, budget, fixed_start):
    """固定起点 band=fixed_start 的零探索贪婪评估（deepcopy 隔离，不污染训练）。"""
    ue = copy.deepcopy(u_ref)
    ue.band = torch.full((ue.B,), int(fixed_start), dtype=torch.long, device=ue.device)
    ue.g = (CELLS * torch.rand(ue.B, generator=gen)).to(ue.device).double()
    ue.ever_top[:] = False
    ue.purpose_tick = -1
    ue.top_tick = -1
    Le = copy.deepcopy(L_ref)
    Le.cur_goal = int(goal)
    _, ticks, _ = mirror.run(ue, Le, gen, budget, "goal", goal_k=goal, learn=False, greedy=True)
    bm = float(ue.band.double().mean())
    dist = (ue.band - int(goal)).abs().double()
    return (bm, float((dist <= 1e-9).double().mean()),
            float((dist <= 1.0).double().mean()), int(ticks))


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--B", type=int, default=4096)
    ap.add_argument("--device", default="cuda")
    ap.add_argument("--seed", type=int, default=0)
    ap.add_argument("--seg-ticks", type=int, default=60000)
    ap.add_argument("--eval-every", type=int, default=20)
    ap.add_argument("--eval-budget", type=int, default=30000)
    ap.add_argument("--fixed-start", type=int, default=9)
    ap.add_argument("--lr", type=float, default=1e-3)
    ap.add_argument("--hidden", type=int, default=64)
    ap.add_argument("--pressure", default="vanilla", choices=["vanilla", "aux", "her"])
    ap.add_argument("--max-seconds", type=float, default=0.0)
    ap.add_argument("--out", default="logs_b/b4")
    args = ap.parse_args()

    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    seg_f = (out / "segments.jsonl").open("a")
    eval_f = (out / "evals.jsonl").open("a")
    t0 = time.time()

    u = Lattice(args.B, args.device, seed=args.seed)
    NL = NeuralLearners(args.B, args.device, lr=args.lr, hidden=args.hidden,
                        pressure=args.pressure)
    gen = torch.Generator().manual_seed(args.seed + 1)
    print(f"[B-b4/{args.pressure}] B={args.B} dev={args.device} schedule={SCHED} "
          f"seg={args.seg_ticks} eval_every={args.eval_every} fixed_start={args.fixed_start} "
          f"net=MLP({OBS_DIM}->{args.hidden}->{args.hidden}->{N_ACT},"
          f"aux={args.pressure == 'aux'})", flush=True)

    seg = 0
    cum_regret = 0.0
    while True:
        if args.max_seconds and (time.time() - t0) > args.max_seconds:
            break
        goal = SCHED[seg % len(SCHED)]
        NL.cur_goal = goal
        _, ticks, purpose = mirror.run(u, NL, gen, args.seg_ticks, "goal",
                                       goal_k=goal, learn=True)
        bm = float(u.band.double().mean())
        regret = abs(bm - goal)
        cum_regret += regret
        seg += 1
        seg_f.write(json.dumps({"seg": seg, "goal": goal, "reached": purpose is not None,
                                "ticks_used": int(ticks), "band_mean": round(bm, 3),
                                "regret": round(regret, 3), "cum_regret": round(cum_regret, 1),
                                "updates": NL.n_updates,
                                "wall_s": round(time.time() - t0, 1),
                                "B": args.B, "mode": f"b4/{args.pressure}"}) + "\n")
        seg_f.flush()

        if seg % args.eval_every == 0:
            row_res = {}
            for eg in EVAL_GOALS:
                bm_e, fe, fc, et = greedy_eval(u, NL, gen, eg, args.eval_budget,
                                               args.fixed_start)
                row_res[eg] = (round(bm_e, 2), round(fc, 2), et)
                eval_f.write(json.dumps({"seg": seg, "goal_eval": eg,
                                         "band_mean": round(bm_e, 3),
                                         "frac_exact": round(fe, 3),
                                         "frac_close": round(fc, 3), "ticks": et,
                                         "wall_s": round(time.time() - t0, 1),
                                         "mode": f"b4/{args.pressure}"}) + "\n")
            acc_close = sum(v[1] for v in row_res.values()) / len(row_res)
            probe = probe_representation(NL)
            print(f"[B-b4/{args.pressure}] seg={seg} depth={u.t} "
                  f"avg_regret={cum_regret / seg:.2f} eval_acc_close={acc_close:.2f} "
                  f"probe={probe} detail={row_res}", flush=True)
            eval_f.write(json.dumps({"seg": seg, "probe": probe,
                                     "acc_close": round(acc_close, 4),
                                     "wall_s": round(time.time() - t0, 1)}) + "\n")
            eval_f.flush()
    seg_f.close()
    eval_f.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
