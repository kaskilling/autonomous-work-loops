# Convergence requires at least one fix cycle, with bounded escalation

The Reviewer Loop may flip a change to `ready-for-human` only when (i) the current head SHA has no blocking feedback **and** (ii) at least one Fixer cycle has already run (a prior `needs-fix` → fix → re-review transition exists in the markers). Even a suspiciously-clean first draft gets one mandatory adversarial hardening round. This encodes the actual value the source video demonstrated: the review↔fix back-and-forth, not a first-pass rubber stamp.

Termination is bounded by `max_reviewer_fixer_cycles_per_change`:
- At cap with only **non-blocking** items remaining → flip to `ready-for-human`, listing the remaining items in the marker/comment so the human inherits a known state.
- At cap with **blocking** items still unresolved → escalate to a human gate (`ready-for-human` + a `did-not-converge` flag). Never exceed the cap.

## Considered Options

- **Approve-on-clean (no fix-cycle requirement)** — risks handing raw first-draft agent code to the human, the exact thing the loop should harden first. Rejected.
- **Two consecutive clean passes** — with SHA-stamping (ADR-0002), a second pass on an unchanged head is a pure no-op that costs a tick and learns nothing. Rejected.
- **Bounce back past the cap on blocking items** — an unbounded loop on a hard problem is the cost-runaway failure mode budgets exist to prevent. Rejected.

## Consequences

- "Has a fix cycle run?" and "are we at the cap?" are both answered by reading marker comments (`cycle=N`, prior `verdict=needs-fix`) — no agent memory, consistent with ADR-0001/0002.
- A `did-not-converge` outcome is a first-class state the human must be able to see and triage.
