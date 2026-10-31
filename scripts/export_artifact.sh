#!/usr/bin/env bash
# 导出本文 artifact 到 artifact/dist/（已被 artifact/.gitignore 忽略）（只含论文用到的路径，见 artifact/SCOPE.md）。
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$ROOT/artifact/dist"

PATHS=(
  lakefile.pinned.toml
  lean-toolchain
  lake-manifest.json
  Nods.lean
  Nods/Core
  Nods/Instances
  Nods/Chain.lean
  Nods/Theories/Algebraic.lean
  Nods/Theories/Radical.lean
  Nods/Theories/Tension.lean
  Nods/Theories/TensionReading.lean
  Nods/Theories/TensionAbstract.lean
  Nods/Theories/TensionCarriers.lean
  Nods/Theories/Vibration.lean
  paper/forced-objects
  LICENSE
)

rm -rf "$OUT"
mkdir -p "$OUT"

for p in "${PATHS[@]}"; do
  if [ ! -e "$ROOT/$p" ]; then
    echo "missing: $p" >&2
    exit 1
  fi
  mkdir -p "$OUT/$(dirname "$p")"
  cp -R "$ROOT/$p" "$OUT/$p"
done

# 边界说明放在 artifact 根，避免 artifact/artifact 嵌套
cp "$ROOT/artifact/SCOPE.md" "$OUT/SCOPE.md"

# 边界自检：PU-12 模拟与部署脚本不得进入
if find "$OUT" -iname '*pu12*' -o -iname '*deploy*' | grep -q .; then
  echo "artifact boundary violated: PU-12 or deploy content found" >&2
  exit 1
fi

# 不带走构建产物与临时文件
find "$OUT" -name '.DS_Store' -delete 2>/dev/null || true
find "$OUT" -name '*.log' -delete 2>/dev/null || true
find "$OUT" -name '*.blg' -delete 2>/dev/null || true

echo "artifact written to $OUT"
du -sh "$OUT"
