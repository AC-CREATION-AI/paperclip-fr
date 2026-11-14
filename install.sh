#!/usr/bin/env bash
# paperclip-fr installer: applies the French display layer to a Paperclip source tree.
#
#   ./install.sh [--dry-run] <paperclip-source-dir>
#
# Idempotent: running it twice leaves the tree unchanged. It never touches
# anything outside <paperclip-source-dir>. Uninstall with ./uninstall.sh.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dry=0
if [ "${1:-}" = "--dry-run" ]; then dry=1; shift; fi
target="${1:-}"
[ -n "$target" ] || { echo "usage: install.sh [--dry-run] <paperclip-source-dir>" >&2; exit 2; }
[ -d "$target/ui/src" ] || { echo "error: $target does not look like a Paperclip source tree (ui/src missing)" >&2; exit 2; }
target="$(cd "$target" && pwd)"

marker="$target/.paperclip-fr.json"
backup_dir="$target/.paperclip-fr-backup"
catalog_dest="$target/ui/src/i18n/display/fr.json"
catalog_src="$here/catalog/fr.json"

mapfile -t patches < <(ls -1 "$here"/patches/*.patch 2>/dev/null | sort -r)
[ "${#patches[@]}" -gt 0 ] || { echo "error: no patch in $here/patches" >&2; exit 2; }

applied=""
for p in "${patches[@]}"; do
  if (cd "$target" && git apply -R --check "$p" >/dev/null 2>&1); then applied="$p"; break; fi
done

if [ -n "$applied" ]; then
  echo "already applied: $(basename "$applied")"
  chosen="$applied"
else
  chosen=""
  for p in "${patches[@]}"; do
    if (cd "$target" && git apply --check "$p" >/dev/null 2>&1); then chosen="$p"; break; fi
  done
  if [ -z "$chosen" ]; then
    echo "error: no patch applies to this Paperclip tree. Nothing was changed." >&2
    echo "       Tried: $(printf '%s ' "${patches[@]##*/}")" >&2
    echo "       See README (Mise à jour) or open an issue with your Paperclip version." >&2
    exit 1
  fi
  echo "patch selected: $(basename "$chosen")"
fi

if [ "$dry" = 1 ]; then echo "dry-run: nothing written"; exit 0; fi

if [ -z "$applied" ]; then
  # Back up every file the patch touches (those that already exist), then apply.
  mkdir -p "$backup_dir"
  (cd "$target" && git apply --numstat "$chosen" | awk '{print $3}' | while read -r f; do
    if [ -f "$f" ]; then mkdir -p "$backup_dir/$(dirname "$f")"; cp -p "$f" "$backup_dir/$f"; fi
  done)
  (cd "$target" && git apply "$chosen")
  echo "patch applied"
fi

mkdir -p "$(dirname "$catalog_dest")"
cp "$catalog_src" "$catalog_dest"
sum="$(sha256sum "$catalog_src" | cut -d' ' -f1)"
printf '{"patch":"%s","catalogSha256":"%s"}\n' "$(basename "$chosen")" "$sum" > "$marker"
echo "catalog installed ($(basename "$catalog_dest"))"
echo "done. Rebuild the UI (pnpm --filter @paperclipai/ui build) to see the French interface."
