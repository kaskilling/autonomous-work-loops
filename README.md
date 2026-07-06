# autonomous-work-loops

Turn trusted GitHub issues into proven, reviewed PRs.

**Status:** ready for private development and targeted validation installs.
The 2026-07-06 release-candidate pass proved a fresh public clone, standard
skill installer paths, Codex and Claude plugin installs from clean temp homes,
and a live foreground-supervisor smoke. Keep broad public launch and unattended
use behind real user trials and pinned release tags.

You write a clear issue and add the `ready` label. A local supervisor runs three
agent roles:

1. **Implementer** claims the issue, writes the change, runs proof, and opens a PR.
2. **Reviewer** checks the proof, diff, and acceptance criteria.
3. **Fixer** handles blocking review feedback when needed.

When proof passes and review has no blocking findings, the PR is labeled
`ready-for-human`. You still review and merge it yourself.

V1 is local and GitHub-only. It is not a hosted bot, daemon, cron job, GitHub
Action, Codex Automation, or Claude `/loop` scheduler.

## Five-Minute Setup

Install machine prerequisites:

```sh
brew install gh coreutils
gh auth login
gh auth status
```

Install this skill:

```sh
git clone https://github.com/kaskilling/autonomous-work-loops.git
cd autonomous-work-loops
./skills/autonomous-work-loops/assets/install.sh --symlink
```

Existing installs are moved aside to a timestamped backup by default. Use
`--force` only when you intentionally want to replace without a backup.

Bootstrap the GitHub repo you want agents to work on:

```sh
cd /path/to/target-repo
/path/to/autonomous-work-loops/skills/autonomous-work-loops/assets/bootstrap.sh "$PWD"
```

If you prefer agent-guided setup, ask Codex or Claude from the target repo:

```text
/autonomous-work-loops
```

or:

```text
Set up autonomous work loops here.
```

Then run the generated setup checks:

```sh
.agent-loops/setup-labels.sh
.agent-loops/doctor.sh
```

Start the local supervisor and leave the terminal open:

```sh
.agent-loops/runners/local-supervisor.sh "$PWD"
```

Create a GitHub issue from `.agent-loops/FIRST-TRIAL-ISSUE.md`, then add the
`ready` label. Watch the issue and PR labels move.

## What You Need To Decide

Bootstrap tries to detect the defaults, but you should confirm these before
starting the supervisor:

| Decision | Default to use first |
|---|---|
| Target repo | A small GitHub repo with issues and PRs enabled |
| Proof command | Existing test/build/lint command, for example `npm test` or `python3 -m pytest -q` |
| Trusted actors | Your authenticated GitHub username |
| Runner | Codex CLI if available, otherwise Claude Code |
| Supervisor cadence | The generated default interval |

If there is no proof command, the loop must stop at `unproven`. Passing proof is
the main safety gate.

## Label Control Panel

| Label | Meaning | What you do |
|---|---|---|
| `ready` | Trusted issue is available for the loop | You apply this |
| `in-progress` | The loop claimed the issue or PR | Wait or inspect |
| `needs-fix` | Review or proof found a blocker | Wait or inspect |
| `ready-for-human` | Proof and autonomous review converged | Review and merge |
| `unproven` | No accepted proof command is configured | Fix setup or handle manually |
| `did-not-converge` | Review/fix cycle cap was reached | Human review needed |
| `stalled` | Runtime or retry wall was reached | Inspect logs and runner state |

Typical paths:

```text
clean path: ready -> in-progress -> ready-for-human
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
path is the local foreground supervisor:

```sh
.agent-loops/runners/local-supervisor.sh "$PWD"
```

The latest release-candidate smoke used a fresh public clone, clean agent homes,
and the generated Claude role runner to move issue #1 to PR #2 with
`ready-for-human` in `kaskilling/awl-live-smoke-20260706`.

Known constraints: browser or Playwright proof can fail under locked local Codex
sandboxes. On this machine, the nested Codex role runner also hit a local Codex
state/app-server permission blocker during the fresh smoke; the supervisor
recovered and converged with the generated Claude role runner.
