# BUILD PLAN — `autonomous-work-loops` skill (V1)

Historical note: this was the original V1 build plan. ADR-0003 was amended after the first live test, so the current skill converges on a clean proven first pass and does not require a mandatory fix cycle.

You are an autonomous build agent. Build a **skill** named `autonomous-work-loops` exactly to this spec. This plan is self-contained; the authoritative design rationale is in `../design/adr/` (read `0000-index.md` first, then any ADR you need). Do **not** re-litigate design decisions — they are settled. Your job is to render them into a working skill.

## 0. Operating rules for you, the build agent

- **Read `../design/adr/0000-index.md` and `../design/ECOSYSTEM.md` before writing anything.** They are the source of truth.
- **Stay in V1 scope.** Do NOT build: a Maintainer Loop, evidence consolidation, Core Memory regeneration, autonomous playbook mutation, a `loopctl` program, or non-GitHub adapters. These are V2. If you find yourself writing them, stop.
- **The skill is prose/markdown, not a runtime framework** (ADR-0009). The only executable artifacts allowed are: (a) a small `install.sh`, (b) runner *templates* under `assets/`, and (c) optional tiny read-only shell snippets the tick instructions tell the agent to run (e.g. `git diff --numstat`). No daemon, no orchestrator program, no Python helper.
- Output goes in `../skill/autonomous-work-loops/`. Create it.
- After building, run the self-verification checklist in §6 and write `../build/BUILD-REPORT.md` with pass/fail per item.
- Commit your work to git with clear messages.

## 1. Package layout to produce

```
skill/autonomous-work-loops/
├── SKILL.md                      # Router. <100 lines. Frontmatter + mode dispatch.
├── references/
│   ├── bootstrap.md              # Discovery checklist, setup model, Critical Decisions, Bootstrap Report
│   ├── adapter-github.md         # The 9 named host operations, implemented for GitHub via `gh`/git
│   ├── state-model.md            # Labels + SHA-stamped marker comment grammar (versioned)
│   ├── loop-implementer.md       # Implementer tick playbook (default, repo-overridable)
│   ├── loop-reviewer.md          # Reviewer tick playbook (adversarial, proof-anchored)
│   ├── loop-fixer.md             # Fixer tick playbook
│   ├── convergence.md            # Outcomes: ready-for-human / needs-fix / did-not-converge / unproven / stalled
│   ├── claiming.md               # Work Claim: branch-ref atomicity + advisory label + stale reclaim
│   ├── budgets.md                # State-derived vs external-wall enforcement; default budget values
│   ├── evidence-capture.md       # V1 forward-compatible capture + threshold tiny-PR suggestion
│   └── safety.md                 # Trust-gated intake + human gates (consolidated safety contract)
└── assets/
    ├── agent-loops-template/     # What bootstrap renders into the TARGET repo's .agent-loops/
    │   ├── config.yaml           # Annotated, with the V2 keys present-but-dormant
    │   └── playbooks/{implementer,reviewer,fixer}.md
    ├── runners/
    │   ├── cron.sh.tmpl          # `timeout N <agent-cmd> "Load the skill and run one <role> tick"` (budget wall)
    │   ├── loop.md.tmpl          # /loop invocation per role (Claude Code)
    │   └── github-actions.yml.tmpl  # scheduled workflow, wall = timeout-minutes; bot-token note
    └── install.sh                # symlink/copy this folder into ~/.claude ~/.codex ~/.agents skills dirs
```

`SKILL.md` MUST be under 100 lines and act as a router (ADR-0009 spirit): detect mode (bootstrap vs tick), point to the right reference. Progressive disclosure — details live in `references/`.

## 2. Frontmatter (exact requirements)

```yaml
---
name: autonomous-work-loops
description: <see below>
metadata:
  short-description: Set up autonomous implement/review/fix work loops in a repo
---
```

`description` must follow the write-a-skill rule: first sentence = what it does, second = "Use when…" with concrete triggers. Max ~1024 chars, third person. It must make clear this is BOTH a bootstrapper and a per-tick executor, and name the trigger words (work loops, autonomous PR, implement/review/fix loop, ready label). Include the Codex `metadata.short-description` (Claude ignores it harmlessly — ECOSYSTEM §3).

## 3. The decisions you must render faithfully (do not deviate)

Each is an ADR; cite it in the relevant reference file so the contract is traceable.

1. **Two modes, zero cross-tick memory (ADR-0001).** Tick mode reconstructs all state from host + `.agent-loops/`. Never instruct the agent to "remember" anything across ticks.
2. **State = labels + SHA-stamped marker comments (ADR-0002).** Define the marker grammar in `state-model.md`, versioned: `<!-- loop:<role> v=1 reviewed_sha=<sha> verdict=<...> cycle=<n> ts=<iso> -->`. Ticks compare `reviewed_sha` to current head to decide act vs no-op.
3. **Convergence on clean proven pass; bounded by cap (ADR-0003 amended).** Current rule: Reviewer → `ready-for-human` if proof passed and the current head is clean. Fix cycles happen only when real blocking defects are found, and those cycles are bounded by the cap. At cap: non-blocking → hand off with items listed; blocking → `did-not-converge`. Put this in `convergence.md`.
4. **Trust-gated intake (ADR-0004).** Bootstrap infers posture from repo visibility/collaborators; emits editable `trusted_actors`. Implementer claims only trust-vetted `ready` issues. In `safety.md` + `bootstrap.md`.
5. **Proof is a precondition (ADR-0005 + 0010 amendment).** Bootstrap discovers proof commands → `config.yaml` `proof:`. Tick: pass→flow, fail→`needs-fix`, absent→`unproven`+human gate. **No-proof repos never auto-converge.** In `bootstrap.md`, `convergence.md`, `safety.md`.
6. **V1 capture + human-gated tiny-PR suggestion (ADR-0006).** Loops append structured evidence in the V2 schema to `.agent-loops/evidence/inbox/`. At threshold (default 3, same theme+scope) the Reviewer tick opens a **tiny PR** against the playbook proposing the addition. NO maintainer, NO consolidation, NO auto-apply. `evidence-capture.md`. `config.yaml` carries the dormant V2 keys.
7. **Budget enforcement split (ADR-0007).** State-derived (cycles, changed-files, concurrency) checked by the tick at boundaries; continuous (runtime/cost) enforced by the runner's external wall. Killed tick: release claim, retry ≤2, then `stalled`. `budgets.md` + runner templates carry the `timeout`.
8. **Claim atomicity via branch-ref push (ADR-0008).** Branch `loop/impl/issue-<id>`; label flip is advisory only; stale reclaim is state-derived from marker ts. `claiming.md`.
9. **GitHub-only behind named prose adapter seam (ADR-0009).** Define exactly these operations in `adapter-github.md`: `list_ready_work`, `claim_work`, `read_state`, `post_marker`, `read_markers`, `set_label`, `open_change`, `get_head_sha`, `is_trusted_actor`. All other references call operations *by name*, never raw `gh`. The local `mkdir`/markdown-queue fallback is "another implementation of the same contract," noted but not built out in V1.
10. **Adversarial, proof-anchored review; opt-in cross-model (ADR-0010).** Reviewer playbook forces disconfirmation and anchors to proof output. `config.yaml` has `reviewer_model:` override (default empty = same model). `loop-reviewer.md`.

## 4. `config.yaml` (target repo) — required keys

Render an annotated template. V1-active keys: `host`, `proof: {test,build,lint}`, `trusted_actors`, `trust_posture`, `labels: {ready,in_progress,needs_fix,ready_for_human}`, `reviewer_model`, `budgets:` (all from ADR-0007 + the convergence cap from ADR-0003), `branch_prefix`. Present-but-dormant V2 keys (commented, marked `# v2`): `evolution.enabled: false`, `evidence.threshold: 3`, `maintainer.*`. The dormant keys are what make V1→V2 an additive enable (ADR-0006), so they MUST be present even though unused.

## 5. Default budget block (use these values)

```yaml
budgets:
  max_active_implementers: 1
  max_active_reviewers: 1
  max_active_fixers: 1
  max_reviewer_fixer_cycles_per_change: 2
  max_runtime_minutes_per_loop: 30
  max_changed_files_without_human_review: 20
  kill_retries: 2
  require_human_approval_for_budget_increase: true
```

## 6. Self-verification checklist (run before declaring done; record in BUILD-REPORT.md)

- [ ] `SKILL.md` exists, has valid frontmatter, is <100 lines, routes by mode.
- [ ] `description` has a "Use when" clause and concrete triggers.
- [ ] All 11 reference files and all assets in §1 exist and are non-empty.
- [ ] Every one of the 10 ADRs is cited in at least one reference file.
- [ ] The 8 adapter operations are each defined with a concrete `gh`/git recipe.
- [ ] No reference outside `adapter-github.md` calls `gh` directly (grep to confirm).
- [ ] Marker grammar is versioned (`v=1`) and parseable.
- [ ] `config.yaml` has all V1-active keys AND the dormant `# v2` keys.
- [ ] Runner templates contain an external `timeout`/`timeout-minutes` wall.
- [ ] No V2 machinery built (no maintainer/consolidation/loopctl/non-GitHub adapter) — grep to confirm absence.
- [ ] `install.sh` targets all three skill dirs (`.claude`, `.codex`, `.agents`).
- [ ] A "dry-run walkthrough" section in SKILL.md or bootstrap.md traces: one `ready` issue → claim → implement → prove → PR → review → fix → converge, naming the state transitions.

## 7. Definition of done

The skill, when read by a fresh agent in a target repo, contains enough to (a) bootstrap `.agent-loops/` + emit runners, and (b) execute any single role tick correctly and idempotently — with zero design decisions left to the executing agent's discretion beyond repo-specific judgment. Write `BUILD-REPORT.md` with the checklist results and any deviations (with justification).
