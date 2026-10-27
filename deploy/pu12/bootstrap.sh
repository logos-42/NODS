#!/bin/bash
# PU-12 依赖引导（容器 cuda118:base，裸 python3，无 pip/numpy/torch）
set -x
cd /work/liuyuanjie || exit 1
date

# 1) pip
python3 -c "import urllib.request;urllib.request.urlretrieve('https://bootstrap.pypa.io/get-pip.py','/work/liuyuanjie/get-pip.py')" \
  && python3 get-pip.py --break-system-packages

# 2) torch (CUDA 11.8) + numpy
python3 -m pip install --no-cache-dir --break-system-packages \
  torch --index-url https://download.pytorch.org/whl/cu118
python3 -m pip install --no-cache-dir --break-system-packages numpy

# 3) 自检
python3 - <<'EOF'
import torch, numpy
print("TORCH", torch.__version__, "CUDA", torch.version.cuda, "avail", torch.cuda.is_available(),
      "devs", torch.cuda.device_count())
print("NUMPY", numpy.__version__)
if torch.cuda.is_available():
    print("GPU0", torch.cuda.get_device_name(0))
EOF
echo BOOTSTRAP_EXIT_$?
