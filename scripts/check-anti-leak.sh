#!/usr/bin/env bash
# Fails if a tracked file contains an internal address, an internal path, a
# token-looking string, an internal host or a private name.
#
# Private names (customers, internal tools) are NOT written in this public
# file: set LEAK_EXTRA_PATTERN (extended regex, e.g. "name1|name2") from a CI
# secret. Without it, the name check is skipped locally and a warning is shown.
# In CI, REQUIRE_EXTRA_PATTERN=1 turns a missing pattern into a failure.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
fail=0
files="$(git ls-files 2>/dev/null || find . -type f -not -path './.git/*')"
files="$(printf '%s\n' "$files" | grep -v -e '^scripts/check-anti-leak.sh$')"

IPV4='\b(10\.[0-9]+\.[0-9]+\.[0-9]+|192\.168\.[0-9]+\.[0-9]+|172\.(1[6-9]|2[0-9]|3[01])\.[0-9]+\.[0-9]+)\b'
PATHS='(/paperclip/instances|/mnt/user|/home/[A-Za-z0-9_.-]+/|/Users/[A-Za-z0-9_.-]+/)'
TOKENS='(gh[pousr]_[A-Za-z0-9]{10,}|github_pat_|sk-[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|BEGIN (RSA|OPENSSH|EC) PRIVATE KEY)'
HOSTS='(\.local\b|\.lan\b|\.internal\b)'

# Upstream test fixtures that legitimately contain fake home paths or
# addresses: one extended regex, matched against added lines of a patch.
FIXTURE_ALLOW='/Users/(yourname|votrenom)/|/home/(user|username)/'

check_files() {
  local label="$1" pattern="$2" hits
  hits="$(printf '%s\n' "$files" | grep -v -e '^catalog/fr.json$' -e '^patches/' \
    | xargs -r grep -nIE -- "$pattern" 2>/dev/null || true)"
  if [ -n "$hits" ]; then echo "LEAK ($label):"; echo "$hits" | head -n 10; fail=1; fi
}

# Patches (added lines only) and catalog: same patterns.
check_bulk() {
  local label="$1" pattern="$2" f hits
  for f in catalog/fr.json patches/*.patch; do
    [ -f "$f" ] || continue
    case "$f" in
      patches/*) hits="$(grep -nE '^\+' "$f" | grep -E -- "$pattern" | grep -vE -- "$FIXTURE_ALLOW" | head -n 5 || true)" ;;
      *) hits="$(grep -nIE -- "$pattern" "$f" | grep -vE -- "$FIXTURE_ALLOW" | head -n 5 || true)" ;;
    esac
    if [ -n "$hits" ]; then echo "LEAK ($label) in $f:"; echo "$hits" | cut -c1-200; fail=1; fi
  done
}

for spec in "private IPv4|$IPV4" "internal path|$PATHS" "token|$TOKENS" "internal host|$HOSTS"; do
  label="${spec%%|*}"; pattern="${spec#*|}"
  check_files "$label" "$pattern"
  check_bulk "$label" "$pattern"
done

if [ -n "${LEAK_EXTRA_PATTERN:-}" ]; then
  check_files "private name" "$LEAK_EXTRA_PATTERN"
  check_bulk "private name" "$LEAK_EXTRA_PATTERN"
else
  echo "warning: LEAK_EXTRA_PATTERN not set, private-name check skipped" >&2
  if [ "${REQUIRE_EXTRA_PATTERN:-0}" = 1 ]; then fail=1; fi
fi

[ "$fail" = 0 ] && echo "anti-leak: OK"
exit "$fail"
