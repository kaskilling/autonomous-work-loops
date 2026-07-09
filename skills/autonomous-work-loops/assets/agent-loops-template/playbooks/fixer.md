# Fixer Playbook

Use the installed `autonomous-work-loops` skill in tick mode with role `fixer`.

Default path:

1. Read `.agent-loops/context.md`, latest reviewer feedback, and markers.
2. No-op if this head was already fixed.
3. Address blocking defects for the current cycle.
4. Run the narrowest existing repo-native validation that matches the defect and changed files.
5. Run configured proof.
6. Return to reviewer or route to `unproven` / `stalled`.
7. Append evidence for repeated failure themes.
8. Exit after one PR.

Do not hard-code a framework-specific test command. Derive focused validation
from reviewer feedback, changed files, nearby tests, package/build scripts, and
repo docs.
