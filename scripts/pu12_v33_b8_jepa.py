#!/usr/bin/env python3
"""b8 —— MU-JEPA：把 I-JEPA 的自监督潜预测搬进升维宇宙（突破方向 4 的候选机制）

I-JEPA 核心（src/train.py）：
  h = layer_norm(target_encoder(full_img))[pred_pos]      # EMA 目标、no_grad
  z = predictor(context_encoder(masked_img), masks)        # 只在可见块上编码
  loss = smooth_l1(z, h)                                   # 潜空间预测，不重建
本实现把「图像」换成宇宙的 2×10×10 网格（通道0=智能体, 通道1=目标），
patch=2 → 25 token，遮块预测被遮块的潜表示。

两阶段（科学上更干净）：
  --phase pretrain : 纯自监督 JEPA，得到编码器（不涉及任何奖励）
  --phase probe    : 用编码器对全部 (x,y,gx,gy) 编码，检验潜表示是否
                     只依赖相对位置 (dx,dy) —— 即「抽象是否自己长出来」
  --phase rl       : 冻结编码器 + Q 头，按 b4 协议学策略，测 ACC

判定探针（沿用全项目口径）：
  rel_cons = 按 (dx,dy) 分组、隐层特征的余弦一致性（→1 = 相对抽象）
  abs_cons = 按 (x,y) 分组对照（应显著更低）
  policy  = 探针同样口径作用在 Q 输出上
"""
import argparse
import json
import math
import time
from pathlib import Path

import torch
import torch.nn as nn
import torch.nn.functional as F

N = 10          # 网格 10×10
PATCH = 2       # 2×2 patch -> 5×5=25 token
GRID = N // PATCH
DIM = 64
N_ACT = 5
CTX_KEEP = 0.35  # 可见块比例（I-JEPA 是 0.85-1.0 的 mask，即只留少量可见）


def make_grid(x, y, gx, gy):
    """(B,) → (B, 2, 10, 10) 网格图：通道0=智能体，通道1=目标。"""
    B = x.shape[0]
    img = torch.zeros(B, 2, N, N, device=x.device)
    img[torch.arange(B, device=x.device), 0, y.long(), x.long()] = 1.0
    img[torch.arange(B, device=x.device), 1, gy.long(), gx.long()] = 1.0
    return img


def patchify(img):
    """(B,2,10,10) -> (B,25,8)"""
    B = img.shape[0]
    p = img.unfold(2, PATCH, PATCH).unfold(3, PATCH, PATCH)   # B,2,5,5,2,2
    p = p.permute(0, 2, 3, 1, 4, 5).reshape(B, GRID * GRID, -1)
    return p


class Block(nn.Module):
    def __init__(self, dim=DIM, heads=4):
        super().__init__()
        self.n1 = nn.LayerNorm(dim)
        self.att = nn.MultiheadAttention(dim, heads, batch_first=True)
        self.n2 = nn.LayerNorm(dim)
        self.ff = nn.Sequential(nn.Linear(dim, dim * 4), nn.GELU(), nn.Linear(dim * 4, dim))

    def forward(self, x):
        h = self.n1(x)
        x = x + self.att(h, h, h, need_weights=False)[0]
        return x + self.ff(self.n2(x))


class Encoder(nn.Module):
    def __init__(self, dim=DIM, depth=3):
        super().__init__()
        self.proj = nn.Linear(PATCH * PATCH * 2, dim)
        self.pos = nn.Parameter(torch.zeros(1, GRID * GRID, dim))
        nn.init.trunc_normal_(self.pos, std=0.02)
        self.blocks = nn.ModuleList([Block(dim) for _ in range(depth)])
        self.norm = nn.LayerNorm(dim)

    def forward(self, tokens, keep=None):
        h = self.proj(tokens) + self.pos
        if keep is not None:            # keep: (B,25) bool
            h = h * keep.unsqueeze(-1)
        for b in self.blocks:
            h = b(h)
        return self.norm(h)


class Predictor(nn.Module):
    def __init__(self, dim=DIM, depth=2):
        super().__init__()
        self.proj = nn.Linear(dim, dim)
        self.pos = nn.Parameter(torch.zeros(1, GRID * GRID, dim))
        nn.init.trunc_normal_(self.pos, std=0.02)
        self.mask_tok = nn.Parameter(torch.zeros(1, 1, dim))
        nn.init.trunc_normal_(self.mask_tok, std=0.02)
        self.blocks = nn.ModuleList([Block(dim) for _ in range(depth)])
        self.norm = nn.LayerNorm(dim)

    def forward(self, z, keep):
        B = z.shape[0]
        h = self.proj(z) + self.pos
        h = torch.where(keep.unsqueeze(-1), h, self.mask_tok.expand(B, GRID * GRID, -1))
        for b in self.blocks:
            h = b(h)
        return self.norm(h)


def sample_masks(B, device, n_pred=2, pred_frac=0.2):
    """上下文 = 一个连续块（占 CTX_KEEP）；目标 = 其余区域中随机取 n_pred 个块。"""
    keep = torch.zeros(B, GRID * GRID, dtype=torch.bool, device=device)
    side = max(1, int(round(math.sqrt(CTX_KEEP) * GRID)))
    px, py = torch.randint(0, GRID - side + 1, (B,), device=device), \
        torch.randint(0, GRID - side + 1, (B,), device=device)
    for i in range(B):
        keep[i].view(GRID, GRID)[py[i]:py[i] + side, px[i]:px[i] + side] = True
    tgt = torch.zeros_like(keep)
    k = max(1, int(round(pred_frac * GRID * GRID)))
    for i in range(B):
        for _ in range(n_pred):
            tx, ty = int(torch.randint(0, GRID, (1,))), int(torch.randint(0, GRID, (1,)))
            tgt[i].view(GRID, GRID)[ty:ty + 2, tx:tx + 2] = True
    return keep, tgt


@torch.no_grad()
def ema_update(enc, tgt_enc, m):
    for pq, pk in zip(enc.parameters(), tgt_enc.parameters()):
        pk.data.mul_(m).add_(pq.detach().data, alpha=1 - m)


def jepa_loss(enc, pred, tgt_enc, tokens, m_ctx, m_tgt, var_lambda=1.0, var_gamma=1.0):
    z = pred(enc(tokens, keep=m_ctx), m_ctx)
    # VICReg 方差项：防表示坍缩（JEPA 小规模复现的必备项）
    feats = enc(tokens)
    std = torch.sqrt(feats.var(dim=(0, 1)) + 1e-4)
    var_term = torch.relu(var_gamma - std).mean()
    with torch.no_grad():
        h_raw = tgt_enc(tokens)
        h = F.layer_norm(h_raw, (h_raw.size(-1),))
    sel = m_tgt
    return F.smooth_l1_loss(z[sel], h[sel]), var_term, float(std.mean())


def pretrain(args, device):
    gen = torch.Generator().manual_seed(args.seed)
    enc = Encoder().to(device)
    pred = Predictor().to(device)
    tgt_enc = Encoder().to(device)
    tgt_enc.load_state_dict(enc.state_dict())
    for p in tgt_enc.parameters():
        p.requires_grad = False
    opt = torch.optim.AdamW(list(enc.parameters()) + list(pred.parameters()),
                            lr=args.lr, weight_decay=0.05)
    B = args.ssl_batch
    t0 = time.time()
    for step in range(1, args.ssl_steps + 1):
        # 采样状态：均匀覆盖各种 (x,y,gx,gy)（自监督不需要奖励，只需状态分布）
        x = torch.randint(0, N, (B,), device=device)
        y = torch.randint(0, N, (B,), device=device)
        gx = torch.randint(0, N, (B,), device=device)
        gy = torch.randint(0, N, (B,), device=device)
        tokens = patchify(make_grid(x, y, gx, gy))
        m_ctx, m_tgt = sample_masks(B, device)
        base, var_t, std_mean = jepa_loss(enc, pred, tgt_enc, tokens, m_ctx, m_tgt,
                                          var_lambda=args.var_lambda, var_gamma=args.var_gamma)
        loss = base + args.var_lambda * var_t
        opt.zero_grad(); loss.backward()
        torch.nn.utils.clip_grad_norm_(list(enc.parameters()) + list(pred.parameters()), 1.0)
        opt.step()
        m = 0.996 + (1.0 - 0.996) * min(1.0, step / args.ssl_steps)
        with torch.no_grad():
            ema_update(enc, tgt_enc, m)
        if step % max(1, args.ssl_steps // 10) == 0:
            print(f"[b8/pretrain] step={step}/{args.ssl_steps} loss={float(loss):.4f} "
                  f"base={float(base):.4f} var={float(var_t):.4f} std={std_mean:.3f} "
                  f"wall={time.time() - t0:.1f}s", flush=True)
    return enc


@torch.no_grad()
def encode_states(enc, x, y, gx, gy, chunk=1024):
    """→ (B, 2*DIM): [全局均值特征, 智能体所在 token 特征]"""
    outs = []
    for i in range(0, x.shape[0], chunk):
        sl = slice(i, i + chunk)
        toks = patchify(make_grid(x[sl], y[sl], gx[sl], gy[sl]))
        z = enc(toks)
        mean = z.mean(dim=1)
        idx = (y[sl] // PATCH) * GRID + (x[sl] // PATCH)
        loc = z[torch.arange(z.shape[0], device=z.device), idx.long()]
        outs.append(torch.cat([mean, loc], dim=1))
    return torch.cat(outs, dim=0)


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
    x = ax.reshape(-1); y = ay.reshape(-1); gx = bx.reshape(-1); gy = by.reshape(-1)
    feat = encode_states(enc, x, y, gx, gy)
    rel_cons = group_cons(feat, (x - gx) * (2 * N) + (y - gy))
    abs_cons = group_cons(feat, x * N + y)
    return {"rel_cons": round(rel_cons, 4), "abs_cons": round(abs_cons, 4),
            "rel_minus_abs": round(rel_cons - abs_cons, 4)}


class QHead(nn.Module):
    def __init__(self, in_dim=2 * DIM, hidden=64):
        super().__init__()
        self.net = nn.Sequential(nn.Linear(in_dim, hidden), nn.ReLU(),
                                 nn.Linear(hidden, N_ACT))

    def forward(self, f):
        return self.net(f)


def rl_train(enc, args, device, out: Path):
    """冻结 JEPA 编码器，学 Q 头（与 b4 同协议：在线回归 + ε-greedy）。"""
    enc.eval()
    for p in enc.parameters():
        p.requires_grad = False
    q = QHead().to(device)
    opt = torch.optim.Adam(q.parameters(), lr=1e-3)
    B = args.rl_batch
    x = torch.randint(0, N, (B,), device=device)
    y = torch.randint(0, N, (B,), device=device)
    gx = torch.randint(0, N, (B,), device=device)
    gy = torch.randint(0, N, (B,), device=device)
    seg_f = (out / "segments.jsonl").open("a")
    eval_f = (out / "evals.jsonl").open("a")
    t0 = time.time()
    steps = 0
    for seg in range(1, args.segs + 1):
        for _ in range(args.seg_ticks):
            with torch.no_grad():
                f = encode_states(enc, x, y, gx, gy)
                act = q(f).argmax(dim=1)
                eps = 0.3 / (1.0 + steps / 4000)
                hit = torch.rand(B, device=device) < eps
                act = torch.where(hit, torch.randint(0, N_ACT, (B,), device=device), act)
            old_d = ((x - gx).abs() + (y - gy).abs()).float()
            mx = (act == 1).long() - (act == 2).long()
            my = (act == 3).long() - (act == 4).long()
            nx = (x + mx).clamp(0, N - 1)
            ny = (y + my).clamp(0, N - 1)
            new_d = ((nx - gx).abs() + (ny - gy).abs()).float()
            r = torch.where(new_d < old_d, torch.full_like(new_d, 1.0),
                            torch.where(new_d > old_d, torch.full_like(new_d, -0.3),
                                        torch.full_like(new_d, -0.05)))
            hitg = (nx == gx) & (ny == gy)
            r = torch.where(hitg, torch.full_like(r, 1.0), r)
            loss = F.mse_loss(q(f).gather(1, act.unsqueeze(1)).squeeze(1), r)
            opt.zero_grad(); loss.backward(); opt.step()
            redrop = hitg & (torch.rand(B, device=device) < 0.5)
            x = torch.where(redrop, torch.randint(0, N, (B,), device=device), nx)
            y = torch.where(redrop, torch.randint(0, N, (B,), device=device), ny)
            gx = torch.where(redrop, torch.randint(0, N, (B,), device=device), gx)
            gy = torch.where(redrop, torch.randint(0, N, (B,), device=device), gy)
            steps += 1
        d = ((x - gx).abs() + (y - gy).abs()).double().mean()
        seg_f.write(json.dumps({"seg": seg, "mean_dist": round(float(d), 3),
                                "steps": steps, "wall_s": round(time.time() - t0, 1)}) + "\n")
        seg_f.flush()
        if seg % args.eval_every == 0:
            res = {}
            for goal in [(9, 9), (1, 1), (9, 1), (1, 9), (5, 9), (9, 5)]:
                ticks, ok = eval_greedy(enc, q, goal, args.eval_budget, device)
                res[str(goal)] = (ticks, ok)
            ok_n = sum(1 for v in res.values() if v[1])
            eval_f.write(json.dumps({"seg": seg, "eval": res, "success": f"{ok_n}/6"}) + "\n")
            eval_f.flush()
            print(f"[b8/rl] seg={seg} dist={float(d):.2f} success={ok_n}/6 detail={res}", flush=True)
    seg_f.close(); eval_f.close()
    torch.save({"q": q.state_dict()}, out / "qhead.pt")


@torch.no_grad()
def eval_greedy(enc, q, goal, budget, device, B=256):
    x = torch.full((B,), 5, device=device)
    y = torch.full((B,), 5, device=device)
    gx = torch.full((B,), goal[0], device=device)
    gy = torch.full((B,), goal[1], device=device)
    for t in range(1, budget + 1):
        f = encode_states(enc, x, y, gx, gy)
        a = q(f).argmax(dim=1)
        x = (x + (a == 1).long() - (a == 2).long()).clamp(0, N - 1)
        y = (y + (a == 3).long() - (a == 4).long()).clamp(0, N - 1)
        if bool(((x == gx) & (y == gy)).all()):
            return t, True
    return budget, False


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--phase", default="all", choices=["pretrain", "probe", "rl", "all"])
    ap.add_argument("--device", default="cuda")
    ap.add_argument("--seed", type=int, default=0)
    ap.add_argument("--ssl-steps", type=int, default=4000)
    ap.add_argument("--ssl-batch", type=int, default=256)
    ap.add_argument("--lr", type=float, default=3e-4)
    ap.add_argument("--var-lambda", type=float, default=1.0, help="VICReg 方差项权重（防坍缩）")
    ap.add_argument("--var-gamma", type=float, default=1.0, help="目标每维 std 下限")
    ap.add_argument("--rl-batch", type=int, default=1024)
    ap.add_argument("--seg-ticks", type=int, default=500)
    ap.add_argument("--segs", type=int, default=120)
    ap.add_argument("--eval-every", type=int, default=10)
    ap.add_argument("--eval-budget", type=int, default=120)
    ap.add_argument("--out", default="logs_b8")
    args = ap.parse_args()

    out = Path(args.out); out.mkdir(parents=True, exist_ok=True)
    device = args.device
    torch.manual_seed(args.seed)
    report = {"phase": args.phase, "ssl_steps": args.ssl_steps, "seed": args.seed}

    ck = out / "encoder.pt"
    if args.phase in ("pretrain", "all"):
        enc = pretrain(args, device)
        torch.save({"enc": enc.state_dict()}, ck)
        print(f"[b8] encoder saved -> {ck}", flush=True)
    else:
        enc = Encoder().to(device)
        enc.load_state_dict(torch.load(ck, map_location=device)["enc"])
    if args.phase in ("probe", "all"):
        p = probe(enc, device)
        report["probe"] = p
        print(f"[b8/probe] {p}", flush=True)
    if args.phase in ("rl", "all"):
        rl_train(enc, args, device, out)
        report["rl"] = "done"
    (out / "summary.json").write_text(json.dumps(report, ensure_ascii=False, indent=1))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
