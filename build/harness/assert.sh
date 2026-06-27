#!/usr/bin/env bash
# Source this file; functions exit 1 on assertion failure.

_fail() {
  echo "ASSERT FAIL: $*" >&2
  return 1
}

assert_issue_label() {
  gh issue view "$2" --repo "$1" --json labels --jq '[.labels[].name]' | grep -q "\"$3\"" || _fail "issue #$2 missing label $3"
}

refute_issue_label() {
  gh issue view "$2" --repo "$1" --json labels --jq '[.labels[].name]' | grep -q "\"$3\"" && _fail "issue #$2 unexpectedly has label $3" || return 0
}

assert_no_loop_branch() {
  [ -z "$(git ls-remote --heads "https://github.com/$1.git" 'refs/heads/loop/*' 2>/dev/null)" ] || _fail "loop branch exists in $1"
}

assert_pr_label() {
  gh pr view "$2" --repo "$1" --json labels --jq '[.labels[].name]' | grep -q "\"$3\"" || _fail "PR #$2 missing label $3"
}

refute_any_pr() {
  [ "$(gh pr list --repo "$1" --state open --json number --jq 'length')" = "0" ] || _fail "unexpected open PR in $1"
}

assert_marker_verdict() {
  gh pr view "$2" --repo "$1" --json comments --jq '.comments[].body' | grep -q "verdict=$3" || _fail "PR #$2 missing marker verdict=$3"
}
