# V1 Quickstart

V1 turns GitHub issues labeled `ready` into proven PRs by arming one runner surface. You create trusted issues; the runner wakes the Implementer, Reviewer, and Fixer ticks until the PR reaches `ready-for-human` or a human-gated terminal state.

## Current V1 Flow

1. Install the skill.
2. Bootstrap a target GitHub repo.
3. Confirm the Bootstrap Report: proof command, trusted actors, labels, and runner surface.
4. Arm the tested runner surface:
   - Local foreground supervisor.
   - Codex Automations and Claude `/loop` are target profiles, but they are not V1 GO until their live permission/concurrency blockers are fixed.
5. Create or rewrite a trusted issue and apply `ready`.
6. Watch GitHub labels and PR markers:
   - clean path: `ready -> in-progress -> ready-for-human`
   - fix path: `ready -> in-progress -> needs-fix -> in-progress -> ready-for-human`
   - human gates: `unproven`, `did-not-converge`, or `stalled`
7. Human reviews and merges the `ready-for-human` PR.

## Prerequisites

- A GitHub repo with issues and pull requests enabled.
- A working `git` remote and authenticated GitHub CLI:

```sh
brew install gh
gh auth login
gh auth status
```

- A proof command that can run locally, such as `python3 -m pytest -q`, `npm test`, or a repo-specific build/test command.
- Codex or Claude installed with access to this skill.
- For Codex guarded runner use on macOS, `gtimeout` is recommended:

```sh
brew install coreutils
```

## Install The Skill

```sh
git clone https://github.com/kaskilling/autonomous-work-loops.git
cd autonomous-work-loops
./skill/autonomous-work-loops/assets/install.sh --symlink
```

## Bootstrap A Repo

In the target repo:

```text
/autonomous-work-loops
```

Or ask:

```text
Set up autonomous work loops here.
```

Bootstrap should render `.agent-loops/`, write a Bootstrap Report, identify the authenticated GitHub user, add that user to `trusted_actors` when appropriate, and ask or infer the runner surface.

Review the Bootstrap Report before arming a runner. In strict mode, the issue author must be listed in `.agent-loops/config.yaml` under `trusted_actors`; the bootstrap default should include the authenticated maintainer/operator, not every collaborator.

## Runner Surface 1: Local Foreground Supervisor

Use this for the current V1 trial path.

Expected bootstrap output:

```sh
.agent-loops/runners/local-supervisor.sh "$PWD"
```

Start it in one terminal and leave it running. Stop it with `Ctrl-C`. It does not install cron, launchd, GitHub Actions, or any persistent scheduler.

## Runner Surface 2: Codex Automations

Status: target profile, not broad-launch GO.

Use this when running from Codex.

Expected bootstrap output:

- `.agent-loops/runners/codex.sh`
- Codex automation prompts from `codex-automation.md.tmpl`
- three recurring automations or suggested automations:
  - implementer
  - reviewer
  - fixer

The automation prompt should run one guarded role tick and exit. It must not install cron jobs or create more automations. Live validation showed broad "load the skill" prompts are too loose; use a command-only prompt and validate the Codex permission profile before relying on this unattended.

## Runner Surface 3: Claude `/loop`

Status: target profile, not broad-launch GO.

Use this when running from Claude Code.

Expected bootstrap output:

- one `/loop` prompt per role:
  - implementer
  - reviewer
  - fixer

Each loop prompt must load the skill, run exactly one role tick, reconstruct host state, do one unit of work, and exit.

Live validation showed Claude Code can create the scheduled `/loop`, but a fresh fixture blocked on skill/reference file permissions before the guarded tick. Validate the Claude permission setup before relying on this unattended.

## Manual Debug Commands

Manual ticks are for troubleshooting, not the happy path:

```sh
.agent-loops/runners/codex.sh "$PWD" implementer
.agent-loops/runners/codex.sh "$PWD" reviewer
.agent-loops/runners/codex.sh "$PWD" fixer
```

## First Manual Trial

Use a small repo with a fast proof command.

1. Bootstrap the repo.
2. Choose the runner surface.
3. Create the labels if the Bootstrap Report asks for them:

```sh
gh label create ready --color 0E8A16 --description "Trusted work ready for autonomous-work-loops intake" --force
gh label create in-progress --color FBCA04 --description "Autonomous-work-loops has claimed this work" --force
gh label create needs-fix --color D93F0B --description "Reviewer found blocking defects or proof failed" --force
gh label create ready-for-human --color 5319E7 --description "Proof passed and autonomous review converged" --force
gh label create unproven --color BFDADC --description "No accepted proof command is configured or available" --force
gh label create did-not-converge --color B60205 --description "Review/fix cycle cap reached with blockers remaining" --force
gh label create stalled --color 000000 --description "Runner exceeded retry or runtime wall and needs a human" --force
```

4. Create a small issue authored by a trusted actor.
5. Apply `ready`.
6. Let the armed runner surface work.
7. Confirm exactly one `loop/impl/issue-<n>` branch and one PR.
8. Confirm the PR has proof markers and reaches `ready-for-human`, or one of the human-gated terminal labels.

## V1 Non-Goals

- No system cron install.
- No GitHub Actions schedule.
- No GitLab adapter.
- No hosted bot.
- No autonomous merge.
- No browser/Playwright proof under a locked Codex sandbox unless a compatible execution surface is validated.
