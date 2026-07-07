# State Model

Cites ADR-0001, ADR-0002, ADR-0003, ADR-0005, ADR-0008.

Ticks have zero memory. Cross-tick state is only labels plus marker comments on the host.

## Labels

Required coarse labels:

- `ready`: trusted work is available for implementer intake.
- `in-progress`: claimed or under active loop work.
- `needs-fix`: reviewer found defects or proof failed.
- `ready-for-human`: autonomous loop has reached a human handoff after configured local proof, autonomous review, external inline bot review intake, and hosted-check classification.

Terminal outcome labels (each is its own label, never co-applied with `ready-for-human`, so the board is filterable and `ready-for-human` alone always means "proven and converged"):

- `unproven`: proof is absent, the proof command itself was invented or changed by the agent and not yet human accepted, or objective proof cannot be run.
- `did-not-converge`: cycle cap reached with blocking defects.
- `stalled`: repeated runner kills exceeded retry budget.

## Marker Grammar

Every marker is versioned and starts on the first line of a host comment:

```text
<!-- loop:<role> v=1 reviewed_sha=<sha> verdict=<verdict> cycle=<n> ts=<iso> -->
```

Parse fields as whitespace-delimited `key=value` pairs inside the comment. Valid roles are `implementer`, `reviewer`, and `fixer`. `reviewed_sha` is the commit SHA the role acted on. `cycle` is an integer reviewer/fixer cycle count. `ts` is an ISO-8601 UTC timestamp.

Recommended verdicts:

- `claimed`
- `implemented`
- `proof-passed`
- `proof-failed`
- `needs-fix`
- `fixed`
- `ready-for-human`
- `unproven`
- `did-not-converge`
- `stalled`
- `checks-pending`
- `no-op`

## Idempotence Rule

For each role, read the latest marker for the item and compare `reviewed_sha` to the current head from `get_head_sha`.

- Same SHA: this role already acted on this head; post no duplicate work unless releasing a stale claim.
- Different SHA: a real new commit exists; run the role playbook.

Labels help humans scan state. Markers are commit-scoped truth.
