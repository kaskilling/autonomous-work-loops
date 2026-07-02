# Bootstrap Reference

Cites ADR-0001, ADR-0004, ADR-0005, ADR-0006, ADR-0007, ADR-0009, ADR-0010.

Bootstrap mode sets up `.agent-loops/` in the target repository and exits. It discovers current repo facts, renders config and runner artifacts from `assets/`, and writes a Bootstrap Report. It does not start a loop, spawn a daemon, or assume future ticks remember anything.

## Discovery Checklist

1. Confirm the repo host is GitHub for V1. Use `adapter-github.md` as the only V1 host implementation.
2. Confirm GitHub CLI access before writing config:
   - `gh auth status`
   - `gh api user --jq .login`
   - `gh repo view --json nameWithOwner,owner,visibility,viewerPermission,defaultBranchRef,hasIssuesEnabled`
3. Identify default branch, current remote, repository visibility, explicit loop dispatchers, and whether issues and pull requests are enabled.
4. Discover proof commands for `test`, `build`, and `lint` from package scripts, build files, CI workflows, README instructions, and existing developer docs.
5. Infer trust posture:
   - `permissive` for solo private repos.
   - `strict` for public or multi-contributor repos.
6. Build `trusted_actors` from the authenticated GitHub login, explicit maintainers, owners, or named loop dispatchers. Add the authenticated login when `gh api user --jq .login` succeeds and the user is the repo owner, has maintainer/admin/write permission, or is the person explicitly setting up the loop. Do not add every collaborator by default. Leave the list editable. If the authenticated login cannot be proven, stop and ask the user to run `gh auth login`.
7. Render the only V1 runner surface: the local foreground supervisor. Render from `assets/runners/`: `local-supervisor.sh.tmpl` plus the guarded role runner for the local harness (`codex.sh.tmpl` for Codex CLI, `claude.sh.tmpl` for Claude Code, or both when unsure). The supervisor loops in one visible terminal and invokes exactly one guarded role tick at a time. The guarded role runners keep trust, claim, Git mutation, proof, PRs, labels, and markers in the parent shell; nested Codex or Claude edits the working tree only or returns review text. This avoids managed-sandbox `.git` write denial while keeping the branch-ref claim deterministic. The external cost wall prefers `timeout`, then `gtimeout` (coreutils on macOS), else a background-kill fallback baked into the runner. Record credential implications. Do not install Codex Automations, Claude `/loop`, system cron, launchd, or GitHub Actions schedules during V1 bootstrap.
8. Render `.agent-loops/config.yaml`, `.agent-loops/context.md`, `.agent-loops/playbooks/implementer.md`, `.agent-loops/playbooks/reviewer.md`, `.agent-loops/playbooks/fixer.md`, and `.agent-loops/evidence/inbox/`.

## Required Labels

Bootstrap must either create these labels with user approval or print the exact commands in the Bootstrap Report:

```sh
gh label create ready --color 0E8A16 --description "Trusted work ready for autonomous-work-loops intake" --force
gh label create in-progress --color FBCA04 --description "Autonomous-work-loops has claimed this work" --force
gh label create needs-fix --color D93F0B --description "Reviewer found blocking defects or proof failed" --force
gh label create ready-for-human --color 5319E7 --description "Proof passed and autonomous review converged" --force
gh label create unproven --color BFDADC --description "No accepted proof command is configured or available" --force
gh label create did-not-converge --color B60205 --description "Review/fix cycle cap reached with blockers remaining" --force
gh label create stalled --color 000000 --description "Runner exceeded retry or runtime wall and needs a human" --force
```

Do not treat missing labels as a background concern. Without these labels, the state machine is not visible or operable.

## Setup Model

Copy the template tree from `assets/agent-loops-template/` into the target repo as `.agent-loops/`. Then fill placeholders with discovered repo facts and user-approved defaults. Copy the selected runner template from `assets/runners/` into the location the target repo expects.

Bootstrap may edit target-repo files, but it must keep `.agent-loops/config.yaml` and `.agent-loops/context.md` as the durable contracts future ticks read. Future ticks reconstruct all state from `.agent-loops/` and host state.

## Critical Decisions

Write a Bootstrap Report in the target repo or in the conversation. Include:

- `trust_posture`, why it was inferred, and the editable `trusted_actors` list. In strict mode, only issues authored by these actors are executable; external work needs a trusted-authored dispatch issue.
- Proof commands found or missing. Missing proof is a human gate and prevents autonomous convergence.
- Context contract. Include the repo instruction files discovered (`AGENTS.md`, `CLAUDE.md`, `README.md`, `CONTRIBUTING.md`, path-local docs), generated paths, and any repo-specific rules that role ticks must read before editing or reviewing.
- Runner and credential boundary. The local foreground supervisor is the only V1 runner surface. Manual guarded ticks are for debugging. Codex Automations, Claude `/loop`, hosted CI/bot runners, cron, and launchd are outside the V1 default.
- Budget defaults and any requested changes. Budget increases require human approval.
- Reviewer model. Empty `reviewer_model` means same-model adversarial review; a configured override is the recommended quality upgrade.

## Dry-Run Walkthrough

1. A trusted actor authors issue `123` and applies `ready`. If the original request came from an external or untrusted issue, the trusted actor writes a dispatch issue that summarizes the accepted work and links the source issue.
2. Implementer tick calls `list_ready_work`, verifies `is_trusted_actor(123)`, then calls `claim_work(123)`, which re-asserts trust before atomically creating `loop/impl/issue-123`, setting `in-progress`, implementing one unit, running configured proof, posting an implementer marker, and calling `open_change`.
3. Reviewer tick calls `read_state`, `get_head_sha`, and `read_markers`. If proof fails or it finds blocking defects, it sets `needs-fix`. If proof passes and the head is clean, it converges directly to `ready-for-human` — no fix cycle is forced.
4. (Only if `needs-fix`) Fixer tick reads reviewer feedback, patches the branch, runs proof, posts a fixer marker with an incremented cycle, and returns the change to review.
5. (Only if a cycle happened) Reviewer tick re-checks the new head. If proof passes and no blocking defects remain, it sets `ready-for-human`.
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
- Runner:
- Credentials:
- Budgets:
- Reviewer model:
- Critical decisions:
- Human gates:
```
