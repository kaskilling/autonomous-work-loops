#!/usr/bin/env bash
# Usage: run-guarded-tick.sh <repo_path> <role> [model]
#
# Managed Codex sandboxes can edit workspace files but may not write .git.
# This runner keeps GitHub/Git mutation in the parent shell and uses nested
# Codex only for workspace edits or review text.
set -euo pipefail

repo="${1:?repo path required}"
role="${2:?role required}"
model="${3:-}"
mins="${GUARDED_TIMEOUT_MINUTES:-30}"
raw="${RAW_EVIDENCE:-${repo}/.agent-loops/evidence/prove-the-gate}"
mkdir -p "$raw/logs"

cd "$repo"

wall() {
  if command -v timeout >/dev/null 2>&1; then timeout "${mins}m" "$@"; return; fi
  if command -v gtimeout >/dev/null 2>&1; then gtimeout "${mins}m" "$@"; return; fi
  ( "$@" ) & local pid=$!
  ( sleep "$((mins*60))" && kill -TERM "$pid" 2>/dev/null ) & local killer=$!
  wait "$pid"; local rc=$?; kill "$killer" 2>/dev/null || true; return $rc
}

cfg() {
  python3 - "$1" <<'PY'
import ast
import sys
from pathlib import Path

key = sys.argv[1]
lines = Path(".agent-loops/config.yaml").read_text().splitlines()

def scalar(name, default=""):
    for raw in lines:
        line = raw.strip()
        if line.startswith(name + ":"):
            return line.split(":", 1)[1].split("#", 1)[0].strip().strip('"\'')
    return default

def proof(name):
    in_proof = False
    for raw in lines:
        if raw.startswith("proof:"):
            in_proof = True
            continue
        if in_proof and raw and not raw.startswith((" ", "\t")):
            break
        if in_proof and raw.strip().startswith(name + ":"):
            return raw.split(":", 1)[1].split("#", 1)[0].strip().strip('"\'')
    return ""

def trusted():
    for i, raw in enumerate(lines):
        line = raw.strip()
        if not line.startswith("trusted_actors:"):
            continue
        value = line.split(":", 1)[1].split("#", 1)[0].strip()
        if value.startswith("["):
            print("\n".join(ast.literal_eval(value)))
            return
        if value == "":
            out = []
            for nxt in lines[i + 1:]:
                if nxt and not nxt.startswith((" ", "\t", "-")):
                    break
                item = nxt.strip()
                if item.startswith("-"):
                    out.append(item[1:].strip().strip('"\''))
            print("\n".join(out))
            return
    return

if key.startswith("proof."):
    print(proof(key.split(".", 1)[1]))
elif key == "trusted_actors":
    trusted()
elif key.startswith("labels."):
    print(scalar(key.split(".", 1)[1], key.split(".", 1)[1].replace("_", "-")))
else:
    print(scalar(key))
PY
}

label_ready="$(cfg labels.ready)"
label_in_progress="$(cfg labels.in_progress)"
label_needs_fix="$(cfg labels.needs_fix)"
label_ready_for_human="$(cfg labels.ready_for_human)"
label_unproven="$(cfg labels.unproven)"
trust_posture="$(cfg trust_posture)"
branch_prefix="$(cfg branch_prefix)"
branch_prefix="${branch_prefix:-loop/impl/issue-}"

ts() { date -u +%Y-%m-%dT%H:%M:%SZ; }

trusted_actor() {
  local actor="$1"
  if [ "$trust_posture" != "strict" ]; then
    return 0
  fi
  cfg trusted_actors | grep -Fxq "$actor"
}

stale_issue() {
  local repo_slug="$1" issue="$2" branch marker_ts
  branch="${branch_prefix}${issue}"
  if git ls-remote --heads origin "refs/heads/${branch}" | grep -q .; then
    return 1
  fi
  marker_ts="$(gh issue view "$issue" --repo "$repo_slug" --json comments --jq '.comments[].body | select(test("<!-- loop:implementer"))' | sed -n 's/.* ts=\([^ ]*\) -->.*/\1/p' | tail -1)"
  [ -n "$marker_ts" ] || return 1
  python3 - "$marker_ts" <<'PY'
from datetime import datetime, timezone, timedelta
import sys

raw = sys.argv[1].replace("Z", "+00:00")
try:
    ts = datetime.fromisoformat(raw)
except ValueError:
    sys.exit(1)
if ts.tzinfo is None:
    ts = ts.replace(tzinfo=timezone.utc)
sys.exit(0 if datetime.now(timezone.utc) - ts > timedelta(minutes=90) else 1)
PY
}

default_branch() {
  git remote show origin | sed -n '/HEAD branch/s/.*: //p'
}

run_proof() {
  local log="$1"
  : > "$log"
  local any=0
  local cmd
  for key in build lint test; do
    cmd="$(cfg "proof.${key}")"
    [ -n "$cmd" ] || continue
    any=1
    {
      printf '$ %s\n' "$cmd"
      PYTHONDONTWRITEBYTECODE=1 bash -lc "$cmd"
    } >>"$log" 2>&1 || return 1
  done
  [ "$any" = 1 ] || return 2
}

post_pr_marker() {
  local pr="$1" marker="$2" body="$3" file
  file="$(mktemp)"
  {
    printf '%s\n\n' "$marker"
    printf '%s\n' "$body"
  } > "$file"
  gh pr comment "$pr" --body-file "$file" >/dev/null
  rm -f "$file"
}

open_or_update_pr() {
  local issue="$1" branch="$2" title="$3" body_file="$4"
  local pr
  pr="$(gh pr list --repo "$(gh repo view --json nameWithOwner --jq .nameWithOwner)" --head "$branch" --json number --jq '.[0].number // empty')"
  if [ -n "$pr" ]; then
    gh pr edit "$pr" --body-file "$body_file" >/dev/null
    printf '%s\n' "$pr"
    return
  fi
  gh pr create --base "$(default_branch)" --head "$branch" --title "$title" --body-file "$body_file" | sed 's#.*/pull/##'
}

stage_non_generated() {
  python3 - <<'PY' | while IFS= read -r path; do git add "$path"; done
import subprocess
skip = ("/__pycache__/", "__pycache__/", ".pyc")
out = subprocess.check_output(["git", "status", "--porcelain"], text=True)
for line in out.splitlines():
    if not line:
        continue
    path = line[3:]
    if any(s in path for s in skip) or path.endswith(".pyc"):
        continue
    print(path)
PY
}

implementer() {
  local repo_slug issue actor branch base title body claim_sha proof_log pr_body pr head_sha proof_rc log
  repo_slug="$(gh repo view --json nameWithOwner --jq .nameWithOwner)"

  local active_block=0
  while IFS=$'\t' read -r issue actor title; do
    [ -n "$issue" ] || continue
    trusted_actor "$actor" || continue
    if stale_issue "$repo_slug" "$issue"; then
      gh issue comment "$issue" --repo "$repo_slug" --body "<!-- loop:implementer v=1 reviewed_sha=stale verdict=no-op cycle=0 ts=$(ts) -->

Stale in-progress claim detected with no claim branch. Releasing the advisory label so the guarded runner can reclaim through the normal trust and branch-ref path." >/dev/null
      gh issue edit "$issue" --repo "$repo_slug" --remove-label "$label_in_progress" --add-label "$label_ready" >/dev/null
    else
      active_block=1
    fi
  done < <(gh issue list --repo "$repo_slug" --state open --label "$label_in_progress" --json number,title,author --jq '.[] | [.number, .author.login, .title] | @tsv')

  if [ "$active_block" = 1 ]; then
    echo "implementer budget full: active in-progress issue exists"
    return 0
  fi

  while IFS=$'\t' read -r issue actor title; do
    [ -n "$issue" ] || continue
    trusted_actor "$actor" || continue

    branch="${branch_prefix}${issue}"
    if git ls-remote --heads origin "refs/heads/${branch}" | grep -q .; then
      echo "claim already exists for issue #${issue}: ${branch}"
      return 0
    fi

    git fetch origin
    base="$(default_branch)"
    git switch -c "$branch" "origin/$base"
    git commit --allow-empty -m "Claim issue #${issue}"
    claim_sha="$(git rev-parse HEAD)"
    if ! git push origin "HEAD:refs/heads/${branch}"; then
      echo "lost claim race for issue #${issue}"
      return 0
    fi
    gh issue edit "$issue" --repo "$repo_slug" --remove-label "$label_ready" --add-label "$label_in_progress" >/dev/null

    body="$(gh issue view "$issue" --repo "$repo_slug" --json body --jq .body)"
    log="$raw/logs/guarded-implementer-$(date -u +%Y%m%d-%H%M%S)-issue-${issue}.log"
    local prompt="You are implementing already-claimed GitHub issue #${issue} on branch ${branch}.

Issue title: ${title}
Issue body:
${body}

    Edit the working tree only. Do not run git. Do not run gh. Do not create commits, branches, PRs, labels, or marker comments. Do not edit .agent-loops unless the issue explicitly requires it. Implement the smallest complete change and exit."
    if [ -n "$model" ]; then
      wall codex exec --cd "$repo" -s workspace-write -c approval_policy='"never"' -c sandbox_workspace_write.network_access=true -c "model=\"$model\"" "$prompt" >"$log" 2>&1
    else
      wall codex exec --cd "$repo" -s workspace-write -c approval_policy='"never"' -c sandbox_workspace_write.network_access=true "$prompt" >"$log" 2>&1
    fi

    proof_log="$raw/logs/guarded-proof-$(date -u +%Y%m%d-%H%M%S)-issue-${issue}.log"
    set +e
    run_proof "$proof_log"
    proof_rc=$?
    set -e

    stage_non_generated
    if git diff --cached --quiet; then
      echo "no implementation diff for issue #${issue}; leaving claim for human inspection"
      return 1
    fi
    git commit -m "Implement issue #${issue}"
    head_sha="$(git rev-parse HEAD)"
    git push origin "HEAD:refs/heads/${branch}"

    pr_body="$(mktemp)"
    {
      printf 'Closes #%s.\n\n' "$issue"
      printf 'Proof:\n'
      if [ "$proof_rc" = 0 ]; then
        tail -20 "$proof_log" | sed 's/^/- /'
      elif [ "$proof_rc" = 2 ]; then
        printf -- '- no configured proof command; routing to unproven\n'
      else
        tail -40 "$proof_log" | sed 's/^/- /'
      fi
    } > "$pr_body"
    pr="$(open_or_update_pr "$issue" "$branch" "$title" "$pr_body")"
    rm -f "$pr_body"

    if [ "$proof_rc" = 0 ]; then
      post_pr_marker "$pr" "<!-- loop:implementer v=1 reviewed_sha=${head_sha} verdict=proof-passed cycle=0 ts=$(ts) -->" "Guarded implementer committed and pushed issue #${issue}. Proof passed; see ${proof_log}."
    elif [ "$proof_rc" = 2 ]; then
      post_pr_marker "$pr" "<!-- loop:implementer v=1 reviewed_sha=${head_sha} verdict=unproven cycle=0 ts=$(ts) -->" "Guarded implementer committed and pushed issue #${issue}, but no proof command is configured."
      gh issue edit "$issue" --repo "$repo_slug" --remove-label "$label_in_progress" --add-label "$label_unproven" >/dev/null
      gh pr edit "$pr" --repo "$repo_slug" --add-label "$label_unproven" >/dev/null
    else
      post_pr_marker "$pr" "<!-- loop:implementer v=1 reviewed_sha=${head_sha} verdict=proof-failed cycle=0 ts=$(ts) -->" "Guarded implementer committed and pushed issue #${issue}, but proof failed; see ${proof_log}."
      gh issue edit "$issue" --repo "$repo_slug" --remove-label "$label_in_progress" --add-label "$label_needs_fix" >/dev/null
      gh pr edit "$pr" --repo "$repo_slug" --add-label "$label_needs_fix" >/dev/null
    fi
    return 0
  done < <(gh issue list --repo "$repo_slug" --state open --label "$label_ready" --json number,title,author --jq '.[] | [.number, .author.login, .title] | @tsv')

  echo "no trusted ready work"
}

reviewer() {
  local repo_slug pr branch head proof_log proof_rc labels
  repo_slug="$(gh repo view --json nameWithOwner --jq .nameWithOwner)"
  while IFS=$'\t' read -r pr branch labels; do
    [ -n "$pr" ] || continue
    case ",$labels," in
      *",$label_ready_for_human,"*|*",$label_needs_fix,"*|*",$label_unproven,"*) continue ;;
    esac
    git fetch origin "$branch"
    git switch -C "$branch" "origin/$branch"
    head="$(git rev-parse HEAD)"
    proof_log="$raw/logs/guarded-review-proof-$(date -u +%Y%m%d-%H%M%S)-pr-${pr}.log"
    set +e
    run_proof "$proof_log"
    proof_rc=$?
    set -e
    if [ "$proof_rc" = 0 ]; then
      post_pr_marker "$pr" "<!-- loop:reviewer v=1 reviewed_sha=${head} verdict=ready-for-human cycle=0 ts=$(ts) -->" "Guarded reviewer reran configured proof successfully; see ${proof_log}."
      gh pr edit "$pr" --repo "$repo_slug" --add-label "$label_ready_for_human" >/dev/null
      local issue
      issue="$(gh pr view "$pr" --repo "$repo_slug" --json closingIssuesReferences --jq '.closingIssuesReferences[0].number // empty')"
      if [ -z "$issue" ]; then
        issue="${branch#${branch_prefix}}"
      fi
      if [ -n "$issue" ]; then
        gh issue edit "$issue" --repo "$repo_slug" --remove-label "$label_in_progress" --add-label "$label_ready_for_human" >/dev/null
      fi
    elif [ "$proof_rc" = 2 ]; then
      post_pr_marker "$pr" "<!-- loop:reviewer v=1 reviewed_sha=${head} verdict=unproven cycle=0 ts=$(ts) -->" "Guarded reviewer found no configured proof command."
      gh pr edit "$pr" --repo "$repo_slug" --add-label "$label_unproven" >/dev/null
    else
      post_pr_marker "$pr" "<!-- loop:reviewer v=1 reviewed_sha=${head} verdict=needs-fix cycle=1 ts=$(ts) -->" "Guarded reviewer reran proof and it failed; see ${proof_log}."
      gh pr edit "$pr" --repo "$repo_slug" --add-label "$label_needs_fix" >/dev/null
    fi
    return 0
  done < <(gh pr list --repo "$repo_slug" --state open --json number,headRefName,labels --jq '.[] | select(.headRefName | startswith("loop/impl/issue-")) | [.number, .headRefName, ([.labels[].name] | join(","))] | @tsv')
  echo "no reviewable loop PR"
}

case "$role" in
  implementer) implementer ;;
  reviewer) reviewer ;;
  fixer) echo "guarded fixer is not implemented yet"; exit 2 ;;
  *) echo "unknown role: $role" >&2; exit 2 ;;
esac
