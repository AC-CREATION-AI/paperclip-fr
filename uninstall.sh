#!/usr/bin/env bash
# paperclip-fr uninstaller: removes the French display layer from a Paperclip source tree.
#   ./uninstall.sh <paperclip-source-dir>
# Idempotent. Reverses the patch recorded at install time, removes the catalog,
# the marker and the backup directory.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
target="${1:-}"
[ -n "$target" ] || { echo "usage: uninstall.sh <paperclip-source-dir>" >&2; exit 2; }
[ -d "$target/ui/src" ] || { echo "error: $target does not look like a Paperclip source tree" >&2; exit 2; }
target="$(cd "$target" && pwd)"
marker="$target/.paperclip-fr.json"

reversed=0
for p in $(ls -1 "$here"/patches/*.patch 2>/dev/null | sort -r); do
  if (cd "$target" && git apply -R --check "$p" >/dev/null 2>&1); then
    (cd "$target" && git apply -R "$p")
    echo "patch reversed: $(basename "$p")"
    reversed=1
    break
  fi
done
[ "$reversed" = 1 ] || echo "no paperclip-fr patch found on this tree (already removed?)"

rm -f "$target/ui/src/i18n/display/fr.json" "$marker"
rmdir "$target/ui/src/i18n/display" 2>/dev/null || true
rm -rf "$target/.paperclip-fr-backup"
echo "uninstalled"
