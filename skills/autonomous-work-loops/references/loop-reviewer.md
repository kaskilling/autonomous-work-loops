# Reviewer Tick

Cites ADR-0001, ADR-0002, ADR-0003, ADR-0005, ADR-0006, ADR-0007, ADR-0009, ADR-0010.

Goal: review one changed head adversarially, anchored to proof, diff facts, hosted checks, and external inline bot review comments, then route to `needs-fix`, `ready-for-human`, `ready-for-human-baseline-red`, `checks-pending`, `unproven`, or `did-not-converge`.

## Stance

Assume defects exist. Try to disconfirm the Implementer's claims. Inspect the actual diff, changed-file list, proof output, and repo conventions before trusting the PR body.

## Steps

1. Read `.agent-loops/config.yaml` and `.agent-loops/context.md`, especially `proof`, `reviewer_model`, labels, budgets, generated paths, and repo instruction files.
2. Call `read_state`, `get_head_sha`, and `read_markers` for candidate PRs.
3. If the latest reviewer marker has this head SHA, no-op and exit.
4. If proof commands are absent, call `post_marker` with `verdict=unproven`, call `set_label` to `unproven` (its own terminal label, NOT a human-handoff label), and exit. No-proof repos never auto-converge.
5. Enforce changed-file and reviewer concurrency budgets at tick boundary.
6. Re-run or inspect proof. Passing proof is required but not sufficient.
7. Inspect whether the proof is relevant to the changed behavior. If touched surfaces have existing focused validation in this repo, such as browser/UI flows, persistence, routing, auth, build config, API contracts, or migration behavior, require either configured proof, hosted checks, or a clear focused validation result that covers that risk. Missing relevant validation is blocking; invented commands or newly-authored harnesses are not accepted proof until human-approved.
8. Inspect the diff for correctness, tests, security impact, path-scoped human gates, generated files that should not be in the PR, and whether the issue was actually solved.
9. If proof fails or blocking defects exist, call `post_marker` with `verdict=needs-fix`, increment or preserve the cycle as described in `convergence.md`, call `set_label` to `needs-fix`, append evidence, and exit.
10. If local proof and review are clean, wait for hosted PR checks up to the configured wait budget, then read external inline bot review comments for the current head.
11. If hosted checks are still pending, call `post_marker` with `verdict=checks-pending`, leave the PR in non-terminal state, and exit so a later tick can re-check.
12. If external inline bot review comments exist for the current head, route to `needs-fix` and include the comment summary.
13. If hosted checks failed and the same check name is not failing on the default branch, route to `needs-fix`.
14. If hosted checks failed only where the same check names are failing on the default branch, call `post_marker` with `verdict=ready-for-human-baseline-red`, call `set_label` to `ready-for-human-baseline-red`, and include the baseline classification.
15. If only non-blocking defects remain at the cycle cap, call `post_marker` with `verdict=ready-for-human`, list remaining items, call `set_label` to `ready-for-human`, and exit.
16. If blocking defects remain at the cycle cap, call `post_marker` with `verdict=did-not-converge`, call `set_label` to `did-not-converge` (its own terminal label, NOT a human-handoff label), list the blocking items, route to human, and exit.
17. If the head is clean, proof passed, external inline review is clear, and hosted checks are green, skipped, neutral, or absent, call `post_marker` with `verdict=ready-for-human` and call `set_label` to `ready-for-human`. A clean first pass converges immediately after host-state classification; do not force a fixer cycle when there is nothing to fix.
18. At the end of a normal review, run the evidence threshold check from `evidence-capture.md`. If threshold is met, open one tiny playbook-suggestion PR.

## Review Notes

Write actionable feedback. Separate blocking defects from non-blocking notes. Tie each blocking defect to a file, behavior, proof failure, or stated requirement.
