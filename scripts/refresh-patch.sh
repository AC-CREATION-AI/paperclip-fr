#!/usr/bin/env bash
# Regenerate patches/<name>.patch for one upstream ref.
#   scripts/refresh-patch.sh <upstream-checkout> <ref> <name> [<reference-patch>]
# Re-applies the reference patch (default: the newest one in patches/) on <ref>
# with a 3-way merge and writes patches/<name>.patch. Exit 1 on conflict: fix it
# by hand in the checkout, `git add ui doc`, then `git diff --cached --binary`.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
up="${1:?upstream checkout}"; ref="${2:?ref}"; name="${3:?name}"
ref_patch="${4:-$(ls -1 "$here"/patches/*.patch | sort -r | head -n 1)}"
cd "$up"
git reset -q --hard
git checkout -q --detach "$ref"
if ! git apply --3way "$ref_patch"; then
  echo "CONFLICT: $ref does not take $(basename "$ref_patch") cleanly" >&2
  git status --short | grep -E '^(U|.U|AA|DU|UD)' >&2 || true
  exit 1
fi
git add ui doc
git diff --cached --binary > "$here/patches/$name.patch"
git reset -q --hard
echo "wrote patches/$name.patch for $(git rev-parse --short HEAD)"
