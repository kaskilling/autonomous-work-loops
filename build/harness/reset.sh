#!/usr/bin/env bash
# Usage: reset.sh <owner/repo> -- return to clean loop state (issues kept, loop artifacts removed)
set -euo pipefail

repo="$1"

for pr in $(gh pr list --repo "$repo" --state open --json number,headRefName --jq '.[]|select(.headRefName|startswith("loop/"))|.number'); do
  gh pr close "$pr" --repo "$repo" --delete-branch 2>/dev/null || true
done

for ref in $(git ls-remote --heads "https://github.com/${repo}.git" 'refs/heads/loop/*' 2>/dev/null | awk '{print $2}' | sed 's#refs/heads/##'); do
  gh api -X DELETE "repos/${repo}/git/refs/heads/${ref}" 2>/dev/null || true
done

for n in $(gh issue list --repo "$repo" --state all --json number --jq '.[].number'); do
  for lbl in in-progress needs-fix ready-for-human unproven did-not-converge stalled ready; do
    gh issue edit "$n" --repo "$repo" --remove-label "$lbl" 2>/dev/null || true
  done
done

echo "reset $repo to clean state"
