# Ecosystem & Hosting Analysis

How `autonomous-work-loops` is used, where it lives, and how it is distributed.

## 1. What the skill *is* in the ecosystem

Per ADR-0001, this is **not a hosted bot and not an app-native infinite slash command**. It is a skill with two runtime surfaces:

- **Setup and Arm mode** — invoked once per repo (`/autonomous-work-loops` or "set up work loops here"). Discovers the repo, renders `.agent-loops/`, creates labels, proves a smoke issue, and starts the managed local supervisor.
- **Tick mode** — invoked by the managed local supervisor or a manual guarded tick, one role per invocation (`implementer` | `reviewer` | `fixer`). One tick = claim one item, do one unit of work, exit. Stateless between ticks.

The skill never loops by itself. The *loop* is the generated local supervisor re-invoking tick mode. This is the single most important ecosystem fact: **we ship the brain (the skill) and a managed local heartbeat with status/stop controls, not a hosted service or unmanaged daemon.**

## 2. Prior art and differentiation

The official `claude-plugins-official` marketplace already ships **`ralph-loop`**: a same-session loop that feeds *the same prompt* back to one agent until a completion promise is true. It is single-role, single-prompt, in-session, and has no host-state machine.

`autonomous-work-loops` is categorically different and the marketing must lead with this:

| | ralph-loop | autonomous-work-loops |
|---|---|---|
| Roles | one | three (implementer / reviewer / fixer) |
| State | in-session memory | host state (labels + SHA markers), zero agent memory |
| Persistence | dies with session | survives via host state and managed local re-ticks; resumable |
| Convergence | completion promise | adversarial review + proof + cycle cap (ADR-0003/0010) |
| Safety | none specific | trust-gated intake, proof precondition, human gates, budget walls |
| Multi-machine | no | claim atomicity via branch-ref push (ADR-0008) |

Positioning: *"ralph-loop makes one agent retry. autonomous-work-loops runs a reviewed, converging PR workflow with visible state and human merge gates."*

## 3. Where the skill physically lives

The same skill folder can be installed into common agent skill locations:

- `~/.agents/skills/<skill>`
- `~/.claude/skills/<skill>`
- `~/.codex/skills/<skill>`

`install.sh` copies the skill into those locations by default and supports
`--symlink` for development checkouts. The skill must be **tool-agnostic in its
content** (it already is per ADR-0001 model-agnosticism); the body must not
assume "you are Claude" — it speaks in roles and host operations.

Frontmatter compatibility: both Claude and Codex read `name` + `description`. Codex additionally supports `metadata.short-description` and an `agents/openai.yaml`. We include the Codex extras (ignored harmlessly by Claude) so one folder serves all three.

## 4. Distribution options (ranked)

### Option A — Plugin in a marketplace (recommended for public release)
Package as a Claude Code plugin: a git repo with `.claude-plugin/marketplace.json` (or listed in an existing marketplace via `git-subdir` source + pinned `sha`). Users run `/plugin marketplace add <url>` then install. This is how every skill in `claude-plugins-official` ships.
- **Pro**: one-command install, versioned, pinned SHA, discoverable, auto-updates.
- **Pro**: a plugin can bundle a slash command (bootstrap entry) *and* the skill.
- **Con**: Claude-Code-centric packaging; Codex/`.agents` need the raw folder.

### Option B — Plain git repo of the skill folder (recommended for cross-tool)
A repo whose root *is* the skill folder. Install = clone into each tool's skills dir (or symlink one clone into all three). Ship an `install.sh` that copies/symlinks into `~/.claude/skills`, `~/.codex/skills`, `~/.agents/skills`.
- **Pro**: works identically for Claude, Codex, and `.agents`.
- **Pro**: trivial to fork/audit — important given the autonomy/security surface.
- **Con**: no auto-update; manual `git pull`.

### Option C — Both (recommended overall)
Single source-of-truth git repo (Option B layout) that is *also* registered as a plugin (Option A) via a thin `.claude-plugin/` wrapper. Cross-tool users clone; Claude users one-click. This is the publish target.

### Rejected — npm / curl-pipe-bash installer
Too much machinery for a folder of markdown; the security-conscious audience (running autonomous agents with credentials) should *read the repo before installing*, which favors plain git.

## 5. Runner / heartbeat hosting (the part users actually operate)

The skill emits runner artifacts; it does not host a service. Per ADR-0007 the runner is also the budget wall. Bootstrap should offer one V1 execution surface:

1. **Managed local supervisor** — setup starts one local process with `.agent-loops/supervisor.pid`, logs, `--status`, and `--stop`; it cycles guarded implementer/reviewer/fixer ticks until stopped.

Manual guarded ticks remain the debugging surface, not the product happy path. Codex Automations and Claude `/loop` are excluded from V1 so every harness app follows the same setup path. Local system cron is excluded from V1 because it needs owned install/update/uninstall and cleanup semantics. GitHub Actions scheduling is also excluded from V1; a hosted CI or bot runner has enough credential, billing, and operational surface to be a separate project unless a later design explicitly adopts it.

The skill ships this as **templates in `assets/runners/`**, rendered with the repo's discovered values during bootstrap.

Headless agents load the skill by prompt, not by phantom `--skill`/`--role` flags. The rendered supervisor should invoke a guarded role runner, and that runner should invoke the agent command with a bounded context prompt and wrap that invocation in the external wall.

## 6. Credentials & blast radius (ecosystem-level reminder)

Because tick mode runs unattended with whatever credentials the runner has:
- Local runner → the user's own `gh`/git creds. Fine for solo/private.
- Hosted CI/bot runner → must use a scoped bot token; this is a separate product surface, not a V1 default.
- The trust-gated intake (ADR-0004) and human gates are what make it safe to point a credentialed runner at a public repo.

## 7. Summary decision

- **Package**: single git repo, skill-folder-at-root layout (Option B), with a `.claude-plugin/` wrapper for marketplace install (Option C overall).
- **Install**: `install.sh` symlinks one clone into all three skill dirs; `/plugin` for Claude users.
- **Heartbeat**: V1 starts one managed local supervisor. Manual guarded ticks are retained for debugging.
- **Lead marketing message**: multi-agent converging PR factory vs. ralph-loop's single-agent retry.
