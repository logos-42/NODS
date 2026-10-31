#!/usr/bin/env bash
# Submit a paper to aiXiv (https://aixiv.science) through the documented API.
#
#   POST /api/get-upload-url   -> presigned S3 PUT url + s3_url
#   PUT  <upload_url>          -> upload the PDF
#   POST /api/submit           -> create the paper record (Bearer, `submit` scope)
#
# Usage:
#   export AIXIV_TOKEN=...                 # token with the `submit` scope
#   bash scripts/aixiv_submit.sh --dry-run # print what would be sent, no network
#   bash scripts/aixiv_submit.sh           # actually submit
#
# Optional overrides:
#   FILE=... META=... bash scripts/aixiv_submit.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FILE="${FILE:-$ROOT/paper/forced-objects/forced-objects.pdf}"
META="${META:-$ROOT/paper/forced-objects/aixiv_meta.json}"
API="https://aixiv.science/api"
DRY=0

[ "${1:-}" = "--dry-run" ] && DRY=1

if [ ! -f "$FILE" ]; then echo "missing pdf: $FILE" >&2; exit 1; fi
if [ ! -f "$META" ]; then echo "missing metadata: $META" >&2; exit 1; fi

# Metadata sanity check runs in both modes.
python3 - "$META" <<'PY'
import json, sys
m = json.load(open(sys.argv[1]))
req = ["title", "authorship_type", "authors", "corresponding_author",
       "category", "keywords", "license", "doc_type"]
missing = [k for k in req if not m.get(k)]
if missing:
    sys.exit("metadata missing required fields: " + ", ".join(missing))
if len(m["title"]) > 220:
    sys.exit("title exceeds 220 chars")
print("metadata ok:", m["title"])
print("abstract words:", len(m["abstract"].split()))
PY

if [ "$DRY" = "1" ]; then
  echo "--- dry run ---"
  echo "file: $FILE ($(du -h "$FILE" | cut -f1))"
  python3 - "$META" <<'PY'
import json, sys
m = json.load(open(sys.argv[1]))
m["s3_url"] = "<filled after upload>"
print(json.dumps(m, ensure_ascii=False, indent=2))
PY
  exit 0
fi

: "${AIXIV_TOKEN:?set AIXIV_TOKEN to a Bearer token with the 'submit' scope}"


echo "1/3 asking for an upload url"
resp=$(curl -sS -X POST "$API/get-upload-url" \
  -H "Authorization: Bearer $AIXIV_TOKEN" \
  -H 'Content-Type: application/json' \
  -d "$(python3 -c 'import json,os,sys;print(json.dumps({"filename":os.path.basename(sys.argv[1])}))' "$FILE")")

upload_url=$(python3 -c 'import json,sys;print(json.load(sys.stdin)["upload_url"])' <<<"$resp")
s3_url=$(python3 -c 'import json,sys;print(json.load(sys.stdin)["s3_url"])' <<<"$resp")
ctype=$(python3 -c 'import json,sys;print(json.load(sys.stdin).get("content_type","application/pdf"))' <<<"$resp")

echo "2/3 uploading $(basename "$FILE")"
curl -sS -X PUT "$upload_url" -H "Content-Type: $ctype" --data-binary @"$FILE" -o /dev/null

echo "3/3 creating the record"
body=$(python3 - "$META" "$s3_url" <<'PY'
import json, sys
m = json.load(open(sys.argv[1]))
m["s3_url"] = sys.argv[2]
print(json.dumps(m, ensure_ascii=False))
PY
)

curl -sS -X POST "$API/submit" \
  -H "Authorization: Bearer $AIXIV_TOKEN" \
  -H 'Content-Type: application/json' \
  -d "$body" | python3 -m json.tool
