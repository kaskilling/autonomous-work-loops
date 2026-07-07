# V1 Quickstart

V1 runs one local foreground supervisor. It claims trusted GitHub issues labeled
`ready`, opens proven PRs, reviews them, classifies hosted checks and external
inline bot feedback, fixes blockers when needed, and stops at `ready-for-human`
or `ready-for-human-baseline-red` for your final review.

## The Short Path

1. Install prerequisites.
2. Install the skill.
3. Bootstrap one target GitHub repo.
4. Create labels.
5. Run the doctor check.
6. Create one tiny trusted issue and add `ready`.
7. Run one supervisor tick.
8. Review the resulting PR when it reaches `ready-for-human` or
   `ready-for-human-baseline-red`.

## 1. Install Prerequisites

You need a GitHub repo with issues and pull requests enabled, plus a local proof
command such as `npm test`, `pnpm test`, `python3 -m pytest -q`, or a build
command.

On macOS:

```sh
brew install gh coreutils
gh auth login
gh auth status
```

`gh` is required. `coreutils` provides `gtimeout`, which gives the local runner a
stronger runtime wall on macOS.

Also install Codex CLI or Claude Code. The supervisor auto-detects the available
guarded role runner.

## 2. Install The Skill

```sh
git clone https://github.com/kaskilling/autonomous-work-loops.git
cd autonomous-work-loops
./skills/autonomous-work-loops/assets/install.sh --symlink
```

Use `--symlink` while developing or evaluating the skill. Use the default copy
mode when you want a fixed local copy. Existing installs are moved aside to a
timestamped backup by default; use `--force` only when you intentionally want to
replace without a backup.

## 3. Bootstrap The Target Repo

Go to the GitHub repo where agents should work:

```sh
cd /path/to/target-repo
```

Run deterministic bootstrap:

```sh
/path/to/autonomous-work-loops/skills/autonomous-work-loops/assets/bootstrap.sh "$PWD"
```

Or run the guided first setup, which creates labels, runs doctor, creates the
smoke issue, and runs one one-shot supervisor tick:

```sh
/path/to/autonomous-work-loops/skills/autonomous-work-loops/assets/bootstrap.sh --guided "$PWD"
```

Or invoke the skill in Codex or Claude for agent-guided setup:

```text
/autonomous-work-loops
```

or:

```text
Set up autonomous work loops here.
```

Both paths write `.agent-loops/` and a Bootstrap Report. Read the report before
starting the supervisor. The script refuses to overwrite an existing
`.agent-loops/` unless you pass `--force`, and it refuses non-GitHub or non-git
targets unless you pass `--allow-incomplete` for manual scaffolding.

Bootstrap adds `.agent-loops/` and `.agent-loops.tmp.*/` to the target repo's
local `.git/info/exclude`. You should not need to mention AWL files in issues;
the runner also refuses to stage `.agent-loops/` files.

Confirm these fields in `.agent-loops/config.yaml`:

- `proof`: at least one accepted test, build, or lint command. For repos where
  `npm test` includes Playwright/E2E and `test:unit` exists, bootstrap uses the
  unit script as the first-smoke default and records the broader test command in
  `.agent-loops/BOOTSTRAP-REPORT.md`.
- `trusted_actors`: includes the GitHub user who will author executable issues.
- `trust_posture`: use `strict` for public or multi-contributor repos.
- `labels`: keep defaults unless the repo already has a deliberate label scheme.

## 4. Create Labels

Run the generated helper:

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

## 5. Run Doctor

Run the non-mutating preflight:

```sh
.agent-loops/doctor.sh
```

Fix every `fail:` line before starting the supervisor. `warn:` lines are usually
safe for a trial, but the `timeout`/`gtimeout` warning is worth fixing on macOS:

```sh
brew install coreutils
```

## 6. Run The First Trial

Use the generated issue body:

```sh
cat .agent-loops/FIRST-TRIAL-ISSUE.md
```

Create a GitHub issue from that template as a trusted actor, then apply `ready`.

## 7. Run One Supervisor Tick

Run this in one visible terminal:

```sh
.agent-loops/runners/local-supervisor.sh --once "$PWD"
```

The supervisor runs the roles in order:

```text
implementer -> reviewer -> fixer
```

It exits after one pass by default. Use explicit watch mode only after the smoke
test is proven:

```sh
.agent-loops/runners/local-supervisor.sh --watch --interval 600 "$PWD"
```

Override the interval only when you are deliberately testing cadence:

```sh
AWL_SUPERVISOR_INTERVAL_SECONDS=60 .agent-loops/runners/local-supervisor.sh --watch "$PWD"
```

Override the role runner only when auto-detection is wrong:

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
