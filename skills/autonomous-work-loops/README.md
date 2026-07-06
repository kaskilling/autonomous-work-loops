# autonomous-work-loops

This skill bootstraps a target GitHub repo with a local foreground loop:

1. an implementer claims trusted `ready` issues and opens proven PRs
2. a reviewer checks proof, diff, and acceptance criteria
3. a fixer handles blocking review feedback when needed
4. the loop stops at `ready-for-human` for human review and merge

V1 is local and GitHub-only. It is not a hosted bot, daemon, cron job, GitHub
Action, Codex Automation, or Claude `/loop` scheduler.

## Setup

Install machine prerequisites:

```sh
brew install gh coreutils
gh auth login
gh auth status
```

From the target GitHub repo:

```sh
<skill-root>/assets/bootstrap.sh "$PWD"
.agent-loops/setup-labels.sh
.agent-loops/doctor.sh
.agent-loops/runners/local-supervisor.sh "$PWD"
```

Create a small issue from `.agent-loops/FIRST-TRIAL-ISSUE.md`, then add the
`ready` label. A clean proven path should move:

```text
ready -> in-progress -> ready-for-human
```

If no proof command is configured, the loop must stop at `unproven`.

## Read More

The repository root README has the full operator path, release status, and
publishing notes.
