#!/usr/bin/env bash
# Offline check of canary11-chat.patch against a real upstream clone (no network).
#   scripts/check-canary11.sh <paperclip-clone> [<chat-fix.patch>]
# Needs commit 7751fc310 in the clone. The optional chat-fix patch is applied
# first (the "before" tree = canary.11 + local chat fix).
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
up="$(realpath "${1:?paperclip clone}")"; chat="${2:-}"
if [ -n "$chat" ]; then chat="$(realpath "$chat")"; fi
work="$(mktemp -d)"
cleanup() { git -C "$up" worktree remove --force "$work/tree" >/dev/null 2>&1 || true; rm -rf "$work"; }
trap cleanup EXIT
git -C "$up" worktree add -q --detach "$work/tree" 7751fc3107d7dd968ededec7ee25e04873d50b77
cd "$work/tree"
[ -z "$chat" ] || git apply "$chat"
res="$(python3 - "$here/patches/canary11-chat.pins.json" . <<'PY'
import hashlib, json, os, sys
bad = []
for r in json.load(open(sys.argv[1]))["files"]:
    f = os.path.join(sys.argv[2], r["path"]); w = r["beforeSha256"]
    ok = (not os.path.lexists(f)) if w is None else (os.path.isfile(f) and hashlib.sha256(open(f, "rb").read()).hexdigest() == w)
    if not ok: bad.append(r["path"])
print("OK" if not bad else "MISMATCH " + " ".join(bad))
PY
)"
echo "fingerprints (before): $res"
[ "$res" = "OK" ] || exit 1
git apply --check "$here/patches/canary11-chat.patch"
echo "git apply --check: OK"
