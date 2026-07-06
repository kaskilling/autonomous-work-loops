#!/usr/bin/env bash
# Create or update the GitHub labels required by autonomous-work-loops.
set -euo pipefail

repo_arg=()
if [ "${1:-}" != "" ]; then
  repo_arg=(--repo "$1")
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "Missing GitHub CLI: install gh and run gh auth login first." >&2
  exit 1
fi

gh auth status >/dev/null

gh label create ready --color 0E8A16 --description "Trusted work ready for autonomous-work-loops intake" --force "${repo_arg[@]}"
gh label create in-progress --color FBCA04 --description "Autonomous-work-loops has claimed this work" --force "${repo_arg[@]}"
gh label create needs-fix --color D93F0B --description "Reviewer found blocking defects or proof failed" --force "${repo_arg[@]}"
gh label create ready-for-human --color 5319E7 --description "Proof passed and autonomous review converged" --force "${repo_arg[@]}"
gh label create unproven --color BFDADC --description "No accepted proof command is configured or available" --force "${repo_arg[@]}"
gh label create did-not-converge --color B60205 --description "Review/fix cycle cap reached with blockers remaining" --force "${repo_arg[@]}"
gh label create stalled --color 000000 --description "Runner exceeded retry or runtime wall and needs a human" --force "${repo_arg[@]}"

echo "autonomous-work-loops labels are ready."
