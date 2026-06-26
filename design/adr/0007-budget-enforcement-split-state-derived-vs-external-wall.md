# Budget enforcement: state-derived at the tick, continuous at an external wall

An agent cannot reliably police its own runtime/cost — it blows a cap precisely when stuck, which is when the cap matters most. We split budgets into two classes with two enforcers:

- **State-derived budgets** (reviewer↔fixer cycle count, changed-files, active-loop concurrency) are readable from host/repo state at tick boundaries and enforced **by the tick deterministically**. `max_reviewer_fixer_cycles` is already enforced via ADR-0003 reading `cycle=N`; changed-files via `git diff --numstat` before push; concurrency by counting active claims.
- **Continuous-resource budgets** (wall-clock runtime, token/cost within one tick) cannot be caught by a boundary check because the runaway happens *between* checks. These are enforced by an **external wall in the emitted runner** — `timeout 30m claude ...` or the CI/job equivalent — which the agent cannot exceed because the OS/CI kills it.

Core principle: **the agent is never the enforcer of a limit that can be exceeded while the agent is busy.** This works only because ticks are idempotent and stateless (ADR-0001), so a killed tick is harmless and the next tick re-derives state.

This also sharpens the gap-#1 deliverable: the emitted runner is not "a command," it is **a command wrapped in a resource wall** — a concrete, testable artifact.

## Killed-tick outcome

On external-wall kill: release the Work Claim and retry up to a small kill-retry count (e.g. 2); on further timeouts, flag `stalled` for human triage. Repeated timeouts on one item mean "too big" — signal, like `did-not-converge` (ADR-0003) and `unproven` (ADR-0005).

## Considered Options

- **Agent self-restraint** — fails exactly when it matters. Rejected.
- **loopctl resource-limiting wrapper** — that is the deferred runtime framework; (B) achieves it with no new code. Rejected for V1.
