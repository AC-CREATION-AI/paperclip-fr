#!/usr/bin/env bash
# Offline check of all supported upstream targets (no network).
#   scripts/check-all-targets.sh <paperclip-clone> [<chat-fix.patch>]
# Targets verified:
#   1. v2026.1106.0 tag -> v2026.1106.0.patch
#   2. c1451814c (master pin) -> master-c1451814c.patch
#   3. 7751fc310 (canary.11) + optional chat fix -> canary11-chat.patch
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
up="$(realpath "${1:?paperclip clone directory required}")"
chat="${2:-}"
if [ -n "$chat" ]; then
  chat="$(realpath "$chat")"
fi

# Use a scratch directory inside .tmp of the workspace to respect sandbox rules
work="$(mktemp -d -p "$here/../" wt-targets-XXXXXX 2>/dev/null || mktemp -d)"
cleanup() {
  git -C "$up" worktree remove --force "$work/tree" >/dev/null 2>&1 || true
  rm -rf "$work"
}
trap cleanup EXIT

echo "=== Target 1: v2026.1106.0 ==="
git -C "$up" worktree add -q --detach "$work/tree" v2026.1106.0
out="$(bash "$here/install.sh" "$work/tree")"
echo "$out"
echo "$out" | grep -q "patch selected: v2026.1106.0.patch" || { echo "FAIL: wrong patch selected"; exit 1; }
out2="$(bash "$here/install.sh" "$work/tree")"
echo "$out2" | grep -q "already applied: v2026.1106.0.patch" || { echo "FAIL: idempotence"; exit 1; }
bash "$here/uninstall.sh" "$work/tree"
status="$(git -C "$work/tree" status --porcelain)"
[ -z "$status" ] || { echo "FAIL: dirty tree after uninstall: $status"; exit 1; }
git -C "$up" worktree remove --force "$work/tree"

echo "=== Target 2: c1451814c (master pin) ==="
git -C "$up" worktree add -q --detach "$work/tree" c1451814c
out="$(bash "$here/install.sh" "$work/tree")"
echo "$out"
echo "$out" | grep -q "patch selected: master-c1451814c.patch" || { echo "FAIL: wrong patch selected"; exit 1; }
out2="$(bash "$here/install.sh" "$work/tree")"
echo "$out2" | grep -q "already applied: master-c1451814c.patch" || { echo "FAIL: idempotence"; exit 1; }
bash "$here/uninstall.sh" "$work/tree"
status="$(git -C "$work/tree" status --porcelain)"
[ -z "$status" ] || { echo "FAIL: dirty tree after uninstall: $status"; exit 1; }
git -C "$up" worktree remove --force "$work/tree"

echo "=== Target 3: canary.11 (7751fc310) + chat fix ==="
git -C "$up" worktree add -q --detach "$work/tree" 7751fc3107d7dd968ededec7ee25e04873d50b77
if [ -n "$chat" ]; then
  git -C "$work/tree" apply "$chat"
fi
out="$(bash "$here/install.sh" "$work/tree")"
echo "$out"
echo "$out" | grep -q "patch selected: canary11-chat.patch" || { echo "FAIL: wrong patch selected"; exit 1; }
out2="$(bash "$here/install.sh" "$work/tree")"
echo "$out2" | grep -q "already applied: canary11-chat.patch" || { echo "FAIL: idempotence"; exit 1; }
bash "$here/uninstall.sh" "$work/tree"
if [ -n "$chat" ]; then
  # Reversing the chat fix should leave the tree completely clean
  git -C "$work/tree" apply -R "$chat"
fi
status="$(git -C "$work/tree" status --porcelain)"
[ -z "$status" ] || { echo "FAIL: dirty tree after chat reversal: $status"; exit 1; }

echo "ALL TARGETS OK: v2026.1106.0, master (c1451814c), canary.11-chat"
