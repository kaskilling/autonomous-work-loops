# autonomous-work-loops

A portable agent **skill** that turns a repo into a reviewed, converging, multi-agent PR workflow. It is currently **Limited V1 GO for the local foreground supervisor**: strict trust, allowlisted dispatch, proof honesty, no-proof routing, duplicate claims, stale recovery, cost-wall recovery, cycle caps, cron-equivalent cadence, planted-defect review routing, and a fresh local-supervisor run have live fixture evidence.

Tag an issue `ready`. An **Implementer** claims it, writes the change on an isolated branch, proves it, and opens a PR. A **Reviewer** adversarially reviews it. If defects are found, a **Fixer** addresses the feedback and the reviewer re-checks the new head. When proof passes and no blocking defects remain, the PR is labeled `ready-for-human` for you to merge. No human in the loop until the end.

It is **not a daemon**. It's a bootstrapper plus a stateless single-tick executor: an explicit runner surface re-invokes one role per tick, and all state lives on the host (labels + commit-stamped marker comments), never in agent memory.

## How it differs from `ralph-loop`

`ralph-loop` feeds one prompt back to one agent until a promise is true. `autonomous-work-loops` runs **three coordinated roles** with host-state-driven convergence, adversarial proof-anchored review, trust-gated work intake, atomic multi-machine claiming, and enforced cost walls. Single-agent retry vs. a multi-agent reviewed pipeline.

## Install

Prerequisites for a target repo:

```sh
brew install gh coreutils
gh auth login
gh auth status
```

`gh` is required because V1 uses GitHub issues, PRs, labels, and comments as the host state. `coreutils` provides `gtimeout` on macOS for the guarded runner's external wall.

```sh
# clone, then install into all three skill dirs (.claude, .codex, .agents)
./skill/autonomous-work-loops/assets/install.sh            # copy
./skill/autonomous-work-loops/assets/install.sh --symlink  # or symlink one clone
```

Claude Code users can also install it as a plugin (see [PUBLISHING.md](PUBLISHING.md)).

## Use

```
# 1. Bootstrap once per repo
/autonomous-work-loops          # or: "set up autonomous work loops here"
# -> discovers host/proof/trust/current gh user, renders .agent-loops/, emits runners, writes a Bootstrap Report

# 2. Arm one runner surface
# Recommended:
# - Tested V1 path: .agent-loops/runners/local-supervisor.sh "$PWD"
# - Needs live fix/validation: Codex Automations, Claude /loop
```

V1's tested happy path is the local foreground supervisor. Manual guarded tick commands remain available for debugging, but they are not the intended happy path. Codex Automations and Claude `/loop` are real target surfaces, but live validation found permission/concurrency blockers, so they are not broad-launch paths yet. System cron and GitHub Actions schedules are out of V1 scope.

For step-by-step setup and first-trial instructions, see [V1-QUICKSTART.md](V1-QUICKSTART.md).

## Safety (read before pointing it at a credentialed repo)

- **Trust-gated intake**: only trusted actors' `ready` issues should be picked up (posture inferred from repo visibility; editable `trusted_actors`). In strict mode, the issue author must be in `trusted_actors`; external requests need a trusted maintainer to create a dispatch issue and label that issue `ready`. Current status: strict untrusted-author rejection and allowlisted dispatch acceptance both pass; the guarded Codex runner keeps Git mutation outside nested Codex so `.git` sandbox protection no longer blocks claim.
- **Proof is a precondition**: no test/build/lint command → work is labeled `unproven` and handed to a human; it never auto-converges.
- **Bounded context**: every tick starts from repo root, reads `.agent-loops/config.yaml` plus `.agent-loops/context.md`, then inspects only the issue/PR, proof logs, diffs, and relevant repo docs.
- **Human gates**: merge, deploy, secrets, protected paths, budget increases, and playbook changes always stop for a human.
- **Cost walls**: every tick runs under an external `timeout`; runaway cycles cap out and escalate.

## Repo layout

- `skill/autonomous-work-loops/` — the shippable skill (SKILL.md + references + assets)
- `design/` — the source of truth: `adr/` (10 decisions), `CONTEXT.md` (glossary), `ECOSYSTEM.md`, `PLAN-v2-target.md`
- `build/` — the build plan codex executed, its build report, and the post-build evaluation

## Status

V1 is implemented and baseline-tested end-to-end on live private GitHub repos with Codex (`ttl-cache-loop-test`; see `build/TEST-RESULTS.md`, and `awl-gate`; see `build/GATE-RESULTS.md`). The current Codex runner is guarded: shell owns Git/GitHub mutation and nested Codex edits the working tree only. That fixes the managed-sandbox `.git` write denial that blocked the earlier generated runner.

| Capability | Status | Notes |
|---|---|---|
| GitHub bootstrap and single-tick Implementer/Reviewer/Fixer loops | **Implemented** | Shipped in `skill/autonomous-work-loops/`. |
| Live Codex baseline on a private GitHub repo with pytest proof | **Tested once** | Passed in `build/TEST-RESULTS.md`. |
| Strict-trust rejection | **Retest PASS** | T2/T3/T4 passed under author-only semantics; see `build/GATE-RESULTS.md`. |
| Strict dispatch acceptance | **PASS** | T5 issue `#9` converged to PR `#10`; guarded runner issue `#11` converged to PR `#12`. |
| Failed-proof routing | **Smoke-tested PASS** | Red proof routed to `needs-fix`; see `build/GATE-RESULTS.md`. |
| No-proof, proof honesty, duplicate-claim, stale-claim, and reviewer idempotency | **Guarded-runner PASS** | T7/T8/T10/T11/T12 passed on live GitHub; see `build/GATE-RESULTS.md`. |
| Cost wall, cycle-cap, cron-equivalent cadence, and planted-defect model comparison | **Guarded-runner PASS** | Cost wall reached `stalled`; cycle cap reached `did-not-converge`; cron-equivalent cadence converged and no-opped; default and `gpt-5.4` reviewers caught the planted defect. |
| Browser/Playwright proof under Codex sandbox | **Known environment constraint** | Use CI or another runner when local Codex sandbox cannot run browser proof. |
| Local foreground supervisor as V1 runner surface | **Limited V1 GO** | Fresh fixture `awl-v1-local-supervisor` issue `#1` / PR `#2` reached `ready-for-human`; restart no-opped with one branch and one PR. |
| Codex Automations and Claude `/loop` as V1 runner surfaces | **NO-GO** | Codex Automations fired but exposed reviewer overlap and permission/profile issues; Claude `/loop` scheduled but blocked on skill-file permissions before the guarded tick. |
| Maintainer Loop, Core Memory, `loopctl`, evidence consolidation, multi-host adapters | **Designed for V2** | Preserved in `design/PLAN-v2-target.md`; not active in V1. |
