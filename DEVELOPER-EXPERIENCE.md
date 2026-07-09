# Developer Experience

This is what normal use should feel like after the skill is installed.

## One-Time Machine Setup

Install and verify local tools:

```sh
brew install gh coreutils
gh auth login
git --version
gh auth status
python3 --version
gtimeout --version || timeout --version
codex --version || claude --version
```

Install a fixed copy of the skill from a tagged release:

```sh
git clone --branch v0.1.12 --depth 1 https://github.com/kaskilling/autonomous-work-loops.git
cd autonomous-work-loops
./skills/autonomous-work-loops/assets/install.sh
```

Use `--symlink` only while developing this skill from a checkout you control.
The installer backs up existing skill installs by default.

## Per-Repo Setup

In the target GitHub repo, invoke the skill:

```text
/autonomous-work-loops
```

Codex plugin or namespaced skill UI installs may show
`autonomous-work-loops:autonomous-work-loops` in the skill picker. Claude Code
plugin installs use `/autonomous-work-loops:autonomous-work-loops`.

The setup agent should:

- render `.agent-loops/`
- create or update GitHub labels
- run `.agent-loops/doctor.sh`
- create and prove the first smoke issue
- start the managed local supervisor

The CLI equivalent is:

```sh
/path/to/autonomous-work-loops/skills/autonomous-work-loops/assets/bootstrap.sh --arm "$PWD"
```

Use deterministic manual bootstrap only when you do not want GitHub mutation,
smoke issues, or supervisor ticks created for you:

```sh
/path/to/autonomous-work-loops/skills/autonomous-work-loops/assets/bootstrap.sh "$PWD"
```

## What Gets Created

Bootstrap writes `.agent-loops/` into the target repo:

```text
.agent-loops/
  config.yaml
  context.md
  setup-labels.sh
  doctor.sh
  FIRST-TRIAL-ISSUE.md
  BOOTSTRAP-REPORT.md
  runners/local-supervisor.sh
  runners/codex.sh
  runners/claude.sh
  runners/guarded-role-runner-common.sh
  playbooks/
  evidence/inbox/
```

The setup agent also adds `.agent-loops/` to the target repo's local
`.git/info/exclude` when possible. The generated runner still refuses to stage
`.agent-loops/` files even if the exclude write is unavailable.

## Daily Workflow

You create a GitHub issue, describe the work clearly, and add the `ready` label.
In strict mode, the issue author must be listed in `.agent-loops/config.yaml`
under `trusted_actors`.

The local supervisor handles the loop:

```text
ready -> in-progress -> ready-for-human
ready -> in-progress -> needs-fix -> in-progress -> ready-for-human
ready -> in-progress -> ready-for-human-baseline-red
```

Terminal labels mean:

- `ready-for-human`: local proof, hosted checks, and autonomous review converged.
- `ready-for-human-baseline-red`: local proof and autonomous review converged,
  but hosted failures match failures already present on the default branch.
- `unproven`: no accepted proof command is configured.
- `did-not-converge`: the review/fix cycle cap was reached.
- `stalled`: setup, runtime, retry, or local harness limits stopped progress.

You still review and merge the PR yourself.

## Supervisor Controls

Normal setup starts managed background watch. Use:

```sh
.agent-loops/runners/local-supervisor.sh --status "$PWD"
.agent-loops/runners/local-supervisor.sh --stop "$PWD"
```

The status command reports lifecycle plus the current work snapshot, including
issue, PR, phase, last role, verdict, hosted checks, and next action.

Run one visible tick:

```sh
.agent-loops/runners/local-supervisor.sh --once "$PWD"
```

Use foreground watch when your agent harness cannot keep background child
processes alive:

```sh
.agent-loops/runners/local-supervisor.sh --watch --interval 600 "$PWD"
```

The supervisor probes the Codex runner before use and falls back to Claude Code
when available. Force Claude only when auto-detection is wrong:

```sh
AWL_ROLE_RUNNER="$PWD/.agent-loops/runners/claude.sh" .agent-loops/runners/local-supervisor.sh --once "$PWD"
```

Manual guarded role ticks are debugging paths, not the normal product path.
Codex Automations, Claude `/loop`, cron, launchd, and GitHub Actions schedules
are outside V1.

## Mental Model

GitHub labels are the control panel. `.agent-loops/config.yaml` is the local
contract. PR marker comments record what each role proved and decided. The user
experience should stay simple: invoke the skill, create trusted `ready` issues,
then review PRs when the loop reaches a human handoff label.
