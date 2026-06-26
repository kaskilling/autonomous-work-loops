# Convergence

Cites ADR-0002, ADR-0003, ADR-0005, ADR-0007, ADR-0010.

Convergence is marker-derived. A tick never relies on remembered prior outcomes.

## Outcomes

- `ready-for-human`: proof passed, current head has no blocking defects, and at least one fixer cycle has run.
- `needs-fix`: proof failed, blocking defects exist, or the mandatory first hardening cycle has not run.
- `did-not-converge`: cycle cap reached with blocking defects still unresolved.
- `unproven`: proof is absent, newly agent-authored proof has not been human accepted, or objective proof cannot be run.
- `stalled`: repeated external-wall kills exceeded `kill_retries`.

## Cycle Rules

Read latest markers with `read_markers`.

- Reviewer creates or updates the cycle when it sends work to Fixer.
- Fixer preserves the current cycle when addressing feedback.
- A completed fixer marker proves at least one fix cycle ran.
- `max_reviewer_fixer_cycles_per_change` is the hard cap. Never exceed it.

At cap:

- Non-blocking items only: set `ready-for-human` and list the known remaining items in the marker body.
- Any blocking item: set `did-not-converge`, route to human, and list the blocking items.

## Proof Rules

Proof present and passing allows normal convergence. Proof present and failing routes to `needs-fix`. Proof absent routes to `unproven`; no-proof repos never auto-converge under same-model review.
