# Reviewer Playbook

Use the installed `autonomous-work-loops` skill in tick mode with role `reviewer`.

Default path:

1. Read `.agent-loops/config.yaml`, `.agent-loops/context.md`, current host state, and markers.
2. No-op if this head was already reviewed.
3. Anchor review to proof, changed files, diff facts, hosted PR checks, and inline external bot review comments.
4. Send blocking defects to `needs-fix`.
5. If hosted checks are pending, leave the PR non-terminal for a later tick.
6. If hosted checks fail and are not a known default-branch baseline failure, send the PR to `needs-fix`.
7. If proof passes and the head is clean after host-state classification, converge to `ready-for-human` — no fix cycle is forced.
8. At evidence threshold, open a tiny playbook-suggestion PR.
9. Exit after one PR.
