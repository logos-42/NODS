#!/usr/bin/env python3
"""b7 —— 升维世界（突破方向 4）：二维目标 + 顺序组合目标。

W1（--task point）：状态 (x,y)，动作 5 个（等/+x/−x/+y/−y），目标 (gx,gy)。
  到达需两轴协同；相对结构是 (dx,dy) 二维对，不是单减法。
W2（--task sequence）：目标 =「先到 A，再到 B」，观测中**不给阶段位**（部分可观测）。
  此时 (dx,dy) 减法原则上不足——检验相对抽象的边界。

判定探针（与 1D 一致的可测口径）：
  rel_cons = 按 (dx,dy) 分组的 Q 余弦相似（→1 = 发现二维相对抽象）
  abs_cons = 按 (x,y) 分组对照（相对结构下应更低）

评估：固定起点 (5,5)，零探索 greedy，多目标，记精确到达率/步数；
另给「人手写相对规则」的参考上界（不学习，只用 dx,dy 选轴）。

用法：
  python3 pu12_v33_b7_world2d.py --task point --pressure her --B 4096 --device cuda --out logs_b7/w1_her
  python3 pu12_v33_b7_world2d.py --task sequence --pressure her --B 4096 --device cuda --out logs_b7/w2_her
"""
import argparse
import copy
import json
import time
from pathlib import Path

import torch
import torch.nn as nn
import torch.nn.functional as F

N = 10          # 每轴 0..N-1
N_ACT = 5       # 0 等, 1 +x, 2 −x, 3 +y, 4 −y
OBS_DIM = N * 4 + 1   # onehot(x)+onehot(y)+onehot(gx)+onehot(gy)+[dummy常量]


def onehot(v, n=N):
    return F.one_hot(v.long().clamp(0, n - 1), n).float()


class World:
    """二维离散世界。goal 可为点(点任务)或 (A,B) 序对(顺序任务)。"""

    def __init__(self, B: int, device: str, task: str, gen):
        self.B, self.device, self.task = B, device, task
        self.x = torch.randint(0, N, (B,), device=device)
        self.y = torch.randint(0, N, (B,), device=device)
        self.gx = torch.randint(0, N, (B,), device=device)
        self.gy = torch.randint(0, N, (B,), device=device)
        # sequence 任务的第二子目标
        self.g2x = torch.randint(0, N, (B,), device=device)
        self.g2y = torch.randint(0, N, (B,), device=device)
        self.phase_done = torch.zeros(B, dtype=torch.bool, device=device)
        self.gen = gen
        self.reached = torch.zeros(B, dtype=torch.bool, device=device)

    def subgoal(self):
        """当前应朝哪个子目标走（sequence: 分阶段；point: 唯一目标）。"""
        if self.task == "point":
            return self.gx, self.gy
        return (torch.where(self.phase_done, self.g2x, self.gx),
                torch.where(self.phase_done, self.g2y, self.gy))

    def obs(self):
        gx, gy = self.subgoal()
        # 注意：**不给** phase 位（部分可观测），dummy 常 0 仅为维度统一
        zero = torch.zeros_like(gx, dtype=torch.float32).unsqueeze(1)
        return torch.cat([onehot(self.x), onehot(self.y), onehot(gx), onehot(gy), zero], dim=1)

    def step(self, a):
        """返回奖励；到点后 point 任务重投放，sequence 任务推进阶段。"""
        old_d = ((self.x - self.gx).abs() + (self.y - self.gy).abs()).float()
        mx = (a == 1).long() - (a == 2).long()
        my = (a == 3).long() - (a == 4).long()
        nx = (self.x + mx).clamp(0, N - 1)
        ny = (self.y + my).clamp(0, N - 1)
        self.x, self.y = nx, ny
        gx, gy = self.subgoal()
        new_d = ((nx - gx).abs() + (ny - gy).abs()).float()
        rew = torch.where(new_d < old_d, torch.full_like(new_d, 1.0),
                          torch.where(new_d > old_d, torch.full_like(new_d, -0.3),
                                      torch.full_like(new_d, -0.05)))
        hit = (nx == gx) & (ny == gy)
        if self.task == "point":
            rew = torch.where(hit, torch.full_like(rew, 1.0), rew)
            # 重投放（保证覆盖各种相对位置）
            redrop = hit & (torch.rand(self.B, device=self.device) < 0.5)
            self.x = torch.where(redrop, torch.randint(0, N, (self.B,), device=self.device), self.x)
            self.y = torch.where(redrop, torch.randint(0, N, (self.B,), device=self.device), self.y)
            self.gx = torch.where(redrop, torch.randint(0, N, (self.B,), device=self.device), self.gx)
            self.gy = torch.where(redrop, torch.randint(0, N, (self.B,), device=self.device), self.gy)
        else:
            first = hit & ~self.phase_done
            self.phase_done = self.phase_done | first
            rew = torch.where(first, torch.full_like(rew, 2.0), rew)
            done = self.phase_done & hit & (self.x == self.g2x) & (self.y == self.g2y)
            rew = torch.where(done, torch.full_like(rew, 5.0), rew)
            # 完成后重置为新的一对
            self.phase_done = torch.where(done, torch.zeros_like(self.phase_done), self.phase_done)
            self.gx = torch.where(done, torch.randint(0, N, (self.B,), device=self.device), self.gx)
            self.gy = torch.where(done, torch.randint(0, N, (self.B,), device=self.device), self.gy)
            self.g2x = torch.where(done, torch.randint(0, N, (self.B,), device=self.device), self.g2x)
            self.g2y = torch.where(done, torch.randint(0, N, (self.B,), device=self.device), self.g2y)
        return rew


class QNet2D(nn.Module):
    def __init__(self, hidden=128):
        super().__init__()
        self.l1 = nn.Linear(OBS_DIM, hidden)
        self.l2 = nn.Linear(hidden, hidden)
        self.q = nn.Linear(hidden, N_ACT)

    def forward(self, o):
        h = F.relu(self.l1(o))
        return self.q(F.relu(self.l2(h)))


class NetLearner:
    """接口对齐 b4 的 NeuralLearners（act/learn_from），供统一训练循环复用。

    pressure: vanilla | her（her = 存 (x,y,act)，随机重标注目标后重算奖励）
    """

    def __init__(self, B: int, device: str, task: str, pressure: str = "vanilla",
                 lr: float = 1e-3, hidden: int = 128, ring_ticks: int = 2000,
                 her_batch: int = 8192):
        self.device, self.task, self.pressure = device, task, pressure
        self.net = QNet2D(hidden).to(device)
        self.opt = torch.optim.Adam(self.net.parameters(), lr=lr)
        self.anneal = 4000
        self.B = B
        self.her_batch = her_batch
        if pressure == "her":
            self.ring = {k: torch.zeros(ring_ticks, B, dtype=torch.uint8)
                         for k in ("x", "y", "act", "phase")}
            self.ring_i = 0
            self.ring_n = 0
        self.n_updates = 0

    def act(self, w: World, explore: float, learn: bool, t: int, greedy: bool = False):
        obs = w.obs()
        with torch.no_grad():
            q = self.net(obs)
        if greedy:
            return q.argmax(dim=1)
        if not learn:
            return torch.randint(0, N_ACT, (w.B,), device=w.device)
        a = q.argmax(dim=1)
        eps = explore / (1.0 + t / self.anneal)
        if eps > 0:
            hit = torch.rand(w.B, device=w.device) < eps
            a = torch.where(hit, torch.randint(0, N_ACT, (w.B,), device=w.device), a)
        return a

    def learn_from(self, w: World, obs_prev, a, r, learn):
        if not learn:
            return
        q = self.net(obs_prev)
        loss = F.mse_loss(q.gather(1, a.unsqueeze(1)).squeeze(1), r.float())
        self.opt.zero_grad(); loss.backward(); self.opt.step()
        if self.pressure == "her":
            self._ring_push(w, obs_prev, a)
            self._her_step()
        self.n_updates += 1

    @torch.no_grad()
    def _ring_push(self, w, obs_prev, a):
        # 从 obs 反解 x,y（one-hot argmax）——避免额外传参
        x = obs_prev[:, :N].argmax(dim=1)
        y = obs_prev[:, N:2 * N].argmax(dim=1)
        i = self.ring_i
        self.ring["x"][i].copy_(x.to(torch.uint8))
        self.ring["y"][i].copy_(y.to(torch.uint8))
        self.ring["act"][i].copy_(a.to(torch.uint8))
        self.ring["phase"][i].copy_(w.phase_done.to(torch.uint8))
        self.ring_i = (i + 1) % self.ring["x"].shape[0]
        self.ring_n = min(self.ring_n + 1, self.ring["x"].shape[0])

    def _her_step(self):
        n = self.ring_n
        if n == 0:
            return
        idx = torch.randint(0, n * self.B, (self.her_batch,))
        t, e = idx // self.B, idx % self.B
        x = self.ring["x"][t, e].long().to(self.device)
        y = self.ring["y"][t, e].long().to(self.device)
        act = self.ring["act"][t, e].long().to(self.device)
        gx = torch.randint(0, N, (self.her_batch,), device=self.device)
        gy = torch.randint(0, N, (self.her_batch,), device=self.device)
        # 用重标注目标重算奖励：动作的效果对任何目标都一致
        mx = (act == 1).long() - (act == 2).long()
        my = (act == 3).long() - (act == 4).long()
        nx = (x + mx).clamp(0, N - 1)
        ny = (y + my).clamp(0, N - 1)
        old_d = ((x - gx).abs() + (y - gy).abs()).float()
        new_d = ((nx - gx).abs() + (ny - gy).abs()).float()
        r = torch.where(new_d < old_d, torch.full_like(new_d, 1.0),
                        torch.where(new_d > old_d, torch.full_like(new_d, -0.3),
                                    torch.full_like(new_d, -0.05)))
        obs = torch.cat([onehot(x), onehot(y), onehot(gx), onehot(gy),
                         torch.zeros(self.her_batch, 1, device=self.device)], dim=1)
        q = self.net(obs)
        loss = F.mse_loss(q.gather(1, act.unsqueeze(1)).squeeze(1), r)
        self.opt.zero_grad(); loss.backward(); self.opt.step()


@torch.no_grad()
def probe_representation(L: NetLearner) -> dict:
    """按 (dx,dy) 分组 vs 按 (x,y) 分组的 Q 余弦一致性。"""
    xs = torch.arange(N, device=L.device)
    ax, ay, bx, by = torch.meshgrid(xs, xs, xs, xs, indexing="ij")
    xs_f = ax.reshape(-1); ys_f = ay.reshape(-1)
    gx_f = bx.reshape(-1); gy_f = by.reshape(-1)
    obs = torch.cat([onehot(xs_f), onehot(ys_f), onehot(gx_f), onehot(gy_f),
                     torch.zeros(xs_f.shape[0], 1, device=L.device)], dim=1)
    q = F.normalize(L.net(obs), dim=1)
    dx, dy = xs_f - gx_f, ys_f - gy_f

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

    rel_cons = group_cons(dx * (2 * N) + dy)
    abs_cons = group_cons(xs_f * N + ys_f)
    return {"rel_cons": round(rel_cons, 4), "abs_cons": round(abs_cons, 4),
            "rel_minus_abs": round(rel_cons - abs_cons, 4)}


@torch.no_grad()
def greedy_eval(L: NetLearner, task, goal, budget, B=4096):
    """固定起点 (5,5) 的零探索贪婪评估。goal: point=(gx,gy)；sequence=((ax,ay),(bx,by))。"""
    dev = L.device
    x = torch.full((B,), 5, device=dev)
    y = torch.full((B,), 5, device=dev)
    if task == "point":
        gx = torch.full((B,), goal[0], device=dev)
        gy = torch.full((B,), goal[1], device=dev)
        for t in range(1, budget + 1):
            obs = torch.cat([onehot(x), onehot(y), onehot(gx), onehot(gy),
                             torch.zeros(B, 1, device=dev)], dim=1)
            a = L.net(obs).argmax(dim=1)
            x = (x + (a == 1).long() - (a == 2).long()).clamp(0, N - 1)
            y = (y + (a == 3).long() - (a == 4).long()).clamp(0, N - 1)
            if bool(((x == gx) & (y == gy)).all()):
                return t, True, 0.0
        return budget, False, float((x - gx).abs().add((y - gy).abs()).double().mean())
    ax, ay = torch.full((B,), goal[0][0], device=dev), torch.full((B,), goal[0][1], device=dev)
    bx, by = torch.full((B,), goal[1][0], device=dev), torch.full((B,), goal[1][1], device=dev)
    done = torch.zeros(B, dtype=torch.bool, device=dev)
    for t in range(1, budget + 1):
        gx = torch.where(done, bx, ax)
        gy = torch.where(done, by, ay)
        obs = torch.cat([onehot(x), onehot(y), onehot(gx), onehot(gy),
                         torch.zeros(B, 1, device=dev)], dim=1)
        a = L.net(obs).argmax(dim=1)
        x = (x + (a == 1).long() - (a == 2).long()).clamp(0, N - 1)
        y = (y + (a == 3).long() - (a == 4).long()).clamp(0, N - 1)
        done = done | ((x == ax) & (y == ay))
        if bool((done & (x == bx) & (y == by)).all()):
            return t, True, 0.0
    return budget, False, float((x - bx).abs().add((y - by).abs()).double().mean())


def oracle_rel_steps(goal, start=(5, 5), task="point"):
    """人手写「看相对位置」的上界参考（不学习）。"""
    gx, gy = goal if task == "point" else goal[1]
    return abs(gx - start[0]) + abs(gy - start[1])


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--task", default="point", choices=["point", "sequence"])
    ap.add_argument("--pressure", default="her", choices=["vanilla", "her"])
    ap.add_argument("--B", type=int, default=4096)
    ap.add_argument("--device", default="cuda")
    ap.add_argument("--seed", type=int, default=0)
    ap.add_argument("--seg-ticks", type=int, default=5000)
    ap.add_argument("--segs", type=int, default=200)
    ap.add_argument("--eval-every", type=int, default=10)
    ap.add_argument("--eval-budget", type=int, default=120)
    ap.add_argument("--max-seconds", type=float, default=0.0)
    ap.add_argument("--out", default="logs_b7/point_her")
    args = ap.parse_args()

    out = Path(args.out); out.mkdir(parents=True, exist_ok=True)
    seg_f = (out / "segments.jsonl").open("a")
    eval_f = (out / "evals.jsonl").open("a")
    t0 = time.time()
    gen = torch.Generator().manual_seed(args.seed + 1)
    dev = args.device
    w = World(args.B, dev, args.task, gen)
    L = NetLearner(args.B, dev, args.task, pressure=args.pressure)
    print(f"[B-b7] task={args.task} pressure={args.pressure} B={args.B} seg_ticks={args.seg_ticks} "
          f"eval_every={args.eval_every} net=MLP({OBS_DIM}->128->128->{N_ACT})", flush=True)

    goals_point = [(9, 9), (1, 1), (9, 1), (1, 9), (5, 9), (9, 5)]
    goals_seq = [((2, 8), (8, 2)), ((8, 2), (2, 8)), ((1, 1), (9, 9)), ((9, 9), (1, 1))]

    for seg in range(1, args.segs + 1):
        if args.max_seconds and (time.time() - t0) > args.max_seconds:
            break
        for _ in range(args.seg_ticks):
            obs_prev = w.obs()
            a = L.act(w, 0.3, True, L.n_updates)
            r = w.step(a)
            L.learn_from(w, obs_prev, a, r, True)
        gx, gy = w.subgoal()
        d = ((w.x - gx).abs() + (w.y - gy).abs()).double().mean()
        seg_f.write(json.dumps({"seg": seg, "mean_dist_to_subgoal": round(float(d), 3),
                                "updates": L.n_updates,
                                "wall_s": round(time.time() - t0, 1),
                                "task": args.task, "pressure": args.pressure}) + "\n")
        seg_f.flush()

        if seg % args.eval_every == 0:
            probe = probe_representation(L)
            rows = {}
            gs = goals_point if args.task == "point" else goals_seq
            for g in gs:
                ticks, ok, dist = greedy_eval(L, args.task, g, args.eval_budget)
                rows[str(g)] = (ticks, ok, round(dist, 2))
            n_ok = sum(1 for v in rows.values() if v[1])
            eval_f.write(json.dumps({"seg": seg, "probe": probe,
                                     "eval": rows, "success": f"{n_ok}/{len(rows)}",
                                     "wall_s": round(time.time() - t0, 1)}) + "\n")
            eval_f.flush()
            print(f"[B-b7/{args.task}/{args.pressure}] seg={seg} dist={d:.2f} "
                  f"probe={probe} success={n_ok}/{len(rows)} detail={rows}", flush=True)
    # 参考上界
    ref = {"oracle_point_steps": {str(g): oracle_rel_steps(g) for g in goals_point}} \
        if args.task == "point" else {"oracle_seq_steps": "先到 A 再 B，步数=|A−start|+|B−A|"}
    (out / "summary.json").write_text(json.dumps(
        {"task": args.task, "pressure": args.pressure, "segs": seg, "reference": ref,
         "wall_s": round(time.time() - t0, 1), "B": args.B}, ensure_ascii=False, indent=1))
    seg_f.close(); eval_f.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
