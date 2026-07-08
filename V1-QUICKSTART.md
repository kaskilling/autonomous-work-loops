# V1 Quickstart

V1 runs one local supervisor. It claims trusted GitHub issues labeled `ready`,
opens proven PRs, reviews them, classifies hosted checks and external inline bot
feedback, fixes blockers when needed, and stops at `ready-for-human` or
`ready-for-human-baseline-red` for your final review.

## The Short Path

1. Install prerequisites.
2. Install the skill.
3. From the target repo, invoke `/autonomous-work-loops`.
4. Let the setup agent create labels, run doctor, prove the smoke issue, and arm
   the managed background supervisor.
5. Create trusted GitHub issues and add `ready`.
6. Review the resulting PR when it reaches `ready-for-human` or
   `ready-for-human-baseline-red`.

## 1. Install Prerequisites

You need a GitHub repo with issues and pull requests enabled, plus a local proof
command such as `npm test`, `pnpm test`, `python3 -m pytest -q`, or a build
command.

On macOS:

```sh
brew install gh coreutils
gh auth login
git --version
gh auth status
python3 --version
gtimeout --version || timeout --version
codex --version || claude --version
```

`gh` is required. `coreutils` provides `gtimeout`, which gives the local runner a
stronger runtime wall on macOS.

Also install Codex CLI or Claude Code. The supervisor auto-detects the available
guarded role runner.

## 2. Install The Skill

```sh
git clone --branch v0.1.10 --depth 1 https://github.com/kaskilling/autonomous-work-loops.git
cd autonomous-work-loops
./skills/autonomous-work-loops/assets/install.sh
```

This installs a fixed local copy from a tagged release. Use `--symlink` only
while developing this skill from a checkout you control. Existing installs are
moved aside to a timestamped backup by default; use `--force` only when you
intentionally want to replace without a backup.

## 3. Bootstrap The Target Repo

Go to the GitHub repo where agents should work:

```sh
cd /path/to/target-repo
```

Preferred path: invoke the skill in Codex or Claude and let the agent set up and
arm the repo:

```text
/autonomous-work-loops
```

Depending on install path, your host may show:

| Install path | Invocation |
|---|---|
| Direct skill install | `/autonomous-work-loops` |
| Codex plugin or namespaced skill UI | shown as `autonomous-work-loops:autonomous-work-loops` in the skill picker |
| Claude Code plugin | `/autonomous-work-loops:autonomous-work-loops` |

CLI equivalent:

```sh
/path/to/autonomous-work-loops/skills/autonomous-work-loops/assets/bootstrap.sh --arm "$PWD"
```

`--arm` creates or updates labels, runs doctor, preflights the role runner,
creates the smoke issue, runs one one-shot supervisor tick, then starts managed
background watch.

Use guided setup without background watch when you want setup to stop after the
smoke tick:

```sh
/path/to/autonomous-work-loops/skills/autonomous-work-loops/assets/bootstrap.sh --guided "$PWD"
```

Use deterministic manual bootstrap when you do not want GitHub labels, issues,
or supervisor ticks created for you:

```sh
/path/to/autonomous-work-loops/skills/autonomous-work-loops/assets/bootstrap.sh "$PWD"
```

All paths write `.agent-loops/` and a Bootstrap Report. Read the report before
changing defaults. The script refuses to overwrite an existing
`.agent-loops/` unless you pass `--force`, and it refuses non-GitHub or non-git
targets unless you pass `--allow-incomplete` for manual scaffolding.

Bootstrap adds `.agent-loops/` and `.agent-loops.tmp.*/` to the target repo's
local `.git/info/exclude` when that file is writable. If local git metadata is
read-only, bootstrap warns and continues; the runner still refuses to stage
`.agent-loops/` files.

Confirm these fields in `.agent-loops/config.yaml`:

- `proof`: at least one accepted test, build, or lint command. For repos where
  `npm test` includes Playwright/E2E and `test:unit` exists, bootstrap uses the
  unit script as the first-smoke default and records the broader test command in
  `.agent-loops/BOOTSTRAP-REPORT.md`.
- `trusted_actors`: includes the GitHub user who will author executable issues.
- `trust_posture`: use `strict` for public or multi-contributor repos.
- `labels`: keep defaults unless the repo already has a deliberate label scheme.

## 4. Labels

`--arm` and `--guided` run the generated label helper for you. For manual setup,
run:

```sh
.agent-loops/setup-labels.sh
```

The helper is idempotent. It creates or updates:

| Label | Meaning |
|---|---|
| `ready` | Trusted work is available |
| `in-progress` | The loop claimed the work |
| `needs-fix` | Proof or review found a code blocker |
| `ready-for-human` | Proof, green hosted checks, and review converged |
| `ready-for-human-baseline-red` | Proof and review converged; hosted failures match the default branch baseline |
| `unproven` | No accepted proof command exists |
| `did-not-converge` | Review/fix cycle cap was reached |
| `stalled` | Runtime wall, retry wall, or local harness/setup blocker was reached |

## 5. Doctor

`--arm` and `--guided` run the non-mutating preflight for you. For manual setup,
run:

```sh
.agent-loops/doctor.sh
```

Fix every `fail:` line before starting the supervisor. `warn:` lines are usually
safe for a trial, but the `timeout`/`gtimeout` warning is worth fixing on macOS:

```sh
brew install coreutils
```

## 6. First Trial

`--arm` and `--guided` create the first trial issue for you. For manual setup,
use the generated issue body:

```sh
cat .agent-loops/FIRST-TRIAL-ISSUE.md
```

Create a GitHub issue from that template as a trusted actor, then apply `ready`.

## 7. Supervisor Controls

`--arm` starts managed background watch after the smoke tick passes. Use:

```sh
.agent-loops/runners/local-supervisor.sh --status "$PWD"
.agent-loops/runners/local-supervisor.sh --stop "$PWD"
```

`--status` reports both supervisor lifecycle and current work:
`current_issue`, `current_pr`, `current_phase`, `last_role`, `last_verdict`,
`hosted_checks`, and `next_action`.

To run one visible tick:

```sh
.agent-loops/runners/local-supervisor.sh --once "$PWD"
```

The supervisor runs the roles in order:

```text
implementer -> reviewer -> fixer
```

Before it claims work, the supervisor probes the generated Codex runner. If
Codex cannot start and Claude Code is available, it falls back to the generated
Claude runner. To force Claude directly:

```sh
AWL_ROLE_RUNNER="$PWD/.agent-loops/runners/claude.sh" .agent-loops/runners/local-supervisor.sh --once "$PWD"
```

It exits after one pass by default. Use explicit foreground watch mode only
after the smoke test is proven:

```sh
.agent-loops/runners/local-supervisor.sh --watch --interval 600 "$PWD"
```

Start managed background watch manually with:

```sh
.agent-loops/runners/local-supervisor.sh --background "$PWD"
```

Override the interval only when you are deliberately testing cadence:

```sh
AWL_SUPERVISOR_INTERVAL_SECONDS=60 .agent-loops/runners/local-supervisor.sh --watch "$PWD"
```

Override the role runner only when auto-detection is wrong or you want to skip
the Codex preflight:

```sh
AWL_ROLE_RUNNER="$PWD/.agent-loops/runners/claude.sh" .agent-loops/runners/local-supervisor.sh --once "$PWD"
```

Expected clean path:

```text
ready -> in-progress -> ready-for-human
```

Expected baseline-red path:

```text
ready -> in-progress -> ready-for-human-baseline-red
```

Expected fix path:

```text
ready -> in-progress -> needs-fix -> in-progress -> ready-for-human
```

Stop paths:

```text
unproven | did-not-converge | stalled
```

After the trial, confirm:

- Exactly one `loop/impl/issue-<number>` branch was created.
- Exactly one PR was opened for the issue.
- The PR body or comments include proof markers.
- `.agent-loops/` files are not in the PR diff.

## Manual Debug Ticks

Manual ticks are for troubleshooting, not the happy path:

```sh
.agent-loops/runners/codex.sh "$PWD" implementer
.agent-loops/runners/codex.sh "$PWD" reviewer
.agent-loops/runners/codex.sh "$PWD" fixer

.agent-loops/runners/claude.sh "$PWD" implementer
.agent-loops/runners/claude.sh "$PWD" reviewer
.agent-loops/runners/claude.sh "$PWD" fixer
```

Use these when `doctor.sh` passes but the supervisor output does not explain the
blocker.

## What V1 Does Not Do

- No autonomous merge.
- No hosted bot.
- No GitLab adapter.
- No system cron, launchd, or GitHub Actions schedule.
- No Codex Automations or Claude `/loop` scheduler.
- No browser/Playwright proof under a locked Codex sandbox unless a compatible
  execution surface is validated.
