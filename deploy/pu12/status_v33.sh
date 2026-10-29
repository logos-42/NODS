#!/bin/bash
# PU-12 v3.3 运行状态一览（频率上限抬高版，20 带）
cd /work/liuyuanjie/pu12 || exit 1
echo "== pid =="
if [ -f pu12v33.pid ] && kill -0 "$(cat pu12v33.pid)" 2>/dev/null; then
  echo "running v3.3 $(cat pu12v33.pid)  $(ps -o etime= -p "$(cat pu12v33.pid)")"
else
  echo "NOT running"
fi
echo "== gpu =="
nvidia-smi --query-gpu=index,memory.used,utilization.gpu --format=csv,noheader
echo "== latest =="
tail -3 logs_v33/stdout.log 2>/dev/null
echo "== 发展情况 =="
python3 - <<'EOF' 2>/dev/null
import json
s = json.load(open("logs_v33/status.json"))
h = s["band_hist"]; tot = sum(h) or 1
print("tick %d | 目的达成 tick=%s | 全体到顶 tick=%s | 探索覆盖 %d/%d"
      % (s["t"], s["purpose_tick"], s["top_tick"], s["coverage"], s["coverage_tot"]))
print("频率: 天花板 %s  地板 %s  跨度 %d 数量级  %d 带×每带 10^%g"
      % (s["freq_ceil_hz"], s["freq_floor_hz"], s["span_decades"], s["n_bands"], s["decades_per_band"]))
print("带分布（%d = 最高频）:" % (s["n_bands"] - 1))
for k, v in enumerate(h):
    print("  带%2d: %5.1f%% %s" % (k, 100 * v / tot, "#" * int(50 * v / tot)))
print("格点: 占用 %d 个 | 地址深度 sub=%.1f subs=%.1f | 频率细分深度 %.1f"
      % (s["occupied"], s["sub_depth_mean"], s["subs_depth_mean"], s["fine_depth_mean"]))
print("地址空间规模（对数量级）: 平均 10^%.1f | 最深 10^%.1f" % (s["space_log10"], s["space_log10_max"]))
print("理论上限: %s 个格子（只声明，不分配）" % s["theory_total"])
print("动作: 升频 %d/%d 成功 | 降频体验 %d | 扩张 %d | 细分 %d"
      % (s["up_ok"], s["up_try"], s["down"], s["expand"], s["refine"]))
EOF
