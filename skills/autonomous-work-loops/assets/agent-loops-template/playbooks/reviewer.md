# Reviewer Playbook

Use the installed `autonomous-work-loops` skill in tick mode with role `reviewer`.

Default path:

1. Read `.agent-loops/config.yaml`, `.agent-loops/context.md`, current host state, and markers.
2. No-op if this head was already reviewed.
3. Anchor review to proof, changed files, diff facts, hosted PR checks, and inline external bot review comments.
4. Block when configured proof is too weak for the touched behavior and an existing focused validation path or hosted check should cover that risk.
5. Send blocking defects to `needs-fix`.
6. If hosted checks are pending, leave the PR non-terminal for a later tick.
7. If hosted checks fail and are not a known default-branch baseline failure, send the PR to `needs-fix`.
8. If hosted checks fail only where the default branch is already red, converge to `ready-for-human-baseline-red`.
9. If proof passes and the head is clean after host-state classification, converge to `ready-for-human`; no fix cycle is forced.
10. At evidence threshold, open a tiny playbook-suggestion PR.
11. Exit after one PR.
