#!/usr/bin/env bash
# Usage: run-tick.sh <repo_path> <role> [model] -- run one codex tick of one role
set -euo pipefail

repo="$1"
role="$2"
model="${3:-}"
prompt="Load the autonomous-work-loops skill and run exactly one ${role} tick in this repository, following its tick-mode instructions. Reconstruct all state from host (GitHub labels + marker comments) and .agent-loops/ before acting. Do one unit of work and exit. Do not ask questions; record any blocker as a marker/evidence note."
ts="$(date +%Y%m%d-%H%M%S)"
raw="${RAW_EVIDENCE:-/Users/mkamar/Non_Work/Projects/autonomous-work-loops-lab/evidence/validation/prove-the-gate}"
mkdir -p "$raw/logs"
log="$raw/logs/gate-${role}-${ts}.log"
cd "$repo"
net="sandbox_workspace_write.network_access=true"
if [ -n "$model" ]; then
  codex exec --cd "$repo" -s workspace-write -c approval_policy='"never"' -c "$net" -c "model=\"$model\"" "$prompt" > "$log" 2>&1
else
  codex exec --cd "$repo" -s workspace-write -c approval_policy='"never"' -c "$net" "$prompt" > "$log" 2>&1
fi
echo "$log"
