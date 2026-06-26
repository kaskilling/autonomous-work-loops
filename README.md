# autonomous-work-loops

A portable agent **skill** that turns a repo into a reviewed, converging, multi-agent PR factory you can leave running unattended.

Tag an issue `ready`. An **Implementer** claims it, writes the change on an isolated branch, proves it, and opens a PR. A **Reviewer** adversarially reviews it. A **Fixer** addresses the feedback. They cycle until the change converges — then it's labeled `ready-for-human` for you to merge. No human in the loop until the end.

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
*/15 * * * * cd /repo && timeout 30m <agent> --skill autonomous-work-loops --role reviewer
```

## Safety (read before pointing it at a credentialed repo)

- **Trust-gated intake**: only trusted actors' `ready` issues are picked up (posture inferred from repo visibility; editable `trusted_actors`).
- **Proof is a precondition**: no test/build/lint command → work is labeled `unproven` and handed to a human; it never auto-converges.
- **Human gates**: merge, deploy, secrets, protected paths, budget increases, and playbook changes always stop for a human.
- **Cost walls**: every tick runs under an external `timeout`; runaway cycles cap out and escalate.

## Repo layout

- `skill/autonomous-work-loops/` — the shippable skill (SKILL.md + references + assets)
- `design/` — the source of truth: `adr/` (10 decisions), `CONTEXT.md` (glossary), `ECOSYSTEM.md`, `PLAN-v2-target.md`
- `build/` — the build plan codex executed, its build report, and the post-build evaluation

## Status

V1 is complete and internally audited against all 10 ADRs. It has **not** yet been run end-to-end against a live GitHub repo — that's the v1 acceptance test (one `ready` issue → converged, proven, mergeable PR). V2 (self-evolution Maintainer Loop, multi-host) is designed in `design/` and enables additively.
