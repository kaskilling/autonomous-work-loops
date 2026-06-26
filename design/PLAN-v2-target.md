# Autonomous Work Loops Skill Plan

## Goal

Create a portable Codex skill that bootstraps autonomous work loops in any software repository, regardless of host, model, or agent product. The skill should make the first setup low-friction, self-evolving by default, and flexible enough for future loop extensions.

## Core Decisions

The skill is an **Autonomous Work Loop Skill**, not a runtime framework. It teaches an agent how to inspect a repository, create repo-local loop guidance, and run loops using the best available local or host-native tools.

Bootstrap is **host-agnostic from the start**. It detects the code host, work tracker, review host, CI, available CLIs, credentials, repo docs, proof commands, and existing agent guidance before rendering files.

Bootstrap creates a repo-local `.agent-loops/` system by default:

```text
.agent-loops/
  config.yaml
  playbooks/
    implementer.md
    reviewer.md
    fixer.md
    maintainer.md
  memory/
    core.md
  evidence/
    inbox/
      .gitkeep
    ledger.jsonl
  extensions/
    .gitkeep
  bin/
    loopctl
```

The setup uses **discovery-first with template fallback**. The skill fills a setup model from repo discovery, then renders a reusable Loop Template with safe defaults. Unknowns become editable defaults and Bootstrap Report warnings unless they are Critical Decisions.

Bootstrap must also detect existing automation before creating loop behavior. Existing reviewer bots, CI checks, host automations, CodeBuddy-style configuration, Dependabot/Renovate, GitHub Actions, GitLab schedules, and repo-specific agent instructions should be treated as integration points, not ignored.

## End-To-End Operating Model

The skill should make the following path explicit:

1. User invokes the skill in a repository.
2. Bootstrap discovers repo structure, guidance, host, tracker, review flow, CI, existing automation, credentials, and available agent products.
3. Bootstrap fills a setup model, renders `.agent-loops/`, validates it, and writes a Bootstrap Report.
4. User or host automation invokes one loop at a time through a Loop Invocation Contract.
5. Each loop creates or verifies a Work Claim before changing anything.
6. Working loops use playbooks and Core Memory, run proof commands, update host state, and write evidence into the Evidence Inbox.
7. Maintainer Loop periodically consolidates evidence into the Evidence Ledger, proposes playbook updates, and regenerates Core Memory through a review change.

This keeps the skill from becoming a daemon framework while still making loop execution concrete.

## Canonical Loops

The core loop system has three default loops:

- **Implementer Loop**: claims ready work, creates an isolated branch or worktree, implements the change, proves it, pushes a branch, and opens review.
- **Reviewer Loop**: reviews unreviewed or updated changes, leaves actionable feedback, records evidence, or marks ready for human review.
- **Fixer Loop**: fixes unresolved review feedback, failed checks, and conflicts on loop-owned branches, proves the result, and responds to or resolves feedback.

The optional fourth loop is:

- **Playbook Maintainer Loop**: reviews accumulated evidence and proposes playbook/core-memory updates. It runs on explicit request, low-frequency schedule, failed convergence, or evidence thresholds; it does not run for every issue or review.

## Loop Invocation Contract

Every Execution Profile must explain how to invoke a loop with the current agent product. The invocation contract is model-agnostic and contains:

- role: implementer, reviewer, fixer, maintainer, or extension name
- target: work item, review change, local queue item, or evidence sweep
- guidance: Core Memory plus selected playbooks
- host adapter: how to read and update host state
- credential profile: which identity and model access to use
- allowed actions and Human Gates
- Loop Budget for this run
- Work Claim behavior
- evidence behavior
- stop conditions and Bootstrap Report updates

For local usage, bootstrap should generate copyable commands or prompts for each loop. For host CI or scheduler usage, bootstrap should generate a profile but require explicit human approval before adding scheduled automation.

## Claiming And Locking

Every loop that mutates code or host state must create or verify a Work Claim before starting.

Preferred claim order:

1. Host-native atomic state transition, assignment, or label/status change.
2. Host-native comment/check marker that includes loop role, target, branch, and commit SHA.
3. Local lock directory for local queues or single-machine workflows.

If a claim cannot be created, the loop must skip the item and record the blocker in the Bootstrap Report or evidence. Duplicate work is a design failure, not an acceptable race.

## Self-Evolution Model

Self-evolution is enabled by default but not silent.

Working loops write lightweight evidence through `loopctl record-evidence`. Evidence events include source references, capped excerpts, themes, summaries, proposed rules, confidence, outcomes, and proof references.

Working loops should write new events into `.agent-loops/evidence/inbox/` instead of appending directly to one shared ledger from every branch. The Maintainer Loop consolidates inbox events into `.agent-loops/evidence/ledger.jsonl`, clusters repeated evidence, and opens a **Playbook Update Change** when the evidence is strong enough. That change edits `.agent-loops/playbooks/*.md` and regenerates `.agent-loops/memory/core.md`.

`memory/core.md` is committed, capped, and generated. It is a compact summary of current repo loop guidance, not the source of truth. The source of truth is playbooks plus evidence.

Evidence events should include source trust and Guidance Scope. External contributor comments, generated comments, and untrusted text can support investigation but must not become durable playbook rules without corroborating proof or human confirmation. Scope prevents a rule learned in one package or framework from becoming an accidental repo-wide rule.

## Loop Control Helper

Bootstrap creates one helper command:

```bash
.agent-loops/bin/loopctl
```

Initial commands:

```bash
.agent-loops/bin/loopctl record-evidence ...
.agent-loops/bin/loopctl regenerate-core-memory
.agent-loops/bin/loopctl validate
```

The helper handles deterministic mechanics only: JSONL schema, excerpt caps, generated-file headers, validation, and memory regeneration. Agents keep responsibility for judgment.

Use Python for `loopctl` when available. If Python is missing, bootstrap should fall back to scriptless mode or a minimal shell-compatible evidence path rather than blocking setup.

`loopctl` may later grow claim helpers if local queue workflows need them, but v1 should keep host-native claiming in Host Adapters unless repeated local locking proves worth scripting.

## Existing Automation Coexistence

Bootstrap must choose one of three coexistence modes when it detects existing automation:

- **Observe**: leave existing automation in charge and consume its comments/checks as evidence.
- **Integrate**: map loop playbooks or repo standards into the existing tool's configuration when that tool supports it.
- **Own**: create loop behavior only where no existing automation already owns the responsibility.

For example, in a repo with CodeBuddy-style review automation, the Reviewer Loop should not blindly create duplicate review comments. Bootstrap should detect review configuration, reuse repo standards/custom prompts when available, and decide whether this loop system observes existing review output, adds specialized extensions, or owns only implementer/fixer/maintainer responsibilities.

## Execution And Credentials

Bootstrap creates editable **Execution Profiles**. It prefers a local interactive profile when the user is running the skill locally and host CLI credentials work. It can also add host CI or scheduler profiles when detected.

Bootstrap creates **Credential Profiles** without secrets. It detects host CLIs and agent products such as Codex, Claude, Cursor, OpenCode, and API-backed setups. It defaults to current user credentials with least-privilege loop actions. Bot or service accounts are extension profiles.

Ask the user only when profiles differ materially in cost, risk, permissions, or required autonomy.

## Triggers

Use host-native triggers when present. If none exist, bootstrap creates this fallback vocabulary:

- `ready`
- `in-progress`
- `needs-fix`
- `ready-for-human`

Default triggers:

- Implementer starts from ready work.
- Reviewer starts from opened or updated review changes.
- Fixer starts from unresolved blocking feedback, failed checks, or conflicts.
- Maintainer starts manually, on low-frequency schedule, after failed convergence, or when evidence thresholds are met.

## Human Gates

Loops may work on isolated branches, open or update review changes, and record evidence.

Human approval is required for:

- merge to protected/default branch
- deploy or release
- secret access or modification
- production data access or modification
- billing or cost setting changes
- destructive actions
- security policy, auth, permissions, or compliance changes
- converting evidence into durable playbook guidance
- raising cost or concurrency budgets

## Default Budgets

Start conservative and make limits editable:

```yaml
budgets:
  max_active_implementers: 1
  max_active_reviewers: 1
  max_active_fixers: 1
  max_reviewer_fixer_cycles_per_change: 2
  max_maintainer_runs_per_week: 1
  max_evidence_events_per_change: 10
  max_runtime_minutes_per_loop: 30
  max_changed_files_without_human_review: 20
  require_human_approval_for_budget_increase: true
```

## Extension Contract

Extensions use the open/closed principle. They extend a Canonical Loop without changing the core lifecycle.

An extension declares:

```yaml
name: accessibility-reviewer
extends: reviewer
trigger:
  paths:
    - "src/**/*.tsx"
    - "app/**/*.jsx"
playbooks:
  - ".agent-loops/playbooks/reviewer.md"
  - ".agent-loops/extensions/accessibility-reviewer.md"
allowed_actions:
  - read_code
  - run_safe_checks
  - leave_review_comments
evidence:
  themes:
    - accessibility
budget:
  max_runs_per_change: 1
human_gates:
  - modify_policy
  - merge
```

## Skill Package Shape

Create the skill as `autonomous-work-loops` unless renamed later.

Recommended package:

```text
autonomous-work-loops/
  SKILL.md
  references/
    bootstrap.md
    hosts.md
    playbooks.md
    loopctl.md
    extensions.md
    evidence.md
  assets/
    agent-loops-template/
      config.yaml
      playbooks/
      memory/
      evidence/
      extensions/
      bin/loopctl
```

`SKILL.md` is the Skill Router. It stays concise and tells the agent which references to read based on the repo and user request.

References provide progressive disclosure:

- `bootstrap.md`: discovery checklist, setup model, critical decisions, Bootstrap Report.
- `hosts.md`: host adapter patterns for GitHub, GitLab, Bitbucket, Jira, Linear, and local queues.
- `playbooks.md`: role playbook structure and default guidance.
- `loopctl.md`: helper command behavior and usage patterns.
- `extensions.md`: Loop Extension contract.
- `evidence.md`: ledger schema, references, excerpts, thresholds, and maintainer flow.

Assets provide deterministic bootstrap structure. Agents adapt the template after discovery instead of rewriting boilerplate.

## Bootstrap Report

After setup, the agent writes a short report with:

- detected host and workflow vocabulary
- detected execution profiles
- detected credential profiles
- created or modified files
- selected defaults
- human gates
- loop start commands
- optional host scheduler or CI next steps
- unresolved Critical Decisions
- detected existing automation and selected coexistence mode
- generated loop invocation commands or prompts

If host credentials allow it, bootstrap may open the setup as a PR or MR. Otherwise it leaves local changes ready for review.

## Critical Decisions To Ask Humans

Bootstrap should infer most details. Ask only when the decision affects autonomy, risk, cost, or ownership:

- Whether loops may push branches or only draft local changes.
- Whether `.agent-loops/` may be committed.
- Which execution surface to use when multiple viable surfaces differ materially.
- Which credential profile to use when cost or permission boundaries differ.
- Whether self-evolution may create playbook update review changes.
- Whether to raise default budget/concurrency limits.
- Whether any repo-specific protected areas require additional Human Gates.
- Whether to add or enable scheduled host automation.
- Whether to replace, integrate with, or observe existing automation when responsibilities overlap.

## Next Implementation Steps

1. Create the `autonomous-work-loops` skill skeleton with `SKILL.md`, references, and template assets.
2. Draft `SKILL.md` as a concise router.
3. Draft the reference docs using the decisions above.
4. Implement and test `assets/agent-loops-template/bin/loopctl`.
5. Create the template playbooks, config, empty ledger, and generated-memory header.
6. Validate the skill with the skill validator.
7. Forward-test bootstrap on at least one GitHub-like repo, one local/no-host repo, one mature repo with existing automation, and one monorepo or multi-package repo.
