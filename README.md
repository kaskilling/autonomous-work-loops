# autonomous-work-loops

A portable agent **skill** that turns a repo into a reviewed, converging, multi-agent PR workflow. It is currently **pre-release**: author-only strict-trust rejection now passes, but public release is still blocked until the allowlisted dispatch happy path runs in a loop-engine surface that can mutate Git.

Tag an issue `ready`. An **Implementer** claims it, writes the change on an isolated branch, proves it, and opens a PR. A **Reviewer** adversarially reviews it. If defects are found, a **Fixer** addresses the feedback and the reviewer re-checks the new head. When proof passes and no blocking defects remain, the PR is labeled `ready-for-human` for you to merge. No human in the loop until the end.

It is **not a daemon**. It's a bootstrapper plus a stateless single-tick executor: an external scheduler (cron, `/loop`, or CI) re-invokes one role per tick, and all state lives on the host (labels + commit-stamped marker comments), never in agent memory.

## How it differs from `ralph-loop`

`ralph-loop` feeds one prompt back to one agent until a promise is true. `autonomous-work-loops` runs **three coordinated roles** with host-state-driven convergence, adversarial proof-anchored review, trust-gated work intake, atomic multi-machine claiming, and enforced cost walls. Single-agent retry vs. a multi-agent reviewed pipeline.

## Install

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
# -> discovers host/proof/trust, renders .agent-loops/, emits runners, writes a Bootstrap Report

# 2. Let a scheduler run ticks (the runner is the cost wall)
*/15 * * * * /repo/.agent-loops/runners/reviewer.sh
```

## Safety (read before pointing it at a credentialed repo)

- **Trust-gated intake**: only trusted actors' `ready` issues should be picked up (posture inferred from repo visibility; editable `trusted_actors`). In strict mode, the issue author must be in `trusted_actors`; external requests need a trusted maintainer to create a dispatch issue and label that issue `ready`. Current status: strict untrusted-author rejection passed in `build/GATE-RESULTS.md`; allowlisted dispatch acceptance is blocked by a nested Codex `.git` transport boundary.
- **Proof is a precondition**: no test/build/lint command → work is labeled `unproven` and handed to a human; it never auto-converges.
- **Human gates**: merge, deploy, secrets, protected paths, budget increases, and playbook changes always stop for a human.
- **Cost walls**: every tick runs under an external `timeout`; runaway cycles cap out and escalate.

## Repo layout

- `skill/autonomous-work-loops/` — the shippable skill (SKILL.md + references + assets)
- `design/` — the source of truth: `adr/` (10 decisions), `CONTEXT.md` (glossary), `ECOSYSTEM.md`, `PLAN-v2-target.md`
- `build/` — the build plan codex executed, its build report, and the post-build evaluation

## Status

V1 is implemented and baseline-tested end-to-end on a live private GitHub repo with Codex (`ttl-cache-loop-test`; see `build/TEST-RESULTS.md`). The tested baseline is GitHub + local Codex runner + non-browser proof + permissive private-repo trust. A later gate smoke retest fixed the strict untrusted-author rejection path, but the allowlisted dispatch happy path is still blocked by Codex `.git` write denial inside the tick process; see `build/GATE-RESULTS.md`.

| Capability | Status | Notes |
|---|---|---|
| GitHub bootstrap and single-tick Implementer/Reviewer/Fixer loops | **Implemented** | Shipped in `skill/autonomous-work-loops/`. |
| Live Codex baseline on a private GitHub repo with pytest proof | **Tested once** | Passed in `build/TEST-RESULTS.md`. |
| Strict-trust rejection | **Retest PASS** | T2/T3/T4 passed under author-only semantics; see `build/GATE-RESULTS.md`. |
| Strict dispatch acceptance | **Blocked by transport** | T5 trusted the allowlisted author but could not claim because Codex could not write `.git/FETCH_HEAD`; see `build/GATE-RESULTS.md`. |
| Failed-proof routing | **Smoke-tested PASS** | Red proof routed to `needs-fix`; see `build/GATE-RESULTS.md`. |
| No-proof, duplicate-claim, stale-claim, and true unattended cron variants | **Designed, not fully run** | Tracked in `build/TEST-PLAN.md`; run after strict-trust is fixed. |
| Browser/Playwright proof under Codex sandbox | **Known environment constraint** | Use CI or another runner when local Codex sandbox cannot run browser proof. |
| Maintainer Loop, Core Memory, `loopctl`, evidence consolidation, multi-host adapters | **Designed for V2** | Preserved in `design/PLAN-v2-target.md`; not active in V1. |
