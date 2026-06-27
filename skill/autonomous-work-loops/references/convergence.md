# Convergence

Cites ADR-0002, ADR-0003, ADR-0005, ADR-0007, ADR-0010.

Convergence is marker-derived. A tick never relies on remembered prior outcomes.

## Outcomes

- `ready-for-human`: proof passed and the current head has no blocking defects. A clean first review converges immediately.
- `needs-fix`: proof failed or blocking defects exist.
- `did-not-converge`: cycle cap reached with blocking defects still unresolved.
- `unproven`: proof is absent, the proof command itself was invented or changed by the agent and has not been human accepted, or objective proof cannot be run.
- `stalled`: repeated external-wall kills exceeded `kill_retries`.

## Cycle Rules

Read latest markers with `read_markers`.

- A clean, proven first pass converges with no fix cycle. Cycles happen only when the reviewer finds real blocking defects.
- Reviewer creates or updates the cycle when it sends work to Fixer.
- Fixer preserves the current cycle when addressing feedback.
- `max_reviewer_fixer_cycles_per_change` is the hard cap on how many review→fix rounds a change may take before escalation. Never exceed it.

At cap:

- Non-blocking items only: set `ready-for-human` and list the known remaining items in the marker body.
- Any blocking item: set `did-not-converge`, route to human, and list the blocking items.

## Proof Rules

Proof present and passing allows normal convergence. Proof present and failing routes to `needs-fix`. Proof absent routes to `unproven`; no-proof repos never auto-converge under same-model review. Agent-added tests under an existing configured proof command count as normal proof. Inventing or changing the proof command itself is a human gate until accepted.
