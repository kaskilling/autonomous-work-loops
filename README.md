# autonomous-work-loops

Turn trusted GitHub issues into proven, reviewed PRs.

**Status:** ready for private development and targeted validation installs.
The 2026-07-08 setup pass proved the smooth path: skill/default setup can render
`.agent-loops/`, run guided checks, and arm a managed local supervisor with
status and stop controls. Keep broad public launch behind real user trials and
pinned release tags.

You write a clear issue and add the `ready` label. A local supervisor runs three
agent roles:

1. **Implementer** claims the issue, writes the change, runs proof, and opens a PR.
2. **Reviewer** checks the proof, diff, and acceptance criteria.
3. **Fixer** handles blocking review feedback when needed.

When proof passes, hosted checks are classified, and review has no blocking
findings, the PR is labeled `ready-for-human`. If hosted checks are red only
because the default branch is already red, the PR is labeled
`ready-for-human-baseline-red` instead. You still review and merge it yourself.

V1 is local and GitHub-only. It is not a hosted bot, cron job, GitHub Action,
Codex Automation, or Claude `/loop` scheduler. The normal setup starts one
managed local background supervisor that you can inspect and stop.

## First Run

From the repo where agents should work, invoke the skill in Codex or Claude:

```text
/autonomous-work-loops
```

The agent should set up `.agent-loops/`, create or update labels, run doctor,
prove one smoke issue, and arm the managed local supervisor. When it finishes,
create normal GitHub issues for work you want done and add the `ready` label.

What success looks like:

```text
issue with ready -> loop/impl/issue-N branch -> PR -> ready-for-human
```

If hosted checks fail only because the default branch is already red, the final
handoff label is `ready-for-human-baseline-red`.

Use these generated controls when needed:

```sh
.agent-loops/runners/local-supervisor.sh --status "$PWD"
.agent-loops/runners/local-supervisor.sh --stop "$PWD"
```

## Before You Start

The setup agent checks these, but they are the real requirements:

- The target is a GitHub repo with issues and pull requests enabled.
- `gh auth status` works for a GitHub user allowed to create issues, labels,
  branches, and PRs.
- The repo has at least one proof command such as test, build, or lint.
- Codex CLI or Claude Code can run locally.

On macOS, install machine prerequisites:

```sh
brew install gh coreutils
gh auth login
gh auth status
```

Install this skill if it is not already installed:

```sh
git clone https://github.com/kaskilling/autonomous-work-loops.git
cd autonomous-work-loops
./skills/autonomous-work-loops/assets/install.sh --symlink
```

Existing installs are moved aside to a timestamped backup by default. Use
`--force` only when you intentionally want to replace without a backup.

## Command-Line Setup

Use this when you want the same smooth path without an agent harness:

```sh
cd /path/to/target-repo
/path/to/autonomous-work-loops/skills/autonomous-work-loops/assets/bootstrap.sh --arm "$PWD"
```

`--arm` creates or updates labels, runs doctor, preflights the role runner,
creates the first smoke issue, runs one supervisor tick, then starts managed
background watch.

For setup without background watch:

```sh
/path/to/autonomous-work-loops/skills/autonomous-work-loops/assets/bootstrap.sh --guided "$PWD"
```

For manual setup without GitHub label mutation or a supervisor tick:

```sh
/path/to/autonomous-work-loops/skills/autonomous-work-loops/assets/bootstrap.sh "$PWD"
```

If `.agent-loops/` already exists and you intentionally want to replace it, add
`--force`.

Manual setup requires the generated commands:

```sh
.agent-loops/setup-labels.sh
.agent-loops/doctor.sh
.agent-loops/runners/local-supervisor.sh --once "$PWD"
.agent-loops/runners/local-supervisor.sh --background "$PWD"
```

Bootstrap also tries to add `.agent-loops/` to the target repo's local
`.git/info/exclude`. If the local git metadata is read-only, bootstrap warns
and continues; generated runners still refuse to stage `.agent-loops/` files.

The supervisor preflights the Codex role runner before using it. If Codex cannot
start in the current environment and Claude Code is available, it falls back to
the generated Claude runner. You can force that runner explicitly:

```sh
AWL_ROLE_RUNNER="$PWD/.agent-loops/runners/claude.sh" .agent-loops/runners/local-supervisor.sh --once "$PWD"
```

Or watch continuously after the smoke test is proven:

```sh
.agent-loops/runners/local-supervisor.sh --watch --interval 600 "$PWD"
```

If no trusted ready issue exists, the supervisor prints the exact smoke-issue
command to run from `.agent-loops/FIRST-TRIAL-ISSUE.md`.

## Glossary

- `proof`: the configured test, build, or lint command that must pass before
  autonomous handoff.
- `trusted actor`: a GitHub user allowed to create executable `ready` issues.
- `supervisor`: the local process that runs implementer, reviewer, and fixer
  ticks.
- `ready`: the label that gives AWL permission to work on an issue.

## What You Need To Decide

Bootstrap tries to detect the defaults, but you should confirm these before
starting the supervisor:

| Decision | Default to use first |
|---|---|
| Target repo | A small GitHub repo with issues and PRs enabled |
| Proof command | Existing test/build/lint command, for example `npm test` or `python3 -m pytest -q` |
| Trusted actors | Your authenticated GitHub username |
| Runner | First viable generated runner; Codex is probed before use, then Claude Code is used if available |
| Supervisor cadence | The generated default interval |

If there is no proof command, the loop must stop at `unproven`. Passing proof is
the main safety gate.

For repositories where `npm test` includes browser or E2E work and
`test:unit` exists, bootstrap starts with the unit script as the first-smoke
proof and records the broader test command in the Bootstrap Report. Promote to
the broader proof after the loop is proven on that repo.

## Label Control Panel

| Label | Meaning | What you do |
|---|---|---|
| `ready` | Trusted issue is available for the loop | You apply this |
| `in-progress` | The loop claimed the issue or PR | Wait or inspect |
| `needs-fix` | Review or proof found a code blocker | Wait or inspect |
| `ready-for-human` | Proof, green hosted checks, and autonomous review converged | Review and merge |
| `ready-for-human-baseline-red` | Proof and review converged; hosted failures match the default branch baseline | Review the baseline risk before merge |
| `unproven` | No accepted proof command is configured | Fix setup or handle manually |
| `did-not-converge` | Review/fix cycle cap was reached | Human review needed |
| `stalled` | Runtime wall, retry wall, or local harness/setup blocker was reached | Inspect logs and runner state |

Typical paths:

```text
clean path: ready -> in-progress -> ready-for-human
baseline:   ready -> in-progress -> ready-for-human-baseline-red
fix path:   ready -> in-progress -> needs-fix -> in-progress -> ready-for-human
stop path:  ready -> in-progress -> unproven | did-not-converge | stalled
```

## Safety Defaults

- Only trusted `ready` issues are executable. In strict mode, the issue author
  must be listed in `.agent-loops/config.yaml` under `trusted_actors`.
- External requests should become trusted-authored dispatch issues before they
  receive `ready`.
- Proof is required for autonomous convergence.
- Merge, deploy, secrets, protected paths, budget increases, and playbook changes
  stay human-gated.
- The local supervisor uses your local credentials. Do not run it in a repo you
  would not trust with those credentials.

## Generated Files

Bootstrap writes `.agent-loops/` into the target repo:

```text
.agent-loops/
  config.yaml                  # proof commands, trust, labels, budgets
  context.md                   # short repo contract every role reads
  setup-labels.sh              # idempotent GitHub label setup
  doctor.sh                    # non-mutating preflight checker
  FIRST-TRIAL-ISSUE.md         # safe first smoke-test issue body
  runners/local-supervisor.sh  # only supported V1 runner surface
  runners/codex.sh             # guarded Codex role runner when available
  runners/claude.sh            # guarded Claude role runner when available
  runners/guarded-role-runner-common.sh
  playbooks/                   # role instructions
  evidence/inbox/              # future-compatible evidence inbox
```

## Install And Packaging

The plain install script copies or symlinks the skill into:

- `~/.claude/skills`
- `~/.codex/skills`
- `~/.agents/skills`

This repo also includes:

- `.claude-plugin/plugin.json` for Claude Code plugin packaging.
- `.codex-plugin/plugin.json` for Codex plugin packaging.
- `skills/autonomous-work-loops/agents/openai.yaml` for Codex skill UI metadata.
- `skills/autonomous-work-loops` is the canonical skill tree used by both
  direct skill installs and plugin packaging.

For publishing notes, see [PUBLISHING.md](PUBLISHING.md).

## Where To Read More

- [V1-QUICKSTART.md](V1-QUICKSTART.md) gives the operator setup path in more detail.
- [DEVELOPER-EXPERIENCE.md](DEVELOPER-EXPERIENCE.md) shows what the daily loop feels like.
- [design/](design/) contains the ADRs, glossary, ecosystem notes, and V2 target design.
- [build/](build/) contains build plans, test results, and gate evidence.

## Current Status

V1 is implemented and tested on live private GitHub repos. The current happy
path is the managed local supervisor:

```sh
.agent-loops/runners/local-supervisor.sh --background "$PWD"
```

The latest release-candidate smokes used fresh clones, clean agent homes, and
generated role runners to move trusted `ready` issues into proven PRs. The
managed supervisor now exposes `--status` and `--stop` so a setup agent can arm
the repo without leaving the user to run a watch command manually.

Known constraints: browser or Playwright proof can fail under locked local Codex
sandboxes. On this machine, the nested Codex role runner also hit a local Codex
state/app-server permission blocker during the fresh smoke; the supervisor
recovered and converged with the generated Claude role runner.
