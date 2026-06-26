# Budgets

Cites ADR-0003, ADR-0007, ADR-0008.

Budgets split into state-derived limits enforced by ticks and continuous limits enforced by the external runner wall.

## Default Budget Block

```yaml
budgets:
  max_active_implementers: 1
  max_active_reviewers: 1
  max_active_fixers: 1
  max_reviewer_fixer_cycles_per_change: 2
  max_runtime_minutes_per_loop: 30
  max_changed_files_without_human_review: 20
  kill_retries: 2
  require_human_approval_for_budget_increase: true
```

## Tick-Enforced Limits

- Active implementers, reviewers, and fixers: count labels, open branches, and active markers before starting work.
- Reviewer/fixer cycle cap: read marker `cycle=<n>`.
- Changed files: inspect the local diff summary before push or handoff.
- Budget increases: require explicit human approval and record it in the host conversation or PR.

## Runner-Enforced Limits

Runtime and cost can be exceeded while the agent is busy, so the runner must wrap every tick in an external wall. Local cron uses `timeout`; GitHub Actions uses `timeout-minutes`; `/loop` runners must include the same wall in the command they invoke.

## Killed Ticks

On a wall kill, the next tick reconstructs state. Release the claim if safe, retry up to `kill_retries`, then post a `stalled` marker and route to human.
