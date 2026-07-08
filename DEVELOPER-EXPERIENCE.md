# Developer Experience — what using autonomous-work-loops actually feels like

Written from the real first live run (`ttl-cache-loop-test`, Codex-driven). This is the end-to-end DX, with the exact commands and what you see at each step.

## One-time machine setup

```sh
# 1. Install local prerequisites
brew install gh coreutils
gh auth login
gh auth status

# 2. Install into all three agent skill dirs
./skills/autonomous-work-loops/assets/install.sh   # or --symlink
```

`gh` is the GitHub host adapter. `coreutils` provides `gtimeout` on macOS for the external cost wall. Setup starts no hosted service, cron, launchd job, or CI bot.

The installer backs up existing skill installs by default. Use `--force` only
when replacing them without a backup is intentional.

## Per-repo setup: one bootstrap, ~1 minute

In the target repo, invoke the skill:

```
/autonomous-work-loops
```

The normal path runs guided setup and arms the managed background supervisor.
The CLI equivalent is:

```sh
/path/to/autonomous-work-loops/skills/autonomous-work-loops/assets/bootstrap.sh --arm "$PWD"
```

Run deterministic manual bootstrap only when you do not want GitHub mutation or a
supervisor tick:

```sh
/path/to/autonomous-work-loops/skills/autonomous-work-loops/assets/bootstrap.sh "$PWD"
```

What it does, unattended:
- Discovers host (GitHub), default branch, authenticated `gh` login, and crucially **your proof command** (it found `pytest` / would find `npm test` / etc.). Deterministic bootstrap keeps `trust_posture: strict` as the conservative default.
- Renders `.agent-loops/` into your repo: `config.yaml`, `context.md`, `setup-labels.sh`, `doctor.sh`, a first-trial issue template, three playbooks, an evidence inbox, the managed local supervisor, and guarded local role engines for Codex or Claude.
- Writes a **Bootstrap Report** stating exactly what it detected and what's left for you to decide.

What you see afterward (`.agent-loops/`):
```
config.yaml                     # the durable contract: proof cmd, trust, labels, budgets
context.md                      # small repo context every tick reads before acting
setup-labels.sh                 # idempotent required-label setup helper
doctor.sh                       # non-mutating setup preflight
FIRST-TRIAL-ISSUE.md            # safe smoke-test issue body
playbooks/{implementer,reviewer,fixer}.md
runners/local-supervisor.sh     # the only V1 runner surface
runners/{codex,claude}.sh       # guarded local role engines behind the supervisor
runners/guarded-role-runner-common.sh
evidence/inbox/
BOOTSTRAP-REPORT.md
```

You review the Bootstrap Report's **Critical Decisions** (trust posture, trusted actors, proof command, credential boundary) and edit `config.yaml` if needed. In strict mode, bootstrap should add the authenticated maintainer/operator to `trusted_actors` when it can prove the login with `gh api user`; it should not add every collaborator. Guided setup creates or refreshes the labels and runs the preflight for you. In manual setup, run:

```sh
.agent-loops/setup-labels.sh
.agent-loops/doctor.sh
```

## Operating: the daily loop

### The only thing you do
Open an issue, write what you want (clearly — the issue body *is* the implementer's brief), and apply the **`ready`** label. In strict mode, the issue must be authored by someone in `trusted_actors`; if the idea came from an external issue, create a trusted-authored dispatch issue that summarizes the accepted work and links the source.

For V1, bootstrap gives everyone the same product path: one managed local supervisor, controlled by the generated script.

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

### Runner surface
The shippable V1 path has one runner surface: the local supervisor. Normal setup starts managed background watch:

```sh
.agent-loops/runners/local-supervisor.sh --status "$PWD"
.agent-loops/runners/local-supervisor.sh --stop "$PWD"
```

For a visible one-shot tick:

```sh
.agent-loops/runners/local-supervisor.sh --once "$PWD"
```

The supervisor auto-detects `.agent-loops/runners/codex.sh` when Codex CLI is available, otherwise `.agent-loops/runners/claude.sh` when Claude Code is available. Set `AWL_ROLE_RUNNER` when you want an explicit guarded role engine:

```sh
AWL_ROLE_RUNNER="$PWD/.agent-loops/runners/claude.sh" .agent-loops/runners/local-supervisor.sh "$PWD"
```

Manual guarded ticks are debugging and validation paths. Codex Automations, Claude `/loop`, actual system cron, launchd, and GitHub Actions schedules are out of V1.

The honest V1 promise is: invoke the skill from the repo, let it set up and arm the local supervisor, label trusted work `ready`, and get a proven PR or a clear human-gated terminal state.

### Your endgame
You come back to a PR labeled `ready-for-human` that is **proven (tests ran and passed) and converged (survived adversarial review; review→fix cycles ran only if real defects were found)**. You read the diff, you merge. If something couldn't converge, you instead see `did-not-converge`, `unproven`, or `stalled` — distinct labels that tell you precisely why it needs you, rather than a false "ready."

## What surprised me (honest notes)

- **It writes its own tests.** Given an issue that said "prove it with pytest," the implementer authored 3 new tests, not just the feature.
- **Proof is the real gate, not ceremony.** The first build had the reviewer force a fix cycle even on a clean PR; watching the fixer change nothing taught us that forced motion ≠ rigor. The honest value is: the tests actually ran and passed, and an adversarial (ideally cross-model) reviewer read the diff — convergence is earned by proof, not by counting rounds.
- **It's resilient to environment friction.** When codex's sandbox blocked `.git` writes, the agent self-healed by working from a temp clone and logged it as evidence — no human intervention.
- **Codex sandbox + browser tests don't mix** on a policy-locked machine. If your proof is Playwright/Chromium, use a compatible guarded role engine or a non-sandboxed future surface. Unit/build proofs are perfect for codex.

## The mental model

You are not a coder in this loop. You are a **product owner who writes issues and a reviewer who merges**. The label board is your control panel. The loops are interns who never get tired, always run the tests, and won't hand you work until it survived a critic.
