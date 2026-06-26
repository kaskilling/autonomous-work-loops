# Developer Experience — what using autonomous-work-loops actually feels like

Written from the real first live run (`ttl-cache-loop-test`, Codex-driven). This is the end-to-end DX, with the exact commands and what you see at each step.

## One-time machine setup

```sh
# 1. Get the skill into all three agent dirs (.agents canonical, .claude/.codex symlink to it)
./skill/autonomous-work-loops/assets/install.sh   # or --symlink

# 2. Cost wall needs a timeout binary (macOS has none by default)
brew install coreutils    # provides gtimeout
```

That's it. No daemon, no service, nothing running in the background yet.

## Per-repo setup: one bootstrap, ~1 minute

In the target repo, invoke the skill in bootstrap mode:

```
/autonomous-work-loops          # or just: "set up autonomous work loops here"
```

What it does, unattended:
- Discovers host (GitHub), default branch, **visibility → trust posture**, collaborators → `trusted_actors`, and crucially **your proof command** (it found `pytest` / would find `npm test` / etc.).
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

You review the Bootstrap Report's **Critical Decisions** (trust posture, proof command, credential boundary) and edit `config.yaml` if needed. Then create the 7 labels (the report gives the commands).

## Operating: the daily loop

### The only thing you do
Open an issue, write what you want (clearly — the issue body *is* the implementer's brief), and apply the **`ready`** label. That's the entire human input.

### Watching it work
The whole system state is **visible in your GitHub labels** — no dashboard, no log diving. You literally watch the label move:

```
ready  →  in-progress  →  needs-fix  →  (back to in-progress)  →  ready-for-human
```

Under the hood, an external scheduler (cron) fires the runner scripts. From the real run:
- **Implementer** (within ~2 min): claimed the issue, created `loop/impl/issue-1`, wrote the feature **and its own tests**, ran proof (`9 passed`), opened a PR. Issue flips `ready → in-progress`.
- **Reviewer**: re-ran proof independently, found no defect, but **refused to rubber-stamp the first draft** — posted a precise `needs-fix` marker demanding one hardening cycle. PR → `needs-fix`.
- **Fixer**: ran the hardening pass, confirmed proof, posted a `fixed` marker. PR → `in-progress`.
- **Reviewer** again: clean head + proof passed + one fix cycle exists → **`ready-for-human`**.

Every step leaves a machine-readable marker comment on the PR (`<!-- loop:reviewer v=1 reviewed_sha=... verdict=... -->`) so the next tick — and you — can see exactly what happened and why.

### Arming the loop (cron)
The Bootstrap Report hands you cron lines like:
```cron
*/15 * * * * /path/.agent-loops/runners/implementer.sh >> /tmp/awl-impl.log 2>&1
*/10 * * * * /path/.agent-loops/runners/reviewer.sh   >> /tmp/awl-rev.log  2>&1
2-59/10 * * * * /path/.agent-loops/runners/fixer.sh    >> /tmp/awl-fix.log  2>&1
```
Each runner is one `codex exec` tick wrapped in a 30-minute `gtimeout` wall. Install them and walk away.

### Your endgame
You come back to a PR labeled `ready-for-human` that is **proven (tests ran and passed) and converged (survived a review→fix cycle)**. You read the diff, you merge. If something couldn't converge, you instead see `did-not-converge`, `unproven`, or `stalled` — distinct labels that tell you precisely why it needs you, rather than a false "ready."

## What surprised me (honest notes)

- **It writes its own tests.** Given an issue that said "prove it with pytest," the implementer authored 3 new tests, not just the feature.
- **The anti-rubber-stamp rule is the star.** Watching the reviewer find nothing wrong yet *still* refuse to converge on pass 1 is the whole value proposition made visible.
- **It's resilient to environment friction.** When codex's sandbox blocked `.git` writes, the agent self-healed by working from a temp clone and logged it as evidence — no human intervention.
- **Codex sandbox + browser tests don't mix** on a policy-locked machine. If your proof is Playwright/Chromium, run the loop via Claude or in CI, not codex-in-sandbox. Unit/build proofs are perfect for codex.

## The mental model

You are not a coder in this loop. You are a **product owner who writes issues and a reviewer who merges**. The label board is your control panel. The loops are interns who never get tired, always run the tests, and won't hand you work until it survived a critic.
