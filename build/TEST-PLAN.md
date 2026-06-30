# TEST PLAN — Validating `autonomous-work-loops` on a live repo


**Scheduler update 2026-06-29:** V1 should arm Codex Automations, Claude `/loop`, or a local foreground supervisor. Manual guarded Codex ticks are the debugging path, not the product happy path. The widened gate has cron-equivalent cadence evidence, not actual system-cron install/uninstall evidence. Real crontab support is outside V1 and must prove install, update, uninstall, environment, logging, overlap, timeout, and cleanup behavior before docs claim cron support. GitHub Actions scheduling is also outside V1 and should be treated as a hosted CI/bot product surface.

**Gate smoke update 2026-06-28:** `build/GATE-RESULTS.md` records NO-GO for public release. Author-only strict rejection now passes in T2/T3/T4; failed-proof routing passed in T6; T5 allowlisted dispatch passes with issue `#9` and PR `#10`; and the guarded Codex runner passes with issue `#11` and PR `#12`. The widened guarded-runner pass also covers T7 no-proof routing, T8 ready-for-human honesty, T10 idempotency, T11 duplicate-claim race behavior, and T12 stale-claim recovery. The next validation step is cost wall kill proof, cycle-cap escalation, native/local runner cadence, and planted-defect model-comparison runs without reopening T2/T3/T4/T5 unless strict-trust semantics change.

**Status update 2026-06-26:** the baseline live GitHub acceptance run has now passed on `ttl-cache-loop-test`; see `TEST-RESULTS.md`. This file remains the validation plan for remaining variants and release hardening.

The acceptance test: **one `ready` issue → a converged, proven, mergeable PR, with no human in the loop.** This plan runs that on a real GitHub repo, with the loops driven by **Codex** (unlimited usage), and defines exactly how we judge pass/fail and which setup works best.

## Decisions locked (from grilling)

- **Test repo**: new **private** repo `diff-tool-loop-test` under `Mohamad-Kamar`, seeded from `mac-diff-tool` (`katooling/diff-tool` code). Isolated blast radius, real host.
- **Cadence**: Codex Automations, Claude `/loop`, or local foreground supervisor are the V1 runner surfaces. Cron-equivalent cadence can validate the runner/state machine without mutating a user's crontab. Actual system cron is excluded from V1.
- **Work**: 2–3 small real diff-tool features as issues (drafted below, pending your approval).
- **Loop engine**: **Codex CLI**. One tick = one `codex exec` invocation whose prompt says *"load the autonomous-work-loops skill and run a `<role>` tick in this repo."* (Verified: codex reads the skill and selects the correct references headlessly.)

## Pre-flight fixes (landed before the baseline test)

These are real gaps found while probing, not optional polish:

1. **Runner invocation model was wrong and is now fixed.** Templates originally assumed `codex --skill X --role Y` flags that do not exist. The real form is `codex exec -s workspace-write -c approval_policy='"never"'` with a *prompt*. The `codex.sh.tmpl` runner and related docs now use prompt-based invocation.
2. **No `timeout` binary on macOS.** The ADR-0007 external wall (`timeout 30m …`) will fail. Fix: use `gtimeout` (coreutils) if present, else a background-PID + `sleep N && kill` fallback baked into the runner. The wall is non-negotiable (cost control), so the runner must provide it portably.
3. **`codex exec` refuses outside a trusted/git dir.** Ticks run inside the repo (fine), but the runner must `cd` into the repo and may need `--skip-git-repo-check` for worktrees.

## Phases

### Current gate — widen after manual T5 PASS
Start from commit `87ff8c3` or a descendant that preserves its author-only strict trust semantics. T2/T3/T4/T5 do not need another retest unless those semantics change. T5 passed on a Git-capable manual loop surface, and the guarded Codex runner passed by moving Git/GitHub mutation outside nested Codex.

The accepted T5 outcome is: trusted issue author -> implementer claim -> one `loop/impl/issue-<n>` branch -> one PR -> proof marker -> reviewer marks `ready-for-human`. If the same scenario fails before claim because Git mutation is blocked, classify it as transport/environment and switch runner surfaces rather than reopening the trust design.

### Phase 1 — Repo + issue setup (Codex-executed)
Duplicate code into the new private repo, push, create the 4 workflow labels (`ready`, `in-progress`, `needs-fix`, `ready-for-human`) plus the 3 terminal labels (`unproven`, `did-not-converge`, `stalled`), seed the approved issues (unlabeled at first), confirm `npm ci` + `npm run test:e2e` pass on a clean checkout (establishes the proof baseline).

### Phase 2 — Bootstrap (skill, Claude-driven or Codex-driven)
Run the skill in bootstrap mode in the test repo. Expect: `.agent-loops/` rendered with `host: github`, discovered `proof.test: npm run test:e2e`, `trust_posture: permissive` (private repo), `trusted_actors: [Mohamad-Kamar]`, and a Bootstrap Report. **Eval checkpoint B1**: does discovery correctly find the Playwright proof command and the right trust posture unprompted?

### Phase 2a — Manual smoke tick per role
Label one issue `ready`. Run implementer tick manually, inspect host state, then reviewer, then fixer. **Eval checkpoint S1–S3** (see matrix). Cheap proof the mechanics work before arming a recurring runner surface.

### Phase 3 — Scheduler cadence validation
For V1, validate at least one V1 runner surface: Codex Automations, Claude `/loop`, or local foreground supervisor. The cron-equivalent scripted cadence is acceptable only as a guardrail for the runner/state machine, not as the user-facing scheduler claim. Capture the full label/marker timeline and prove later intervals no-op cleanly.

Do not install real system cron in this phase. Do not add GitHub Actions schedule as the V1 default. Real cron and hosted CI/bot orchestration are separate product surfaces.

### Phase 4 — Evaluate + pick best setup
Score against the acceptance criteria and the eval matrix; write findings.

## Acceptance criteria (the pass/fail bar)

A run **PASSES** if, for at least one issue, the observed host-state timeline is:

```
ready → in-progress → (PR opened, proof ran) → ready-for-human
```

with ALL of these invariants holding (each is grep-checkable from issue/PR markers):

| # | Invariant | ADR |
|---|-----------|-----|
| A1 | Implementer only claimed a trusted `ready` issue | 0004 |
| A2 | Exactly one branch `loop/impl/issue-<id>` per issue; no duplicate PRs | 0008 |
| A3 | Every PR head that reached a verdict had proof run (marker shows proof result) | 0005 |
| A4 | Clean proven first pass may converge immediately; review→fix cycles happen only when blocking defects are found, and never exceed the cap | 0003 |
| A5 | A tick re-invoked on an unchanged head SHA was a no-op (idempotent) | 0001/0002 |
| A6 | `ready-for-human` label appears ONLY on proven+converged PRs; `unproven`/`did-not-converge` use their own labels | 0005/0010 |
| A7 | No tick exceeded the runtime wall (`timeout`/`gtimeout` or host wall enforced) | 0007 |
| A8 | Markers are versioned (`v=1`) and parseable | 0002 |
| A9 | Every nested Implementer/Reviewer/Fixer prompt starts from repo root with bounded context: `.agent-loops/config.yaml`, `.agent-loops/context.md`, issue/PR state, proof logs, diffs, and relevant repo docs only; persisted `*-prompt.log` snapshots prove the delivered context | context contract |

A run **FAILS** (and we learn from it) if: duplicate work appears (A2), a PR converges without proof (A3/A6), a reviewer misses a planted blocking defect, it loops past the cycle cap instead of escalating (0003), a tick re-does work on an unchanged head (A5), or nested agents act without the context contract (A9).

## V1 runner-surface validation

Run these before claiming V1 product GO:

| Surface | Required proof |
|---|---|
| Codex Automations | Fresh bootstrap suggests or creates implementer/reviewer/fixer automations; one `ready` issue reaches `ready-for-human` or a human-gated terminal label; later automation intervals no-op; no duplicate branch, PR, or marker. |
| Claude `/loop` | Fresh bootstrap emits one loop prompt per role; loops process one `ready` issue to terminal state; re-review on unchanged head no-ops; stopping the loops leaves no hidden scheduler state. |
| Local foreground supervisor | `bash -n` passes; foreground run cycles roles without manual ticks; one `ready` issue reaches terminal state; `Ctrl-C` stops it; restart no-ops on already-terminal work. |

At least one product-native surface must pass for a limited V1 GO. All three should pass before broad public launch.

## Context validation

Before rerunning GO validation, confirm bootstrap renders `.agent-loops/context.md` and that guarded runner logs include role prompts with:

- repository root and runner working directory
- `.agent-loops/context.md` content, capped to the first 220 lines
- root instruction files present, such as `AGENTS.md`, `CLAUDE.md`, `README.md`, `CONTRIBUTING.md`, and `.github/copilot-instructions.md`
- explicit guidance to use targeted reads/`rg`, not broad directory dumps
- explicit prohibition on editing `.agent-loops/` unless the issue requires it

## Eval matrix — which setup works best

Run the happy-path issue under these variations and compare convergence quality + cost:

| Axis | Variant A | Variant B | What we learn |
|------|-----------|-----------|---------------|
| Review model | same model (reviewer_model empty) | cross-model (`reviewer_model` = a different codex/Claude model) | Does cross-model review catch defects same-model rubber-stamps? (ADR-0010) |
| Cadence | V1 runner surface | cron-equivalent scripted cadence | Does the repeated guarded command shape hold up without hand-driven ticks? |
| Proof present | proof configured | proof blanked (force `unproven`) | Confirms no-proof never auto-converges (ADR-0005 amendment) |
| Trust posture | permissive (private) | strict author-only dispatch (reject non-allowlisted author; accept allowlisted dispatch issue) | Confirms trust gate blocks untrusted intake without becoming deny-all (ADR-0004) |

Additional release-hardening rows: failed proof routes to `needs-fix`; duplicate claim race creates one branch/PR; stale claim recovers or escalates to `stalled`; browser proof runs on a compatible non-sandboxed execution surface; actual system cron install/uninstall is validated before any cron support claim.

Sequencing constraint: this matrix starts after the guarded-runner PASS. The remaining release blockers are cost-wall kill proof, cycle-cap escalation, V1 runner cadence, and planted-defect model comparison, not the strict trust or claim transport path. Actual system cron and GitHub Actions schedule are outside this V1 guarded-runner release gate.

Scoring per run: (1) did it converge? (2) cycles to converge, (3) wall-clock + codex tokens, (4) defects the reviewer caught vs. defects that slipped to `ready-for-human` (we plant one subtle bug to measure this), (5) any invariant violation.

**"Best setup" verdict** = the cheapest variant that converges with zero invariant violations and catches the planted defect. Hypothesis: cross-model review catches more, same-model + proof is cheaper and good enough when proof coverage is real.

## Candidate test issues (PENDING YOUR APPROVAL)

All are small, real, and Playwright-provable:

1. **`feat: add a "Swap sides" button`** — a button that swaps the original/changed text panes and re-runs the diff. Small, self-contained, testable (assert panes swap). Good happy-path convergence case.
2. **`feat: add a copy-to-clipboard button for the diff summary`** — copies the change-count summary line. Tiny DOM + clipboard; Playwright can assert clipboard or button state.
3. **`fix: Cmd+Enter does not trigger diff when focus is in the changed-text box`** (planted-bug candidate) — a bugfix-style issue; lets us measure whether the reviewer verifies the fix against a test rather than trusting the PR body. This is also where we *plant a subtle defect* in the fix to test review rigor.

If you approve, Phase 1 seeds #1 and #3 (one feature + one bugfix = exercises review/fix well); #2 is held as the cross-model comparison case.

## Definition of done for the whole test

- At least one issue converged to `ready-for-human` with all A1–A9 holding, evidenced by the captured timeline.
- The eval matrix is filled with real numbers and a "best setup" recommendation.
- Any invariant failures are documented with root cause (skill bug vs. codex behavior vs. environment).
- DX walkthrough written from the actual observed experience.
