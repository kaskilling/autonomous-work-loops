# Developer Experience — what using autonomous-work-loops actually feels like

Written from the real first live run (`ttl-cache-loop-test`, Codex-driven). This is the end-to-end DX, with the exact commands and what you see at each step.

## One-time machine setup

```sh
# 1. Install local prerequisites
brew install gh coreutils
gh auth login
gh auth status

# 2. Get the skill into all three agent dirs (.agents canonical, .claude/.codex symlink to it)
./skill/autonomous-work-loops/assets/install.sh   # or --symlink
```

`gh` is the GitHub host adapter. `coreutils` provides `gtimeout` on macOS for the external cost wall. No daemon, no service, nothing running in the background yet.

## Per-repo setup: one bootstrap, ~1 minute

In the target repo, invoke the skill in bootstrap mode:

```
/autonomous-work-loops          # or just: "set up autonomous work loops here"
```

What it does, unattended:
- Discovers host (GitHub), default branch, authenticated `gh` login, **visibility → trust posture**, explicit loop dispatchers → `trusted_actors`, and crucially **your proof command** (it found `pytest` / would find `npm test` / etc.).
- Renders `.agent-loops/` into your repo: `config.yaml`, three playbooks, an evidence inbox, and **ready-to-run Codex runner scripts** for each role.
- Writes a **Bootstrap Report** stating exactly what it detected and what's left for you to decide.

What you see afterward (`.agent-loops/`):
```
config.yaml                     # the durable contract: proof cmd, trust, labels, budgets
playbooks/{implementer,reviewer,fixer}.md
runners/{implementer,reviewer,fixer}.sh   # each wraps `codex exec` in a gtimeout wall
evidence/inbox/
BOOTSTRAP-REPORT.md
```

You review the Bootstrap Report's **Critical Decisions** (trust posture, trusted actors, proof command, credential boundary) and edit `config.yaml` if needed. In strict mode, bootstrap should add the authenticated maintainer/operator to `trusted_actors` when it can prove the login with `gh api user`; it should not add every collaborator. Then create the 7 labels with the `gh label create --force` commands from the report.

## Operating: the daily loop

### The only thing you do
Open an issue, write what you want (clearly — the issue body *is* the implementer's brief), and apply the **`ready`** label. In strict mode, the issue must be authored by someone in `trusted_actors`; if the idea came from an external issue, create a trusted-authored dispatch issue that summarizes the accepted work and links the source.

For V1, bootstrap should help you arm one runner surface. The skill does not install cron jobs or create GitHub Actions workflows. It should choose the product-native path when it can:

- Codex user: Codex Automations.
- Claude user: Claude `/loop`.
- Unknown or generic local user: local foreground supervisor.

Manual guarded tick commands still exist for troubleshooting, but they are not the happy path.

### Watching it work
The whole system state is **visible in your GitHub labels** — no dashboard, no log diving. You literally watch the label move:

```
clean path:  ready → in-progress → ready-for-human
fix path:    ready → in-progress → needs-fix → in-progress → ready-for-human
```

Under the hood, each tick reconstructs state from GitHub labels and marker comments. From the real run:
- **Implementer** (within ~2 min): claimed the issue, created `loop/impl/issue-1`, wrote the feature **and its own tests**, ran proof (`9 passed`), opened a PR. Issue flips `ready → in-progress`.
- **Reviewer**: re-ran proof independently and inspected the diff against the issue's acceptance criteria. If it finds a blocking defect → `needs-fix`; if the head is clean and proof passed → straight to `ready-for-human`.
- **Fixer** (only when there was a `needs-fix`): addresses the feedback, re-runs proof, returns the PR for re-review.

> Note: the very first test run used an earlier rule that *forced* one fixer cycle even on a clean PR. We dropped that (it was ceremony — the fixer changed nothing and the reviewer then approved identical code). A clean, proven PR now converges in one implementer + one reviewer tick. A second reviewer pass happens only after a real fixer change.

Every step leaves a machine-readable marker comment on the PR (`<!-- loop:reviewer v=1 reviewed_sha=... verdict=... -->`) so the next tick — and you — can see exactly what happened and why.

### Runner surfaces
The shippable V1 path should set up one runner surface that keeps checking for work after bootstrap. It ships runner templates and validates the guarded Codex runner, but actual system-cron install/uninstall is not a V1 claim.

Current scheduler posture:
- **Codex Automations**: V1 Codex happy path. Use project/worktree automation to wake implementer, reviewer, and fixer ticks on a cadence.
- **Claude `/loop`**: V1 Claude happy path. Create one recurring loop prompt per role.
- **Local foreground supervisor**: V1 generic fallback. User starts one terminal process; it cycles implementer, reviewer, and fixer until stopped.
- **Manual guarded Codex ticks**: debugging and validation path.
- **Actual system cron**: out of V1. It needs install, update, uninstall, environment, log, overlap, and cleanup behavior before support is claimed.
- **GitHub Actions schedule**: out of V1. Treat hosted CI/bot orchestration as a separate product surface unless a later design explicitly adopts it.

The honest V1 promise is: bootstrap the repo, arm one V1 runner surface, label trusted work, and get a proven PR or a clear human-gated terminal state.

### Your endgame
You come back to a PR labeled `ready-for-human` that is **proven (tests ran and passed) and converged (survived adversarial review; review→fix cycles ran only if real defects were found)**. You read the diff, you merge. If something couldn't converge, you instead see `did-not-converge`, `unproven`, or `stalled` — distinct labels that tell you precisely why it needs you, rather than a false "ready."

## What surprised me (honest notes)

- **It writes its own tests.** Given an issue that said "prove it with pytest," the implementer authored 3 new tests, not just the feature.
- **Proof is the real gate, not ceremony.** The first build had the reviewer force a fix cycle even on a clean PR; watching the fixer change nothing taught us that forced motion ≠ rigor. The honest value is: the tests actually ran and passed, and an adversarial (ideally cross-model) reviewer read the diff — convergence is earned by proof, not by counting rounds.
- **It's resilient to environment friction.** When codex's sandbox blocked `.git` writes, the agent self-healed by working from a temp clone and logged it as evidence — no human intervention.
- **Codex sandbox + browser tests don't mix** on a policy-locked machine. If your proof is Playwright/Chromium, run the loop via Claude or in CI, not codex-in-sandbox. Unit/build proofs are perfect for codex.

## The mental model

You are not a coder in this loop. You are a **product owner who writes issues and a reviewer who merges**. The label board is your control panel. The loops are interns who never get tired, always run the tests, and won't hand you work until it survived a critic.
