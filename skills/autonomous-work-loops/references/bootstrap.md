# Bootstrap Reference

Cites ADR-0001, ADR-0004, ADR-0005, ADR-0006, ADR-0007, ADR-0009, ADR-0010.

Bootstrap mode sets up `.agent-loops/` in the target repository. Prefer the deterministic `assets/bootstrap.sh` script; it discovers current repo facts, renders config and runner artifacts from `assets/`, and writes a Bootstrap Report. Without `--guided` or `--arm`, it exits without starting a loop or mutating GitHub labels. With `--guided`, it performs the first approved setup actions in the foreground. With `--arm`, it implies guided setup, proves the smoke tick on first setup, and starts the managed local background supervisor. If `.agent-loops/` already exists, `--guided` and `--arm` resume it instead of replacing it and do not create a duplicate smoke issue. It never assumes future ticks remember anything.

Use manual rendering only when `assets/bootstrap.sh` is unavailable. If the user invokes the skill normally from a repo, run `assets/bootstrap.sh --arm "$PWD"`; this creates or updates labels, runs doctor, preflights the role runner, creates the smoke issue on first setup, waits until GitHub reports it with `ready`, runs one one-shot supervisor tick, and then starts managed watch mode. On an existing setup, it updates labels/checks and arms the supervisor without duplicating the smoke issue. If the user explicitly asks for setup without background watch, run `assets/bootstrap.sh --guided "$PWD"`.

## Discovery Checklist

1. Confirm the repo host is GitHub for V1. Use `adapter-github.md` as the only V1 host implementation.
2. Confirm GitHub CLI access before writing config:
   - `gh auth status`
   - `gh api user --jq .login`
   - `gh repo view --json nameWithOwner,owner,visibility,viewerPermission,defaultBranchRef,hasIssuesEnabled`
3. Identify default branch, current remote, repository visibility, explicit loop dispatchers, and whether issues and pull requests are enabled.
4. Discover proof commands for `test`, `build`, and `lint` from package scripts, build files, CI workflows, README instructions, and existing developer docs.
5. Default deterministic bootstrap to `trust_posture: strict`. Agents may suggest `permissive` only for a clearly solo private repo, and the user must approve that config edit.
6. Build `trusted_actors` from the authenticated GitHub login, explicit maintainers, owners, or named loop dispatchers. Add the authenticated login when `gh api user --jq .login` succeeds and the user is the repo owner, has maintainer/admin/write permission, or is the person explicitly setting up the loop. Do not add every collaborator by default. Leave the list editable. If the authenticated login cannot be proven, stop and ask the user to run `gh auth login`.
7. Render the only V1 runner surface: the local supervisor. Render from `assets/runners/`: `local-supervisor.sh.tmpl`, `guarded-role-runner-common.sh.tmpl`, plus the guarded role runner wrapper for the local harness (`codex.sh.tmpl` for Codex CLI, `claude.sh.tmpl` for Claude Code, or both when unsure). The supervisor runs one visible tick by default; `--watch --interval 600` is explicit foreground polling mode; `--background` starts the same watch loop as a managed local process with `.agent-loops/supervisor.pid`, logs under `.agent-loops/evidence/prove-the-gate/logs/`, and `--status` / `--stop` controls. Durable background watch requires a persistent local terminal; if an agent command harness reaps child processes after command exit, use foreground `--watch` or surface the exact persistent-terminal command. The supervisor probes Codex before selecting it and falls back to Claude when available. The guarded role runner common file keeps trust, claim, Git mutation, proof, PRs, labels, PR checks, external review comments, and markers in the parent shell; the thin Codex/Claude wrappers only define nested agent invocation. Nested Codex or Claude edits the working tree only or returns review text. This avoids managed-sandbox `.git` write denial while keeping the branch-ref claim deterministic. The external cost wall prefers `timeout`, then `gtimeout` (coreutils on macOS), else a background-kill fallback baked into the runner. Record credential implications. Do not install Codex Automations, Claude `/loop`, system cron, launchd, or GitHub Actions schedules during V1 bootstrap.
8. Render `.agent-loops/config.yaml`, `.agent-loops/context.md`, `.agent-loops/setup-labels.sh`, `.agent-loops/doctor.sh`, `.agent-loops/FIRST-TRIAL-ISSUE.md`, `.agent-loops/playbooks/implementer.md`, `.agent-loops/playbooks/reviewer.md`, `.agent-loops/playbooks/fixer.md`, and `.agent-loops/evidence/inbox/`.

## Required Labels

Bootstrap must either create these labels with user approval, render `.agent-loops/setup-labels.sh`, or print the exact commands in the Bootstrap Report:

```sh
.agent-loops/setup-labels.sh
```

Equivalent direct commands:

```sh
gh label create ready --color 0E8A16 --description "Trusted work ready for autonomous-work-loops intake" --force
gh label create in-progress --color FBCA04 --description "Autonomous-work-loops has claimed this work" --force
gh label create needs-fix --color D93F0B --description "Reviewer found blocking defects or proof failed" --force
gh label create ready-for-human --color 5319E7 --description "Proof, green hosted checks, and autonomous review converged" --force
gh label create ready-for-human-baseline-red --color 8A63D2 --description "Proof and review converged; hosted failures match default-branch baseline" --force
gh label create unproven --color BFDADC --description "No accepted proof command is configured or available" --force
gh label create did-not-converge --color B60205 --description "Review/fix cycle cap reached with blockers remaining" --force
gh label create stalled --color 000000 --description "Runner exceeded retry or runtime wall and needs a human" --force
```

Do not treat missing labels as a background concern. Without these labels, the state machine is not visible or operable.

## Setup Model

Copy the template tree from `assets/agent-loops-template/` into the target repo as `.agent-loops/`. Then fill placeholders with discovered repo facts and user-approved defaults. Copy `local-supervisor.sh.tmpl`, `guarded-role-runner-common.sh.tmpl`, and the selected agent wrapper template from `assets/runners/` into the location the target repo expects. Make `setup-labels.sh`, `doctor.sh`, and rendered runner scripts executable.

Bootstrap may edit target-repo files, but it must keep `.agent-loops/config.yaml` and `.agent-loops/context.md` as the durable contracts future ticks read. Future ticks reconstruct all state from `.agent-loops/` and host state.

## Critical Decisions

Write a Bootstrap Report in the target repo or in the conversation. Include:

- `trust_posture`, which defaults to `strict`, and the editable `trusted_actors` list. In strict mode, only issues authored by these actors are executable; external work needs a trusted-authored dispatch issue.
- Proof commands found or missing. Missing proof is a human gate and prevents autonomous convergence.
- Context contract. Include the repo instruction files discovered (`AGENTS.md`, `CLAUDE.md`, `README.md`, `CONTRIBUTING.md`, path-local docs), generated paths, and any repo-specific rules that role ticks must read before editing or reviewing.
- Runner and credential boundary. The local supervisor is the only V1 runner surface. Managed background mode is local and controllable with `--status` and `--stop`. Manual guarded ticks are for debugging. Codex Automations, Claude `/loop`, hosted CI/bot runners, cron, and launchd are outside the V1 default.
- Doctor command. In normal setup, run `.agent-loops/doctor.sh` yourself through `--arm`; only tell the user to run it manually when setup is blocked or they requested manual setup.
- First trial. Normal setup creates the safe smoke-test issue from `.agent-loops/FIRST-TRIAL-ISSUE.md`. For manual setup, point the user at that file and show both the guided one-command path and the manual commands.
- Budget defaults and any requested changes. Budget increases require human approval.
- Reviewer model. Empty `reviewer_model` means same-model adversarial review; a configured override is the recommended quality upgrade.

## Dry-Run Walkthrough

1. A trusted actor authors issue `123` and applies `ready`. If the original request came from an external or untrusted issue, the trusted actor writes a dispatch issue that summarizes the accepted work and links the source issue.
2. Implementer tick calls `list_ready_work`, verifies `is_trusted_actor(123)`, then calls `claim_work(123)`, which re-asserts trust before atomically creating `loop/impl/issue-123`, setting `in-progress`, implementing one unit, running configured proof, posting an implementer marker, and calling `open_change`.
3. Reviewer tick calls `read_state`, `get_head_sha`, and `read_markers`. If proof fails or it finds blocking defects, it sets `needs-fix`. If local proof and review pass, it waits for hosted checks, ingests inline external bot review comments, compares hosted failures with the default branch baseline, and only then converges to `ready-for-human` or `ready-for-human-baseline-red`. A clean first pass converges without a forced fix cycle, but pending hosted checks stay pending until a later tick can classify them.
4. (Only if `needs-fix`) Fixer tick reads reviewer feedback, patches the branch, runs proof, posts a fixer marker with an incremented cycle, and returns the change to review.
5. (Only if a cycle happened) Reviewer tick re-checks the new head. If proof passes and no blocking defects remain, it sets `ready-for-human` or `ready-for-human-baseline-red` based on hosted-check classification.
6. If proof is absent, the state becomes `unproven`. If the cycle cap is hit with blocking defects, the state becomes `did-not-converge`. If repeated runner kills exceed the retry cap, the state becomes `stalled`.

## Bootstrap Report Template

```md
# Autonomous Work Loops Bootstrap Report

- Host: GitHub
- Authenticated GitHub user:
- Trust posture:
- Trusted actors:
- Required labels:
- Proof commands:
  - test:
  - build:
  - lint:
- Context:
  - repo instructions:
  - generated paths:
  - repo-specific rules:
- Doctor:
- First trial issue:
- Runner:
- Credentials:
- Budgets:
- Reviewer model:
- Critical decisions:
- Human gates:
```
