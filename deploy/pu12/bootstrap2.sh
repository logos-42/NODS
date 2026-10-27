#!/bin/bash
# PU-12 依赖引导 v2：bootstrap.pypa.io 在这台容器上卡住 ⟹ 直接从 PyPI 取 pip wheel 跑
set -x
cd /work/liuyuanjie || exit 1
date

# 1) 从 PyPI JSON 拿 pip wheel 的直链并下载（用 urllib，带超时）
python3 - <<'EOF'
import json, urllib.request, sys
meta = json.load(urllib.request.urlopen("https://pypi.org/pypi/pip/json", timeout=30))
url = next(u["url"] for u in meta["urls"] if u["filename"].endswith("py3-none-any.whl"))
print("PIP_WHEEL", url, flush=True)
with urllib.request.urlopen(url, timeout=60) as r, open("pip.whl", "wb") as f:
    f.write(r.read())
print("PIP_WHL_BYTES", __import__("os").path.getsize("pip.whl"), flush=True)
EOF

# 2) 解包 wheel，用 PYTHONPATH 直接跑 pip（容器没有 pip 模块）
rm -rf pipdir && mkdir -p pipdir
python3 -c "import zipfile;zipfile.ZipFile('pip.whl').extractall('pipdir')"
export PYTHONPATH=/work/liuyuanjie/pipdir
python3 -m pip --version

# 3) torch (CUDA 11.8) + numpy
python3 -m pip install --no-cache-dir --break-system-packages \
  torch --index-url https://download.pytorch.org/whl/cu118 --timeout 120 --retries 5
python3 -m pip install --no-cache-dir --break-system-packages numpy --timeout 60

# 4) 自检
python3 - <<'EOF'
import torch, numpy
print("TORCH", torch.__version__, "CUDA", torch.version.cuda, "avail", torch.cuda.is_available(),
      "devs", torch.cuda.device_count(), flush=True)
print("NUMPY", numpy.__version__, flush=True)
for i in range(torch.cuda.device_count()):
    print("GPU", i, torch.cuda.get_device_name(i), flush=True)
EOF
echo BOOTSTRAP2_EXIT_$?
