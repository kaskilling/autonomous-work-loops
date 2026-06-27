#!/usr/bin/env bash
# Usage: snapshot.sh <owner/repo>
set -euo pipefail

repo="$1"
echo "### snapshot $(date -u +%FT%TZ) $repo"
echo "-- issues --"
gh issue list --repo "$repo" --state open --json number,title,labels \
  --jq '.[] | "#\(.number) [\([.labels[].name]|join(","))] \(.title)"'
echo "-- PRs --"
gh pr list --repo "$repo" --state open --json number,headRefName,labels \
  --jq '.[] | "PR#\(.number) \(.headRefName) [\([.labels[].name]|join(","))]"'
echo "-- loop branches --"
git ls-remote --heads "https://github.com/${repo}.git" 'refs/heads/loop/*' 2>/dev/null | awk '{print $2}' || true
echo "-- latest markers (per open PR) --"
for pr in $(gh pr list --repo "$repo" --state open --json number --jq '.[].number'); do
  gh pr view "$pr" --repo "$repo" --json comments \
    --jq '.comments[].body | select(test("<!-- loop:"))' 2>/dev/null | tail -3
done
