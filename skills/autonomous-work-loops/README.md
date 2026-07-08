# autonomous-work-loops

This skill bootstraps and arms a target GitHub repo with a local work loop:

1. an implementer claims trusted `ready` issues and opens proven PRs
2. a reviewer checks proof, diff, hosted checks, external inline bot comments, and acceptance criteria
3. a fixer handles blocking review feedback when needed
4. the loop stops at `ready-for-human` or `ready-for-human-baseline-red` for human review and merge

V1 is local and GitHub-only. It is not a hosted bot, cron job, GitHub Action,
Codex Automation, or Claude `/loop` scheduler. The normal setup starts one
managed local supervisor with status and stop controls. Durable background watch
requires a persistent local terminal; use foreground `--watch` when a harness
stops child processes after the setup command exits.

## Setup

Install machine prerequisites:

```sh
brew install gh coreutils
gh auth login
gh auth status
```

From the target GitHub repo, invoke the skill:

```text
/autonomous-work-loops
```

The agent should run the guided-and-armed setup: create labels, run doctor,
prove the smoke issue, and start managed background watch. If `.agent-loops/`
already exists, the same command resumes setup and avoids a duplicate smoke
issue.

CLI equivalent:

```sh
<skill-root>/assets/bootstrap.sh --arm "$PWD"
```

Use these controls after setup:

```sh
.agent-loops/runners/local-supervisor.sh --status "$PWD"
.agent-loops/runners/local-supervisor.sh --stop "$PWD"
```

Create a trusted GitHub issue, then add the `ready` label. A clean proven path
should move:

```text
ready -> in-progress -> ready-for-human
```

If hosted checks fail only because the default branch is already red, the clean
handoff label is `ready-for-human-baseline-red`.

If no proof command is configured, the loop must stop at `unproven`.

The supervisor probes Codex before using it and falls back to Claude Code when
Claude is available. To force Claude:

```sh
AWL_ROLE_RUNNER="$PWD/.agent-loops/runners/claude.sh" .agent-loops/runners/local-supervisor.sh --once "$PWD"
```

## Read More

The repository root README has the full operator path, release status, and
publishing notes.
