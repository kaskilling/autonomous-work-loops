# Cross-tick state lives in labels plus SHA-stamped marker comments

Because ticks carry zero agent memory (see ADR-0001), cross-tick state must be readable from the host. We decided to use **labels** for coarse, human-visible workflow state (`ready` / `in-progress` / `needs-fix` / `ready-for-human`) and a single machine-readable **marker comment** per role for fine, commit-scoped truth, e.g. `<!-- loop:reviewer v=1 reviewed_sha=def123 verdict=needs-fix cycle=2 -->`.

A tick reads the latest marker for its role, compares `reviewed_sha` to the current head SHA: equal → already done (idempotent no-op); different → real new commit, act. The SHA comparison simultaneously answers "did anything change?", "have I already done this?", and supplies the convergence signal.

## Considered Options

- **Label-only** — labels are not commit-scoped, so a reviewer cannot distinguish a stale re-trigger from a genuine new commit. Rejected: causes redundant re-reviews or premature approval.
- **Repo-committed state file** (`.agent-loops/state/<pr>.json`) — collides with PR branches, creates merge noise, duplicates host knowledge. Rejected: state about a PR belongs on the PR.

## Consequences

- The marker comment format is a versioned contract (`v=1`) that must be parsed reliably.
- Extends the Work Claim marker concept to review *state*, not just ownership.
- The Work Claim must be taken *before* the review, not after, to avoid overlapping ticks racing on "latest marker wins."
- Degrades to hosts without rich labels: the marker-comment pattern works anywhere text can attach to a change.
