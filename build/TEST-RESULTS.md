# TEST RESULTS — autonomous-work-loops, first live acceptance run

Date: 2026-06-26 · Loop engine: **Codex CLI** (`codex exec`) · Repo: `Mohamad-Kamar/ttl-cache-loop-test` (private)

## Headline: PASS ✅

The acceptance test the skill had never passed now passes on a live GitHub repo, driven entirely by Codex. Issue #1 (`feat: add size() to TTLCache`) traversed the full lifecycle with no human in the loop:

```
ready → in-progress → PR#3 (proof: 9 passed)
      → reviewer: needs-fix (cycle 1, mandatory hardening)
      → fixer: fixed (cycle 1, proof 9 passed)
      → in-progress
      → reviewer: ready-for-human (proof 9 passed, clean head, 1 fix cycle)
```

## Acceptance invariants (independently grep-audited, not trusting markers)

| # | Invariant | Result |
|---|-----------|--------|
| A1 | Implementer claimed only the trusted `ready` issue | ✅ only #1 (labeled ready) acted on; #2 untouched |
| A2 | Exactly one `loop/impl/issue-1` branch; no duplicate PRs | ✅ 1 branch, 1 PR |
| A3 | Every verdict-bearing head had proof run | ✅ all 3 markers show `9 passed` |
| A4 | ≥1 real review→fix cycle before `ready-for-human` | ✅ 1 fixer `verdict=fixed` marker |
| A5 | Re-tick on unchanged head = no-op (idempotent) | ✅ re-ran reviewer on converged head: 0 new comments, no label change |
| A6 | `ready-for-human` only on proven+converged; terminal labels distinct | ✅ PR carries only `ready-for-human`; no `unproven`/`did-not-converge` |
| A7 | No tick exceeded the runtime wall | ✅ all ticks completed well under 30m `gtimeout` |
| A8 | Markers versioned `v=1`, parseable | ✅ all 4 markers `v=1` with reviewed_sha/verdict/cycle/ts |

## What this proves about the DESIGN

- **The mandatory hardening cycle fired exactly as designed — and that exposed it as ceremony.** The reviewer found no defect on a clean PR yet still refused to converge on first pass, the fixer ran and changed nothing, then the reviewer approved byte-identical code. **This observation led us to DROP the mandatory-cycle rule** (ADR-0003 amended 2026-06-26): a clean proven pass now converges immediately. Rigor is carried by proof-as-precondition (ADR-0005) and the adversarial/cross-model reviewer (ADR-0010), not by forced motion. The timeline below reflects the *old* behavior at test time.
- **Proof-as-precondition (ADR-0005) held.** Every state transition re-ran pytest; convergence never happened without a green proof.
- **Zero-memory ticks (ADR-0001) + SHA markers (ADR-0002) work.** Each tick reconstructed state purely from host labels + markers; the idempotency no-op confirms no hidden memory.
- **Atomic claim (ADR-0008) held.** One branch, one PR, no duplication.
- **Evidence capture (ADR-0006) worked unprompted.** Loops wrote structured `evidence.v2` notes for environment blockers.

## Environment findings (codex sandbox constraints — NOT skill bugs)

These are properties of running ticks inside codex's managed sandbox on this machine, and they shaped the runner design:

1. **Network**: `workspace-write` blocks DNS by default → runner must set `-c sandbox_workspace_write.network_access=true`. **Fixed in runner template.**
2. **No `timeout` binary on macOS** → installed coreutils (`gtimeout`); runner prefers timeout→gtimeout→shell-fallback. **Fixed.**
3. **`.git` writes blocked** in the repo's own `.git` → codex worked around it by doing git ops from a writable temp clone/archive. Self-healed by the agent; worth noting for DX.
4. **`danger-full-access` forbidden headlessly by managed enterprise policy** → **browser-based proof (Playwright/Chromium) cannot run inside a codex tick on this machine.** This is why the test target was swapped from `diff-tool` (Playwright) to `ttl-cache` (pytest). Pure unit/build proofs work; browser e2e proofs need a different execution surface (Claude-as-runner, or CI).
5. **Transient `/tmp` policy block**: the fixer's first run was blocked mid-workaround "by policy" and posted no marker (loop would have stalled). A **single re-tick succeeded** — but this is a real robustness note: a tick that dies mid-workaround leaves no marker, and only the stale-claim/re-trigger path recovers it. Acceptable for cron (next tick retries) but worth hardening.

## Eval matrix status

Only the **baseline variant** (same-model review, pytest proof, permissive trust, manual-sequential ticks) was run to convergence — and it passed cleanly. The other matrix axes (cross-model review, forced `unproven`, strict-trust rejection, true unattended cron) are **not yet run**. The baseline is sufficient to declare the core system *works*; the remaining variants are quality/coverage comparisons, not pass/fail gates.

## Best-setup verdict (provisional)

For repos with **non-browser proof**, **Codex + same-model + pytest/unit proof** converges cleanly and cheaply — recommended default. For **browser-proof repos**, do not use codex-in-sandbox as the loop engine on a policy-restricted machine; use Claude-as-runner or move proof to CI. Cross-model review remains the recommended quality upgrade but was not needed to pass.
