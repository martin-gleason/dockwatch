#!/bin/zsh
# Created: 2026-10-18 19:25 -05:00 · Edited: 2026-10-18 19:25 -05:00
# C3-T4 — one secret scan for the pre-commit hook and CI (security review 2026-10-18, finding 4).
#   scan_secrets.sh --staged   every staged blob, binaries included, as the hook sees them
#   scan_secrets.sh --tree     every tracked file, as CI sees the checkout
# Prints each hit as path:line:match and exits 1 on any hit; exits 0 when clean.
set -u
here=${0:A:h}
patterns="$here/secret-patterns.txt"
mode=${1:-}
hits=0
case "$mode" in
  --staged)
    git diff --cached --name-only --diff-filter=ACMR -z | while IFS= read -r -d '' f; do
      [[ "$f" == "scripts/secret-patterns.txt" ]] && continue
      if out=$(git show ":$f" | grep -aEno -f "$patterns"); then
        printf '%s\n' "$out" | sed "s|^|$f:|"; hits=1
      fi
    done
    ;;
  --tree)
    git ls-files -z | while IFS= read -r -d '' f; do
      [[ "$f" == "scripts/secret-patterns.txt" ]] && continue
      if out=$(grep -aEno -f "$patterns" -- "$f"); then
        printf '%s\n' "$out" | sed "s|^|$f:|"; hits=1
      fi
    done
    ;;
  *) echo "usage: scan_secrets.sh --staged | --tree" >&2; exit 2 ;;
esac
exit $hits
