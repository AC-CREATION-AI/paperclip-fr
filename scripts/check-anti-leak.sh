#!/usr/bin/env bash
# Fails if a tracked file (patches excluded from the IP rule only for upstream test fixtures)
# contains an internal address, an internal path, a token-looking string or a client name.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
fail=0
files="$(git ls-files 2>/dev/null || find . -type f -not -path './.git/*')"
files="$(printf '%s\n' "$files" | grep -v -e '^scripts/check-anti-leak.sh$' -e '^catalog/fr.json$' -e '^patches/')"

check() {
  local label="$1" pattern="$2"
  local hits
  hits="$(printf '%s\n' "$files" | xargs -r grep -nIE -- "$pattern" 2>/dev/null || true)"
  if [ -n "$hits" ]; then echo "LEAK ($label):"; echo "$hits" | head -n 10; fail=1; fi
}

check "private IPv4" '\b(10\.[0-9]+\.[0-9]+\.[0-9]+|192\.168\.[0-9]+\.[0-9]+|172\.(1[6-9]|2[0-9]|3[01])\.[0-9]+\.[0-9]+)\b'
check "internal path" '(/paperclip/instances|/mnt/user|/home/[a-z]+/|/Users/[A-Za-z]+/)'
check "token" '(ghp_|gho_|ghu_|github_pat_|sk-[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|BEGIN (RSA|OPENSSH|EC) PRIVATE KEY)'
check "internal host" '(\.local\b|\.lan\b|\.internal\b|gitea|francetv|france[ -]?tv|ztalent)'

# Catalog and patches: same checks, except upstream wording.
for f in catalog/fr.json patches/*.patch; do
  [ -f "$f" ] || continue
  hits="$(grep -nIE '(192\.168\.[0-9]+\.[0-9]+|/paperclip/instances|/mnt/user|ghp_|github_pat_|sk-[A-Za-z0-9]{20,}|francetv|ztalent)' "$f" | head -n 5 || true)"
  if [ -n "$hits" ]; then echo "LEAK in $f:"; echo "$hits"; fail=1; fi
done

[ "$fail" = 0 ] && echo "anti-leak: OK"
exit "$fail"
