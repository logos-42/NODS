#!/bin/bash
# PU-12 v3.2 运行状态一览（多层格点宇宙）
cd /work/liuyuanjie/pu12 || exit 1
echo "== pid =="
if [ -f pu12v32.pid ] && kill -0 "$(cat pu12v32.pid)" 2>/dev/null; then
  echo "running v3.2 $(cat pu12v32.pid)  $(ps -o etime= -p "$(cat pu12v32.pid)")"
else
  echo "NOT running"
fi
echo "== gpu =="
nvidia-smi --query-gpu=index,memory.used,utilization.gpu --format=csv,noheader
echo "== latest =="
tail -3 logs_v32/stdout.log 2>/dev/null
echo "== 发展情况 =="
python3 - <<'EOF' 2>/dev/null
import json
s = json.load(open("logs_v32/status.json"))
h = s["band_hist"]; tot = sum(h) or 1
print("tick %d | 目的达成 tick=%s | 全体到顶 tick=%s | 探索覆盖 %d/%d"
      % (s["t"], s["purpose_tick"], s["top_tick"], s["coverage"], s["coverage_tot"]))
print("带分布（12 = 最高频）:")
for k, v in enumerate(h):
    print("  带%2d: %5.1f%% %s" % (k, 100 * v / tot, "#" * int(50 * v / tot)))
print("格点: 占用 %d 个 | 地址深度 sub=%.1f subs=%.1f | 频率细分深度 %.1f（分辨率 %.2e 带）"
      % (s["occupied"], s["sub_depth_mean"], s["subs_depth_mean"], s["fine_depth_mean"], s["freq_resolution"]))
print("地址空间规模（对数量级）: 平均 10^%.1f | 最深 10^%.1f" % (s["space_log10"], s["space_log10_max"]))
print("理论上限: %s 个格子（只声明，不分配）" % s["theory_total"])
print("动作: 升频 %d/%d 成功 | 降频体验 %d | 扩张 %d | 细分 %d"
      % (s["up_ok"], s["up_try"], s["down"], s["expand"], s["refine"]))
EOF
echo "== 学到的偏好（状态 × 动作，平均奖赏） =="
python3 - <<'EOF' 2>/dev/null
import json
s = json.load(open("logs_v32/status.json"))
q = s["q_table"]; names = ["等", "升频", "降频", "扩张子", "扩张亚", "细分频"]
buckets = ["低带", "中带", "高带"]
print("               " + "".join("%8s" % n for n in names))
for b in range(3):
    for f in range(2):
        for acc in range(2):
            idx = b * 4 + f + 2 * acc
            row = q[idx]
            print("%s%s%s" % (buckets[b], "满格" if f else "空  ", "已达成" if acc else "未达成"),
                  "".join("%+8.2f" % v for v in row))
EOF
