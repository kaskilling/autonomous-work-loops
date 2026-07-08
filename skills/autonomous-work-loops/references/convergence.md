# Convergence

Cites ADR-0002, ADR-0003, ADR-0005, ADR-0007, ADR-0010.

Convergence is marker-derived. A tick never relies on remembered prior outcomes.

## Outcomes

- `ready-for-human`: configured local proof passed, autonomous review found no blocking defects, external inline bot review comments for the current head were absent or already addressed, and hosted checks are green, skipped, neutral, or absent. A clean first review converges immediately only after these host checks settle.
- `ready-for-human-baseline-red`: configured local proof and autonomous review passed, but hosted checks failed only where the same check names are already failing on the default branch.
- `needs-fix`: proof failed or blocking defects exist.
- `checks-pending`: local proof and autonomous review passed, but hosted checks were still pending at the wait budget. This is non-terminal; a later reviewer tick re-checks the same head.
- `did-not-converge`: cycle cap reached with blocking defects still unresolved.
- `unproven`: proof is absent, the proof command itself was invented or changed by the agent and has not been human accepted, or objective proof cannot be run.
- `stalled`: repeated external-wall kills exceeded `kill_retries`.

## Cycle Rules

Read latest markers with `read_markers`.

- A clean, proven first pass converges with no fix cycle after hosted checks and external inline bot comments are classified. Cycles happen only when the reviewer finds real blocking defects, external inline bot comments, or non-baseline hosted failures.
- Reviewer creates or updates the cycle when it sends work to Fixer.
- Fixer preserves the current cycle when addressing feedback.
- `max_reviewer_fixer_cycles_per_change` is the hard cap on how many review→fix rounds a change may take before escalation. Never exceed it.

At cap:

- Non-blocking items only: set `ready-for-human` and list the known remaining items in the marker body. If the only hosted blocker is a default-branch baseline failure, set `ready-for-human-baseline-red`.
- Any blocking item: set `did-not-converge`, route to human, and list the blocking items.

## Proof Rules

Proof present and passing allows the reviewer to inspect the change, but hosted checks are still part of final handoff. Proof present and failing routes to `needs-fix`. Proof absent routes to `unproven`; no-proof repos never auto-converge under same-model review. Agent-added tests under an existing configured proof command count as normal proof. Inventing or changing the proof command itself is a human gate until accepted.

## Hosted Check Rules

Before setting a human-handoff label, the reviewer waits for hosted PR checks up to the configured wait budget.

- Pending after the wait: post `checks-pending`, leave labels non-terminal, and let a later tick retry.
- Failed and not known to fail on the default branch: route to `needs-fix`.
- Failed but the same check name is already failing on the default branch: set `ready-for-human-baseline-red` and include the baseline classification in the marker body.
- Green, skipped, neutral, or absent checks: allow normal convergence after local review passes.

Marker comments should be readable summaries, not raw logs. Keep the hidden
`<!-- loop:... -->` marker machine-readable, then show a short verdict, reason,
next action, and sanitized hosted-check or review excerpt when useful.
