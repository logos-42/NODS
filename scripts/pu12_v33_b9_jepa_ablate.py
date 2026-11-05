#!/usr/bin/env python3
"""b9 —— 组件逐一替换的消融矩阵：我们的组件 vs JEPA 组件

配置（--config）：
  c0_flat            基线：one-hot 输入 + MLP（无 JEPA，纯奖励回归）        [我们的原方案]
  c1_spatial_frozen  JEPA 空间掩码块预测（预训练后冻结）+ Q 头
  c2_spatial_joint   同上，但 JEPA 潜预测与 Q 学习**联合训练**（在线辅助）
  c3_temporal_frozen JEPA 时序预测（动作条件 + 预测 k 步后潜表示）冻结 + Q 头
  c4_temporal_joint  同上联合训练
  c5_temporal_her    同上联合 + HER 目标重标注（两个有效压力叠加）

统一口径：同一世界（10×10，5 动作）、同一起点 (5,5)、同一探针
  rel_cons = 按 (dx,dy) 分组的特征余弦一致性（→1 = 相对抽象）
  abs_cons = 按 (x,y) 分组对照
  ACC      = 6 个角/边目标零探索 greedy 成功率

用法：
  python3 pu12_v33_b9_jepa_ablate.py --config c4_temporal_joint --device cuda --out logs_b9/c4
"""
import argparse
import json
import math
import time
from pathlib import Path

import torch
import torch.nn as nn
import torch.nn.functional as F

N = 10
PATCH = 2
GRID = N // PATCH
DIM = 64
N_ACT = 5
OBS_FLAT = N * 4 + 1
CTX_SIDE = 3          # 空间掩码：可见块 3x3 / 5x5
K_FUTURE = 3          # 时序预测：动作重复 k 步后的潜表示


def make_grid(x, y, gx, gy):
    B = x.shape[0]
    img = torch.zeros(B, 2, N, N, device=x.device)
    ar = torch.arange(B, device=x.device)
    img[ar, 0, y.long().clamp(0, N - 1), x.long().clamp(0, N - 1)] = 1.0
    img[ar, 1, gy.long().clamp(0, N - 1), gx.long().clamp(0, N - 1)] = 1.0
    return img


def patchify(img):
    B = img.shape[0]
    p = img.unfold(2, PATCH, PATCH).unfold(3, PATCH, PATCH)
    return p.permute(0, 2, 3, 1, 4, 5).reshape(B, GRID * GRID, -1)


def flat_obs(x, y, gx, gy):
    def oh(v):
        return F.one_hot(v.long().clamp(0, N - 1), N).float()
    return torch.cat([oh(x), oh(y), oh(gx), oh(gy),
                      torch.zeros(x.shape[0], 1, device=x.device)], dim=1)


class Block(nn.Module):
    def __init__(self, dim=DIM, heads=4):
        super().__init__()
        self.n1, self.n2 = nn.LayerNorm(dim), nn.LayerNorm(dim)
        self.att = nn.MultiheadAttention(dim, heads, batch_first=True)
        self.ff = nn.Sequential(nn.Linear(dim, dim * 4), nn.GELU(), nn.Linear(dim * 4, dim))

    def forward(self, x):
        h = self.n1(x)
        x = x + self.att(h, h, h, need_weights=False)[0]
        return x + self.ff(self.n2(x))


class Encoder(nn.Module):
    def __init__(self, depth=3):
        super().__init__()
        self.proj = nn.Linear(PATCH * PATCH * 2, DIM)
        self.pos = nn.Parameter(torch.zeros(1, GRID * GRID, DIM))
        nn.init.trunc_normal_(self.pos, std=0.02)
        self.blocks = nn.ModuleList([Block() for _ in range(depth)])
        self.norm = nn.LayerNorm(DIM)

    def forward(self, tok, keep=None):
        h = self.proj(tok) + self.pos
        if keep is not None:
            h = h * keep.unsqueeze(-1)
        for b in self.blocks:
            h = b(h)
        return self.norm(h)


class Predictor(nn.Module):
    """空间模式：补 mask token 后预测被遮块；时序模式：拼接动作嵌入后预测未来。"""
    def __init__(self, depth=2, act_cond=False):
        super().__init__()
        self.act_cond = act_cond
        self.proj = nn.Linear(DIM, DIM)
        self.pos = nn.Parameter(torch.zeros(1, GRID * GRID, DIM))
        nn.init.trunc_normal_(self.pos, std=0.02)
        self.mask_tok = nn.Parameter(torch.zeros(1, 1, DIM))
        nn.init.trunc_normal_(self.mask_tok, std=0.02)
        if act_cond:
            self.act_emb = nn.Embedding(N_ACT, DIM)
        self.blocks = nn.ModuleList([Block() for _ in range(depth)])
        self.norm = nn.LayerNorm(DIM)

    def forward(self, z, keep=None, act=None):
        B = z.shape[0]
        h = self.proj(z) + self.pos
        if keep is not None:
            h = torch.where(keep.unsqueeze(-1), h, self.mask_tok.expand(B, GRID * GRID, -1))
        if self.act_cond and act is not None:
            h = h + self.act_emb(act).unsqueeze(1)
        for b in self.blocks:
            h = b(h)
        return self.norm(h)


class FlatEncoder(nn.Module):
    def __init__(self):
        super().__init__()
        self.net = nn.Sequential(nn.Linear(OBS_FLAT, 128), nn.ReLU(),
                                 nn.Linear(128, 128), nn.ReLU())

    def forward(self, obs):
        return self.net(obs)


class EncWrapper:
    """统一编码接口：kind=flat 吃 one-hot；kind=jepa 吃网格 token，输出 (B,2*DIM)。"""

    def __init__(self, kind, device):
        self.kind = kind
        self.device = device
        self.net = (FlatEncoder() if kind == "flat" else Encoder()).to(device)

    def features(self, x, y, gx, gy):
        if self.kind == "flat":
            return self.net(flat_obs(x, y, gx, gy))
        z = self.net(patchify(make_grid(x, y, gx, gy)))
        idx = ((y // PATCH) * GRID + (x // PATCH)).long()
        loc = z[torch.arange(z.shape[0], device=z.device), idx]
        return torch.cat([z.mean(dim=1), loc], dim=1)

    def parameters(self):
        return self.net.parameters()


def batch_mask(B, device, side=CTX_SIDE):
    """整批同一可见块（联合训练时每 tick 只采一次，避免 python 循环）。"""
    keep = torch.zeros(1, GRID * GRID, dtype=torch.bool, device=device)
    px = torch.randint(0, GRID - side + 1, (1,)).item()
    py = torch.randint(0, GRID - side + 1, (1,)).item()
    keep.view(GRID, GRID)[py:py + side, px:px + side] = True
    tgt = ~keep
    return keep.expand(B, -1), tgt.expand(B, -1)


def step_state(x, y, act):
    mx = (act == 1).long() - (act == 2).long()
    my = (act == 3).long() - (act == 4).long()
    return (x + mx).clamp(0, N - 1), (y + my).clamp(0, N - 1)


def ssl_step(enc, pred, tgt_enc, kind, x, y, gx, gy, act, var_lambda, var_gamma):
    """一次自监督更新所需的损失（空间掩码块 或 时序预测）。"""
    toks = patchify(make_grid(x, y, gx, gy))
    if kind == "spatial":
        keep, tgt = batch_mask(x.shape[0], x.device)
        z = pred(enc(toks, keep=keep), keep=keep)
        with torch.no_grad():
            h = tgt_enc(toks)
            h = F.layer_norm(h, (h.size(-1),))
        base = F.smooth_l1_loss(z[tgt], h[tgt])
    else:  # temporal：动作重复 K 步后的潜表示
        keep, _ = batch_mask(x.shape[0], x.device)
        z = pred(enc(toks, keep=keep), keep=None, act=act)
        nx, ny = x, y
        for _ in range(K_FUTURE):
            nx, ny = step_state(nx, ny, act)
        with torch.no_grad():
            h = tgt_enc(patchify(make_grid(nx, ny, gx, gy)))
            h = F.layer_norm(h, (h.size(-1),))
        base = F.smooth_l1_loss(z, h)
    feats = enc(toks)
    std = torch.sqrt(feats.var(dim=(0, 1)) + 1e-4)
    var_term = torch.relu(var_gamma - std).mean()
    return base + var_lambda * var_term, float(base), float(std.mean())


@torch.no_grad()
def ema_update(enc, tgt_enc, m):
    for pq, pk in zip(enc.parameters(), tgt_enc.parameters()):
        pk.data.mul_(m).add_(pq.data, alpha=1 - m)


def pretrain(enc, pred, tgt_enc, kind, args, device):
    opt = torch.optim.AdamW(list(enc.parameters()) + list(pred.parameters()),
                            lr=args.lr, weight_decay=0.05)
    B = args.ssl_batch
    t0 = time.time()
    for step in range(1, args.ssl_steps + 1):
        x = torch.randint(0, N, (B,), device=device)
        y = torch.randint(0, N, (B,), device=device)
        gx = torch.randint(0, N, (B,), device=device)
        gy = torch.randint(0, N, (B,), device=device)
        act = torch.randint(0, N_ACT, (B,), device=device)
        loss, base, std = ssl_step(enc, pred, tgt_enc, kind, x, y, gx, gy, act,
                                   args.var_lambda, args.var_gamma)
        opt.zero_grad(); loss.backward()
        torch.nn.utils.clip_grad_norm_(list(enc.parameters()) + list(pred.parameters()), 1.0)
        opt.step()
        ema_update(enc, tgt_enc, 0.996)
        if step % max(1, args.ssl_steps // 5) == 0:
            print(f"[b9/ssl-{kind}] step={step}/{args.ssl_steps} loss={float(loss):.4f} "
                  f"base={base:.4f} std={std:.3f} wall={time.time() - t0:.1f}s", flush=True)


def group_cons(feat, group_id):
    q = F.normalize(feat, dim=1)
    sims = []
    for g in group_id.unique().tolist():
        idx = (group_id == g).nonzero(as_tuple=True)[0]
        k = idx.numel()
        if k < 2:
            continue
        sim = q[idx] @ q[idx].T
        sims.append(sim[~torch.eye(k, dtype=torch.bool, device=q.device)].mean())
    return float(torch.stack(sims).mean()) if sims else float("nan")


@torch.no_grad()
def probe(enc, device):
    xs = torch.arange(N, device=device)
    ax, ay, bx, by = torch.meshgrid(xs, xs, xs, xs, indexing="ij")
    x, y, gx, gy = ax.reshape(-1), ay.reshape(-1), bx.reshape(-1), by.reshape(-1)
    feat = enc.features(x, y, gx, gy)
    rel = group_cons(feat, (x - gx) * (2 * N) + (y - gy))
    abs_ = group_cons(feat, x * N + y)
    return {"rel_cons": round(rel, 4), "abs_cons": round(abs_, 4),
            "rel_minus_abs": round(rel - abs_, 4)}


@torch.no_grad()
def eval_greedy(enc, q, goal, budget, device, B=256):
    x = torch.full((B,), 5, device=device); y = torch.full((B,), 5, device=device)
    gx = torch.full((B,), goal[0], device=device); gy = torch.full((B,), goal[1], device=device)
    for t in range(1, budget + 1):
        a = q(enc.features(x, y, gx, gy)).argmax(dim=1)
        x, y = step_state(x, y, a)
        if bool(((x == gx) & (y == gy)).all()):
            return t, True
    return budget, False


def rl_train(enc, q, args, device, out: Path, joint=False, ssl_kind="spatial",
             her=False, pred=None, tgt_enc=None):
    opt = torch.optim.Adam(list(q.parameters()) + (list(enc.parameters()) if joint else []),
                           lr=args.rl_lr)
    B = args.rl_batch
    x = torch.randint(0, N, (B,), device=device); y = torch.randint(0, N, (B,), device=device)
    gx = torch.randint(0, N, (B,), device=device); gy = torch.randint(0, N, (B,), device=device)
    steps = 0
    seg_f = (out / "segments.jsonl").open("a"); eval_f = (out / "evals.jsonl").open("a")
    t0 = time.time()
    for seg in range(1, args.segs + 1):
        for _ in range(args.seg_ticks):
            f = enc.features(x, y, gx, gy)
            a = q(f).argmax(dim=1)
            eps = 0.3 / (1.0 + steps / 4000)
            a = torch.where(torch.rand(B, device=device) < eps,
                            torch.randint(0, N_ACT, (B,), device=device), a)
            nx, ny = step_state(x, y, a)
            gx_r, gy_r = gx, gy
            if her and steps % 4 == 0:      # 目标重标注（一半随机换目标）
                swap = torch.rand(B, device=device) < 0.5
                gx_r = torch.where(swap, torch.randint(0, N, (B,), device=device), gx)
                gy_r = torch.where(swap, torch.randint(0, N, (B,), device=device), gy)
            old_d = ((x - gx_r).abs() + (y - gy_r).abs()).float()
            new_d = ((nx - gx_r).abs() + (ny - gy_r).abs()).float()
            r = torch.where(new_d < old_d, torch.full_like(new_d, 1.0),
                            torch.where(new_d > old_d, torch.full_like(new_d, -0.3),
                                        torch.full_like(new_d, -0.05)))
            hitg = (nx == gx_r) & (ny == gy_r)
            r = torch.where(hitg, torch.full_like(r, 1.0), r)
            loss = F.mse_loss(q(f).gather(1, a.unsqueeze(1)).squeeze(1), r)
            if joint:
                ssl_l, _, _ = ssl_step(enc.net, pred, tgt_enc, ssl_kind, x, y, gx_r, gy_r, a,
                                       args.var_lambda, args.var_gamma)
                loss = loss + args.joint_w * ssl_l
                ema_update(enc.net, tgt_enc, 0.996)
            opt.zero_grad(); loss.backward(); opt.step()
            redrop = hitg & (torch.rand(B, device=device) < 0.5)
            x = torch.where(redrop, torch.randint(0, N, (B,), device=device), nx)
            y = torch.where(redrop, torch.randint(0, N, (B,), device=device), ny)
            gx = torch.where(redrop, torch.randint(0, N, (B,), device=device), gx)
            gy = torch.where(redrop, torch.randint(0, N, (B,), device=device), gy)
            steps += 1
        d = ((x - gx).abs() + (y - gy).abs()).double().mean()
        seg_f.write(json.dumps({"seg": seg, "mean_dist": round(float(d), 3), "steps": steps,
                                "wall_s": round(time.time() - t0, 1)}) + "\n"); seg_f.flush()
        if seg % args.eval_every == 0:
            res = {}
            for goal in [(9, 9), (1, 1), (9, 1), (1, 9), (5, 9), (9, 5)]:
                ticks, ok = eval_greedy(enc, q, goal, args.eval_budget, device)
                res[str(goal)] = (ticks, ok)
            ok_n = sum(1 for v in res.values() if v[1])
            eval_f.write(json.dumps({"seg": seg, "eval": res, "success": f"{ok_n}/6",
                                     "probe": probe(enc, device)}) + "\n"); eval_f.flush()
            print(f"[b9/rl] seg={seg} dist={float(d):.2f} success={ok_n}/6 "
                  f"probe={probe(enc, device)}", flush=True)
    seg_f.close(); eval_f.close()


class QHead(nn.Module):
    def __init__(self, in_dim):
        super().__init__()
        self.net = nn.Sequential(nn.Linear(in_dim, 64), nn.ReLU(), nn.Linear(64, N_ACT))

    def forward(self, f):
        return self.net(f)


CONFIGS = {
    "c0_flat":             dict(kind="flat", ssl=None,      joint=False, her=False),
    "c1_spatial_frozen":   dict(kind="jepa", ssl="spatial", joint=False, her=False),
    "c2_spatial_joint":    dict(kind="jepa", ssl="spatial", joint=True,  her=False),
    "c3_temporal_frozen":  dict(kind="jepa", ssl="temporal", joint=False, her=False),
    "c4_temporal_joint":   dict(kind="jepa", ssl="temporal", joint=True,  her=False),
    "c5_temporal_her":     dict(kind="jepa", ssl="temporal", joint=True,  her=True),
}


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--config", default="c4_temporal_joint", choices=list(CONFIGS))
    ap.add_argument("--device", default="cuda")
    ap.add_argument("--seed", type=int, default=0)
    ap.add_argument("--ssl-steps", type=int, default=3000)
    ap.add_argument("--ssl-batch", type=int, default=256)
    ap.add_argument("--lr", type=float, default=3e-4)
    ap.add_argument("--rl-lr", type=float, default=1e-3)
    ap.add_argument("--rl-batch", type=int, default=1024)
    ap.add_argument("--seg-ticks", type=int, default=500)
    ap.add_argument("--segs", type=int, default=120)
    ap.add_argument("--eval-every", type=int, default=10)
    ap.add_argument("--eval-budget", type=int, default=120)
    ap.add_argument("--var-lambda", type=float, default=1.0)
    ap.add_argument("--var-gamma", type=float, default=1.0)
    ap.add_argument("--joint-w", type=float, default=0.5)
    ap.add_argument("--out", default="logs_b9/run")
    args = ap.parse_args()

    cfg = CONFIGS[args.config]
    out = Path(args.out); out.mkdir(parents=True, exist_ok=True)
    device = args.device
    torch.manual_seed(args.seed)
    enc = EncWrapper(cfg["kind"], device)
    pred = tgt_enc = None
    if cfg["ssl"]:
        pred = Predictor(act_cond=(cfg["ssl"] == "temporal")).to(device)
        tgt_enc = Encoder().to(device)
        tgt_enc.load_state_dict(enc.net.state_dict())
        for p in tgt_enc.parameters():
            p.requires_grad = False
        pretrain(enc.net, pred, tgt_enc, cfg["ssl"], args, device)
        torch.save({"enc": enc.net.state_dict()}, out / "encoder.pt")
    p_pre = probe(enc, device)
    print(f"[b9/{args.config}] pre-RL probe={p_pre}", flush=True)

    in_dim = 128 if cfg["kind"] == "flat" else 2 * DIM
    q = QHead(in_dim).to(device)
    rl_train(enc, q, args, device, out, joint=cfg["joint"], ssl_kind=cfg["ssl"] or "spatial",
             her=cfg["her"], pred=pred, tgt_enc=tgt_enc)
    p_post = probe(enc, device)
    (out / "summary.json").write_text(json.dumps(
        {"config": args.config, "cfg": cfg, "probe_before_rl": p_pre,
         "probe_after_rl": p_post, "ssl_steps": args.ssl_steps if cfg["ssl"] else 0,
         "rl_ticks": args.seg_ticks * args.segs}, ensure_ascii=False, indent=1))
    print(f"[b9/{args.config}] DONE probe_after={p_post}", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
