# autonomous-work-loops

Turn trusted GitHub issues into proven, reviewed PRs.

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
managed local supervisor that you can inspect and stop. For durable background
watch, run it from a persistent local terminal; short-lived agent command
sessions may stop child processes when the command exits.

## First Run

From the repo where agents should work, invoke the skill in Codex or Claude:

```text
/autonomous-work-loops
```

Depending on how the skill is installed, your host may show a namespaced command:

| Install path | Invocation |
|---|---|
| Direct skill install | `/autonomous-work-loops` |
| Codex plugin or namespaced skill UI | shown as `autonomous-work-loops:autonomous-work-loops` in the skill picker |
| Claude Code plugin | `/autonomous-work-loops:autonomous-work-loops` |

The agent should set up `.agent-loops/`, create or update labels, run doctor,
prove one smoke issue, and arm the managed local supervisor. When it finishes,
create normal GitHub issues for work you want done and add the `ready` label.
If setup is interrupted, invoke the skill again; existing `.agent-loops/` is
resumed instead of replaced.

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
- `python3` is available.
- The repo has at least one proof command such as test, build, or lint.
- Codex CLI or Claude Code can run locally.

On macOS, install machine prerequisites and verify the tools:

```sh
brew install gh coreutils
gh auth login
git --version
gh auth status
python3 --version
gtimeout --version || timeout --version
codex --version || claude --version
```

Install this skill if it is not already installed:

```sh
git clone --branch v0.1.9 --depth 1 https://github.com/kaskilling/autonomous-work-loops.git
cd autonomous-work-loops
./skills/autonomous-work-loops/assets/install.sh
```

That installs a fixed local copy. Use `--symlink` only while developing this
skill from a checkout you control. Existing installs are moved aside to a
timestamped backup by default; use `--force` only when you intentionally want
to replace without a backup.

## Command-Line Setup

The normal path is the skill invocation above. Use the CLI only when you want
the same setup without an agent harness:

```sh
cd /path/to/target-repo
/path/to/autonomous-work-loops/skills/autonomous-work-loops/assets/bootstrap.sh --arm "$PWD"
```

`--arm` creates or updates labels, runs doctor, preflights the role runner,
creates the first smoke issue, runs one supervisor tick, then starts managed
background watch. If `.agent-loops/` already exists, `--arm` resumes the
existing setup, avoids creating a duplicate smoke issue, and arms the
supervisor. Use [V1-QUICKSTART.md](V1-QUICKSTART.md) for guided, manual,
debug, and runner override commands.

Use foreground watch when your agent harness cannot keep background child
processes alive:

```sh
.agent-loops/runners/local-supervisor.sh --watch --interval 600 "$PWD"
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

If no trusted ready issue exists, the supervisor prints the exact smoke-issue
command to run from `.agent-loops/FIRST-TRIAL-ISSUE.md`.

## Glossary

- `proof`: the configured test, build, or lint command that must pass before
  autonomous handoff.
- `trusted actor`: a GitHub user allowed to create executable `ready` issues.
- `supervisor`: the local process that runs implementer, reviewer, and fixer
  ticks.
- `ready`: the label that gives AWL permission to work on an issue.

## Setup Decisions

Bootstrap tries to detect safe defaults. Confirm these in
`.agent-loops/BOOTSTRAP-REPORT.md` and `.agent-loops/config.yaml`:

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
