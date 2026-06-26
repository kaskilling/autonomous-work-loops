# Evaluation of Codex Build Output

Reviewer: Claude (post-build audit against the 10 ADRs + write-a-skill standards).

## Verdict: PASS, with one real bug found and fixed.

Codex produced a complete, high-fidelity skill: 20 files, SKILL.md a tight 40-line router, all 10 ADRs cited, adapter isolation perfectly clean (zero `gh`/`git` calls leaked outside `adapter-github.md` — verified independently by grep, not just trusting the self-report).

## What was excellent

- **SKILL.md** is a genuine router with mode dispatch and hard-rules that restate the load-bearing ADRs. Under the 100-line limit.
- **Description** has a proper "Use when" clause with concrete triggers; Codex `short-description` included for cross-tool.
- **Adapter seam** (ADR-0009) is real: 8 named operations, each with a concrete recipe, and every playbook calls them by name.
- **Convergence** (ADR-0003/0005/0010), **claiming** (ADR-0008 branch-ref atomicity + state-derived stale reclaim), **budget split** (ADR-0007), **trust-gated intake** (ADR-0004), and **forward-compatible evidence + tiny-PR suggestion** (ADR-0006) are all rendered faithfully.
- **config.yaml** carries every V1 key plus the dormant `# v2` keys — the additive-enable path is preserved.
- **Honest self-report**: flagged that it could not `git commit` (sandbox blocked `.git` writes) rather than claiming success.

## Bug found and fixed (ADR-0010 invariant violation)

The reviewer and implementer playbooks routed the `unproven` and `did-not-converge` outcomes to the **`ready-for-human` label + a buried comment flag**, even though config.yaml defined dedicated `unproven` and `did-not-converge` labels.

This broke the core ADR-0010 amendment invariant: *"a PR reaching the human as `ready-for-human` without an `unproven` flag is a guarantee proof ran."* If unproven/non-converged PRs also wear `ready-for-human`, the label stops meaning "proven and converged," the board is no longer filterable by label, and a human must parse comment flags to tell outcomes apart.

**Fix applied** to `loop-reviewer.md` (2 lines), `loop-implementer.md` (1 line), and `state-model.md` (clarified these are dedicated terminal labels never co-applied with `ready-for-human`). Re-verified by grep: no remaining instances.

## Minor notes (left as-is, acceptable)

- `claim_work` uses an empty claim commit to force the branch ref to exist — a reasonable concrete realization of ADR-0008's "atomic branch-ref push." Acceptable.
- Adapter recipes are prose templates for an executing agent, not a hardened shell library — matches the not-a-runtime-framework thesis (ADR-0009). Acceptable and intended.

## Confidence

The skill is internally consistent and faithful to every ADR. It has **not** been executed end-to-end against a live GitHub repo — that is the v1 success criterion (one `ready` issue → converged, proven, mergeable PR) and the recommended next validation step before public release.
