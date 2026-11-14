#!/usr/bin/env bash
# Offline test of install.sh / uninstall.sh on a throw-away git repo.
# Needs only git, bash, python3. No network.
set -euo pipefail
export GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=t@example.invalid GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=t@example.invalid
here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
fail() { echo "FAIL: $*" >&2; exit 1; }

# Fake package: one tiny patch + tiny catalog, same layout as the real one.
pkg="$work/pkg"; mkdir -p "$pkg/patches" "$pkg/catalog"
cp "$here/install.sh" "$here/uninstall.sh" "$pkg/"
echo '{"Hello":"Bonjour"}' > "$pkg/catalog/fr.json"

repo="$work/paperclip"; mkdir -p "$repo/ui/src"
git -C "$repo" init -q
git -C "$repo" config user.email t@example.invalid
git -C "$repo" config user.name test
printf 'console.log("hi");\n' > "$repo/ui/src/main.tsx"
git -C "$repo" add -A; git -C "$repo" commit -qm base
printf 'import "./i18n";\nconsole.log("hi");\n' > "$repo/ui/src/main.tsx"
git -C "$repo" diff > "$pkg/patches/test.patch"
git -C "$repo" checkout -q -- .

base_sum="$(sha256sum "$repo/ui/src/main.tsx" | cut -d' ' -f1)"

bash "$pkg/install.sh" --dry-run "$repo" >/dev/null
[ "$(sha256sum "$repo/ui/src/main.tsx" | cut -d' ' -f1)" = "$base_sum" ] || fail "dry-run changed the tree"
[ ! -e "$repo/.paperclip-fr.json" ] || fail "dry-run wrote the marker"

bash "$pkg/install.sh" "$repo" >/dev/null
grep -q 'i18n' "$repo/ui/src/main.tsx" || fail "patch not applied"
[ -f "$repo/ui/src/i18n/display/fr.json" ] || fail "catalog missing"
[ -f "$repo/.paperclip-fr.json" ] || fail "marker missing"
after1="$(sha256sum "$repo/ui/src/main.tsx" | cut -d' ' -f1)"

out2="$(bash "$pkg/install.sh" "$repo" 2>/dev/null)"
case "$out2" in *"already applied"*) ;; *) fail "second install is not a no-op: $out2" ;; esac
[ "$(sha256sum "$repo/ui/src/main.tsx" | cut -d' ' -f1)" = "$after1" ] || fail "second install changed the tree"

bash "$pkg/uninstall.sh" "$repo" >/dev/null
[ "$(sha256sum "$repo/ui/src/main.tsx" | cut -d' ' -f1)" = "$base_sum" ] || fail "uninstall did not restore main.tsx"
[ ! -e "$repo/ui/src/i18n/display" ] || fail "catalog left behind"
[ ! -e "$repo/.paperclip-fr.json" ] || fail "marker left behind"
[ -z "$(git -C "$repo" status --porcelain)" ] || fail "tree not clean after uninstall"

bash "$pkg/uninstall.sh" "$repo" >/dev/null || fail "second uninstall must not fail"

# A tree the patch does not fit: refuse, change nothing.
printf 'something else\n' > "$repo/ui/src/main.tsx"
if bash "$pkg/install.sh" "$repo" >/dev/null 2>&1; then fail "install should refuse a non-matching tree"; fi
[ "$(cat "$repo/ui/src/main.tsx")" = "something else" ] || fail "refused install modified the tree"

echo "OK: install / idempotence / uninstall / refusal"
