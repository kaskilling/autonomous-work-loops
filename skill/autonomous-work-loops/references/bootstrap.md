# Bootstrap Reference

Cites ADR-0001, ADR-0004, ADR-0005, ADR-0006, ADR-0007, ADR-0009, ADR-0010.

Bootstrap mode sets up `.agent-loops/` in the target repository and exits. It discovers current repo facts, renders config and runner artifacts from `assets/`, and writes a Bootstrap Report. It does not start a loop, spawn a daemon, or assume future ticks remember anything.

## Discovery Checklist

1. Confirm the repo host is GitHub for V1. Use `adapter-github.md` as the only V1 host implementation.
2. Identify default branch, current remote, repository visibility, collaborators or teams with write access, and whether issues and pull requests are enabled.
3. Discover proof commands for `test`, `build`, and `lint` from package scripts, build files, CI workflows, README instructions, and existing developer docs.
4. Infer trust posture:
   - `permissive` for solo private repos.
   - `strict` for public or multi-contributor repos.
5. Build `trusted_actors` from maintainers, owners, or explicit write-access dispatchers. Leave it editable.
6. Choose runner surface and render from `assets/runners/`: `codex.sh.tmpl` (default for a Codex-driven local loop), `cron.sh.tmpl` (generic agent), `loop.md.tmpl` (Claude Code `/loop`), or `github-actions.yml.tmpl` (scheduled CI). Headless agents load the skill by PROMPT, not by `--skill/--role` flags. The external cost wall prefers `timeout`, then `gtimeout` (coreutils on macOS), else a background-kill fallback baked into the runner. Record credential implications.
7. Render `.agent-loops/config.yaml`, `.agent-loops/playbooks/implementer.md`, `.agent-loops/playbooks/reviewer.md`, `.agent-loops/playbooks/fixer.md`, and `.agent-loops/evidence/inbox/`.

## Setup Model

Copy the template tree from `assets/agent-loops-template/` into the target repo as `.agent-loops/`. Then fill placeholders with discovered repo facts and user-approved defaults. Copy the selected runner template from `assets/runners/` into the location the target repo expects.

Bootstrap may edit target-repo files, but it must keep `.agent-loops/config.yaml` as the durable contract future ticks read. Future ticks reconstruct all state from `.agent-loops/` and host state.

## Critical Decisions

Write a Bootstrap Report in the target repo or in the conversation. Include:

- `trust_posture`, why it was inferred, and the editable `trusted_actors` list.
- Proof commands found or missing. Missing proof is a human gate and prevents autonomous convergence.
- Runner surface and credential boundary. CI runners require a scoped bot token, not silent reuse of personal local credentials.
- Budget defaults and any requested changes. Budget increases require human approval.
- Reviewer model. Empty `reviewer_model` means same-model adversarial review; a configured override is the recommended quality upgrade.

## Dry-Run Walkthrough

1. A trusted actor applies `ready` to issue `123`.
2. Implementer tick calls `list_ready_work`, verifies `is_trusted_actor(123)`, then calls `claim_work(123)`, which re-asserts trust before atomically creating `loop/impl/issue-123`, setting `in-progress`, implementing one unit, running configured proof, posting an implementer marker, and calling `open_change`.
3. Reviewer tick calls `read_state`, `get_head_sha`, and `read_markers`. If proof fails or it finds blocking defects, it sets `needs-fix`. If proof passes and the head is clean, it converges directly to `ready-for-human` — no fix cycle is forced.
4. (Only if `needs-fix`) Fixer tick reads reviewer feedback, patches the branch, runs proof, posts a fixer marker with an incremented cycle, and returns the change to review.
5. (Only if a cycle happened) Reviewer tick re-checks the new head. If proof passes and no blocking defects remain, it sets `ready-for-human`.
6. If proof is absent, the state becomes `unproven`. If the cycle cap is hit with blocking defects, the state becomes `did-not-converge`. If repeated runner kills exceed the retry cap, the state becomes `stalled`.

## Bootstrap Report Template

```md
# Autonomous Work Loops Bootstrap Report

- Host: GitHub
- Trust posture:
- Trusted actors:
- Proof commands:
  - test:
  - build:
  - lint:
- Runner:
- Credentials:
- Budgets:
- Reviewer model:
- Critical decisions:
- Human gates:
```
