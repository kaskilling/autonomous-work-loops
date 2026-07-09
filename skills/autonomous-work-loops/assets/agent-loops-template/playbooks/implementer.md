# Implementer Playbook

Use the installed `autonomous-work-loops` skill in tick mode with role `implementer`.

Default path:

1. Read `.agent-loops/config.yaml` and `.agent-loops/context.md`.
2. Use `claim_work` for one trusted ready issue.
3. Implement one coherent change.
4. Run the narrowest existing repo-native validation that matches the changed behavior.
5. Run configured proof.
6. Open the PR or route to `needs-fix` / `unproven`.
7. Append evidence for repeated or surprising failures.
8. Exit after one item.

Do not hard-code a framework-specific test command. Derive focused validation
from changed files, nearby tests, package/build scripts, and repo docs.
