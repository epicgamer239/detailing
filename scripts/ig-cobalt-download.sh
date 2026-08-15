#!/usr/bin/env bash
# Download Instagram post media via a Cobalt API (paste-link style).
# Usage:
#   ./scripts/ig-cobalt-download.sh <instagram-post-url> [more-urls...]
#   ./scripts/ig-cobalt-download.sh urls.txt   # one URL per line
set -euo pipefail

# Prefer a public instance without Turnstile. Override with COBALT_API=...
# Alternatives: https://api.cobalt.liubquanti.click/  https://cobalt.tools (UI only)
API="${COBALT_API:-https://dwnld.nichind.dev/}"
OUT="${IG_OUT:-$(cd "$(dirname "$0")/.." && pwd)/public/instagram-raw}"
mkdir -p "$OUT"

collect_urls() {
  if [[ $# -eq 1 && -f "$1" ]]; then
    grep -E 'instagram\.com/(p|reel|tv)/' "$1" || true
  else
    printf '%s\n' "$@"
  fi
}

short_id() {
  # .../p/CODE/ or .../reel/CODE/
  echo "$1" | sed -E 's#.*/(p|reel|tv)/([^/?#]+).*#\2#'
}

download_post() {
  local url="$1"
  local pid
  pid="$(short_id "$url")"
  echo "==> $pid  $url"

  local resp
  resp="$(curl -sS -m 60 -X POST "$API" \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json' \
    -d "{\"url\":\"$url\",\"downloadMode\":\"auto\",\"filenameStyle\":\"basic\"}")"

  local status
  status="$(echo "$resp" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("status",""))')"

  case "$status" in
    picker)
      echo "$resp" | python3 -c '
import json,sys,subprocess,pathlib
out=pathlib.Path("'"$OUT"'")
pid="'"$pid"'"
d=json.load(sys.stdin)
for i,it in enumerate(d.get("picker",[]),1):
    u=it["url"]
    typ=it.get("type") or "photo"
    ext="mp4" if typ=="video" else "jpg"
    dest=out/f"{pid}_{i:02d}.{ext}"
    subprocess.run(["curl","-sSL","--fail","-o",str(dest),u], check=False)
    size=dest.stat().st_size if dest.exists() else 0
    if size==0:
        print(f"  FAIL {dest.name}")
        continue
    head=dest.read_bytes()[:12]
    if head.startswith(b"\xff\xd8\xff") and dest.suffix!=".jpg":
        dest2=dest.with_suffix(".jpg"); dest.rename(dest2); dest=dest2
    elif b"ftyp" in head and dest.suffix!=".mp4":
        dest2=dest.with_suffix(".mp4"); dest.rename(dest2); dest=dest2
    print(f"  ok {dest.name} ({size})")
'
      ;;
    tunnel|redirect)
      echo "$resp" | python3 -c '
import json,sys,subprocess,pathlib
out=pathlib.Path("'"$OUT"'")
pid="'"$pid"'"
d=json.load(sys.stdin)
u=d.get("url") or (d.get("tunnel") or [None])[0]
if not u:
    print("  no url in response", d); raise SystemExit(1)
dest=out/f"{pid}_01.bin"
subprocess.run(["curl","-sSL","--fail","-o",str(dest),u], check=False)
head=dest.read_bytes()[:12]
if head.startswith(b"\xff\xd8\xff"):
    dest2=dest.with_suffix(".jpg"); dest.rename(dest2); dest=dest2
elif b"ftyp" in head:
    dest2=dest.with_suffix(".mp4"); dest.rename(dest2); dest=dest2
print(f"  ok {dest.name} ({dest.stat().st_size})")
'
      ;;
    *)
      echo "  Cobalt error: $resp" >&2
      return 1
      ;;
  esac
}

# Bash 3.2 compatible (macOS default) — no mapfile
URLS=()
while IFS= read -r line; do
  [[ -z "$line" || "$line" == \#* ]] && continue
  URLS+=("$line")
done < <(collect_urls "$@")

if [[ ${#URLS[@]} -eq 0 ]]; then
  echo "No Instagram post URLs given." >&2
  exit 1
fi

ok=0
fail=0
for u in "${URLS[@]}"; do
  if download_post "$u"; then
    ok=$((ok+1))
  else
    fail=$((fail+1))
  fi
  sleep 1
done

echo "Done. ok=$ok fail=$fail  → $OUT"
ls -lah "$OUT" | tail -n +1
