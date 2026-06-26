# Fixer Tick

Cites ADR-0001, ADR-0002, ADR-0003, ADR-0005, ADR-0006, ADR-0007, ADR-0009.

Goal: address one Reviewer feedback set on the current PR head, rerun proof, post a marker, and return the change to review or a human gate.

## Steps

1. Read `.agent-loops/config.yaml`, then call `read_state`, `get_head_sha`, and `read_markers` for PRs labeled `needs-fix`.
2. If the latest fixer marker has this head SHA and there are no newer reviewer defects, no-op and exit.
3. Enforce fixer concurrency, changed-file, and cycle budgets.
4. Read the latest reviewer marker and human-visible feedback. Classify blocking and non-blocking items.
5. Fix only the blocking items needed for the current cycle unless non-blocking cleanup is tiny and directly adjacent.
6. Run configured proof commands. If proof is absent, route to `unproven`; do not send the PR back into autonomous convergence.
7. If proof passes, call `post_marker` with `verdict=fixed`, the current head SHA, and the cycle number, then call `set_label` back to `in-progress` for reviewer pickup.
8. If proof fails, call `post_marker` with `verdict=proof-failed`, keep or set `needs-fix`, append the failure summary, and exit.
9. Append evidence for repeated failure themes or repo-specific rules that would help future ticks.

## Exit

Exit after one PR. Do not chain into review in the same invocation.
