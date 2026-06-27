# ADR Index — Autonomous Work Loops Skill

Decisions from the grilling session, in dependency order. ADR-0001 is the root constraint; most others derive from it.

| ADR | Decision | Depends on |
|-----|----------|------------|
| [0001](0001-skill-is-bootstrapper-plus-single-tick-executor.md) | Skill = bootstrapper + stateless single-tick executor; zero agent memory between ticks; hands-off scheduler | — |
| [0002](0002-cross-tick-state-labels-plus-sha-stamped-marker-comments.md) | Cross-tick state = labels (coarse) + SHA-stamped marker comments (commit-scoped truth) | 0001 |
| [0003](0003-convergence-requires-one-fix-cycle-and-bounded-escalation.md) | Converge on a clean proven pass (mandatory-fix-cycle rule dropped 2026-06-26); fix cycles only on real defects, bounded by cap; blocking-at-cap → `did-not-converge` | 0001, 0002, 0005, 0010 |
| [0004](0004-trust-gated-work-intake.md) | Work intake is trust-gated; defaults inferred from repo visibility; editable `trusted_actors` | 0001 |
| [0005](0005-proof-is-a-precondition-absence-degrades-not-fakes.md) | Proof is a precondition; absence → `unproven` + human gate, never faked success | 0003 |
| [0006](0006-v1-core-with-forward-compatible-capture-and-human-gated-suggestions.md) | V1 core-only; forward-compatible evidence capture + human-gated tiny-PR suggestions; V1→V2 is additive enable | 0003 |
| [0007](0007-budget-enforcement-split-state-derived-vs-external-wall.md) | Budgets: state-derived enforced at tick, continuous enforced by external runner wall | 0001, 0003 |
| [0008](0008-work-claim-atomicity-via-branch-ref-push.md) | Work Claim atomicity via atomic branch-ref push; labels advisory; state-derived stale reclaim | 0001, 0002, 0007 |
| [0009](0009-github-only-v1-behind-a-named-prose-adapter-seam.md) | GitHub-only V1 behind a named prose adapter seam (9 host ops); V2 multi-host is additive | 0006 |
| [0010](0010-same-model-review-is-adversarial-and-proof-anchored.md) | Same-model review is adversarial + proof-anchored; opt-in cross-model; no-proof+same-model never auto-converges (tightens 0005) | 0005 |

## The V1 system in one paragraph

A scheduler (cron / `/loop` / CI) re-invokes the skill in **tick mode**, each tick wrapped in an external resource wall (0007). A tick carries no memory (0001): it reconstructs everything from labels + SHA-stamped marker comments (0002) via a named GitHub adapter (0009). The **Implementer** claims a trust-vetted (0004) `ready` issue by atomically pushing `loop/impl/issue-<id>` (0008), implements, runs the repo's discovered proof command (0005), and opens a PR. The **Reviewer** — adversarial and proof-anchored (0010) — reviews the current head SHA; proof-fail or defects → `needs-fix`. The **Fixer** addresses feedback and re-pushes. Reviewer flips `ready-for-human` as soon as proof passes and the head is clean — a clean first pass converges immediately, no fix cycle forced (0003); fix cycles happen only on real defects and are bounded by the cap; blocking-at-cap → `did-not-converge`, no-proof → `unproven`, repeated-timeout → `stalled`. Loops append structured evidence in the V2 schema; at a small threshold the Reviewer opens a tiny PR proposing a playbook addition (0006) — the only "evolution" in V1, fully human-gated. Turning on the V2 Maintainer Loop is a later additive enable, not a re-setup.

## Out of scope for V1 (deferred to V2, designs preserved)

Maintainer Loop, evidence consolidation into the durable ledger, Core Memory regeneration, autonomous playbook mutation, `loopctl` helper, multi-host adapters. The CONTEXT.md glossary and the original PLAN.md describe the V2 target; V1 is an honest, forward-compatible subset.
