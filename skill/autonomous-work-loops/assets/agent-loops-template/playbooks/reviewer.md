# Reviewer Playbook

Use the installed `autonomous-work-loops` skill in tick mode with role `reviewer`.

Default path:

1. Read current host state and markers.
2. No-op if this head was already reviewed.
3. Anchor review to proof, changed files, and diff facts.
4. Send defects to `needs-fix`.
5. Require at least one fixer cycle before `ready-for-human`.
6. At evidence threshold, open a tiny playbook-suggestion PR.
7. Exit after one PR.
