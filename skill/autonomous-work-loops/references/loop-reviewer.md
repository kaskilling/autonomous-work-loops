# Reviewer Tick

Cites ADR-0001, ADR-0002, ADR-0003, ADR-0005, ADR-0006, ADR-0007, ADR-0009, ADR-0010.

Goal: review one changed head adversarially, anchored to proof and diff facts, then route to `needs-fix`, `ready-for-human`, `unproven`, or `did-not-converge`.

## Stance

Assume defects exist. Try to disconfirm the Implementer's claims. Inspect the actual diff, changed-file list, proof output, and repo conventions before trusting the PR body.

## Steps

1. Read `.agent-loops/config.yaml`, especially `proof`, `reviewer_model`, labels, and budgets.
2. Call `read_state`, `get_head_sha`, and `read_markers` for candidate PRs.
3. If the latest reviewer marker has this head SHA, no-op and exit.
4. If proof commands are absent, call `post_marker` with `verdict=unproven`, call `set_label` to `unproven` (its own terminal label, NOT `ready-for-human`), and exit. No-proof repos never auto-converge. This preserves the invariant that the `ready-for-human` label alone means "proven and converged."
5. Enforce changed-file and reviewer concurrency budgets at tick boundary.
6. Re-run or inspect proof. Passing proof is required but not sufficient.
7. Inspect the diff for correctness, tests, security impact, path-scoped human gates, and whether the issue was actually solved.
8. If proof fails or blocking defects exist, call `post_marker` with `verdict=needs-fix`, increment or preserve the cycle as described in `convergence.md`, call `set_label` to `needs-fix`, append evidence, and exit.
9. If only non-blocking defects remain at the cycle cap, call `post_marker` with `verdict=ready-for-human`, list remaining items, call `set_label` to `ready-for-human`, and exit.
10. If blocking defects remain at the cycle cap, call `post_marker` with `verdict=did-not-converge`, call `set_label` to `did-not-converge` (its own terminal label, NOT `ready-for-human`), list the blocking items, route to human, and exit.
11. If the head is clean and proof passed, call `post_marker` with `verdict=ready-for-human` and call `set_label` to `ready-for-human`. A clean first pass converges immediately — do NOT force a fixer cycle when there is nothing to fix. (Cycles arise only from real blocking defects found in step 8.)
12. At the end of a normal review, run the evidence threshold check from `evidence-capture.md`. If threshold is met, open one tiny playbook-suggestion PR.

## Review Notes

Write actionable feedback. Separate blocking defects from non-blocking notes. Tie each blocking defect to a file, behavior, proof failure, or stated requirement.
