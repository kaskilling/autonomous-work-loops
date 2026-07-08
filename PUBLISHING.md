# Publishing & Marketing

## Publishing status: targeted validation, not broad launch

The project is ready for private development and targeted validation installs.
It is not ready for unattended public use or a broad launch claim until other
users repeat the setup on their own repos and pinned release tags are used for
marketplace-style installs.

Preserve the current proof: the baseline v1 acceptance test passed once on a
live private GitHub repo, the author-only strict rejection retest now passes for
untrusted authors and prompt-injection issues, allowlisted dispatch acceptance
passes, and the guarded runners now claim and converge on live GitHub. No-proof
routing, ready-for-human honesty, reviewer idempotency, duplicate-claim race
behavior, stale-claim recovery, cost-wall recovery, cycle-cap escalation,
local-supervisor cadence, and planted-defect review routing also pass on guarded
fixture runs. In strict mode, executable issues must be authored by
`trusted_actors`; external work must be rewritten as a trusted-authored dispatch
issue. The V1 product path is now one managed local supervisor with status and
stop controls. Codex Automations and Claude `/loop` are removed from V1 setup.

Release-candidate proof from 2026-07-06:

1. Fresh public clone of `kaskilling/autonomous-work-loops` passed
   `build/harness/check-packaging.sh`.
2. Standard installer paths passed: the Codex GitHub skill-installer helper,
   `npx skills@latest add --list --full-depth`, and `npx skills@latest add
   --skill autonomous-work-loops --agent codex --copy`.
3. Cross-tool installer passed from a clean temp `HOME`, creating Claude, Codex,
   and `.agents` skill installs.
4. Codex plugin install passed from a clean temp `HOME` through a local
   marketplace entry and loaded as enabled.
5. Claude plugin validation and install passed from a clean temp `HOME` through
   a local marketplace entry, and `claude plugin details` showed the skill.
6. A live fresh-smoke repo, `kaskilling/awl-live-smoke-20260706`, moved issue #1
   to PR #2 with proof-passed and reviewer `ready-for-human` markers. The first
   Codex role-runner attempt hit a local Codex state/app-server permission
   blocker; the same supervisor recovered and converged with the generated
   Claude role runner.

Before broad public release, repeat the release-candidate smoke with at least
one external user and a pinned tag:

1. Create a small repo with a real test command and 1-2 `ready` issues.
2. Bootstrap and arm: `/autonomous-work-loops`.
3. Confirm the tested V1 runner surface: `.agent-loops/runners/local-supervisor.sh --status "$PWD"`.
4. Confirm: one `ready` issue -> claimed -> proven PR -> `ready-for-human`. A
   clean proven PR may converge on the first review; review->fix cycles happen
   only when defects are found.
5. Confirm later intervals no-op cleanly and create no duplicate branch, PR, or
   review marker.

The guarded-runner matrix plus the 2026-07-06 fresh public install smoke is a
strong release-candidate signal for targeted validation. It is not a broad
public-launch proof by itself. Codex Automations were rerun on 2026-07-02 in
local and worktree execution modes and failed to connect to `api.github.com`;
Claude `/loop` passed but is also removed from V1 to keep one uniform setup
path. The cadence row is foreground-style evidence for the runner/state
machine, not actual system cron. System cron and GitHub Actions schedule are
out of V1 scope. Browser/Playwright proof remains out of scope unless run in a
compatible non-sandboxed surface.

## How to publish (five channels, pick based on audience)

### 1. Cross-tool (Claude + Codex + .agents) — plain git repo
This repo is already shaped for it, and the clean temp-home proof passed on
2026-07-06. Users:
```sh
git clone <your-repo-url> autonomous-work-loops
cd autonomous-work-loops
./skills/autonomous-work-loops/assets/install.sh --symlink
```
`install.sh` drops it into `~/.claude/skills`, `~/.codex/skills`, and `~/.agents/skills`. This is the most auditable path — the security-conscious audience can read every line before trusting it with credentials. Lead with this for targeted validation.

### 2. Standard skill installer — public SKILL.md distribution
The nested skill folder resolved successfully in the 2026-07-06 clean install
proof. The shortest setup path is:

```sh
npx skills@latest add kaskilling/autonomous-work-loops
```

or:

```sh
npx skills@latest add kaskilling/autonomous-work-loops --skill autonomous-work-loops --agent codex --copy
```

This is the best "I just want the skill" path because it avoids a manual clone
and still installs into the user's agent skill directories.

### 3. Codex plugin marketplace
The repo carries `.codex-plugin/plugin.json`, and the clean local-marketplace
install proof passed on 2026-07-06. To make it installable as a Codex plugin,
publish it through a Codex plugin marketplace entry that points at this repo
and pins a tag or commit. The plugin manifest points Codex at the real
`./skills/` tree and includes UI metadata for the Codex app.

Use this path when you want Codex users to install the workflow as a plugin
rather than as a raw skill folder. Pin versions deliberately; this workflow can
mutate credentialed repositories.

### 4. Claude Code one-click — plugin marketplace
The repo carries `.claude-plugin/plugin.json`, and the clean local-marketplace
install proof passed on 2026-07-06. To make it installable:
- **Your own marketplace**: create a repo with `.claude-plugin/marketplace.json` listing this plugin with a `git` (or `git-subdir`) source and a pinned `sha`. Users run `/plugin marketplace add <your-marketplace-url>` then `/plugin install autonomous-work-loops`.
- **Official directory**: submit a PR to `anthropics/claude-code` (or the relevant community marketplace) adding an entry pointing at this repo with a pinned `sha`. This is how every plugin in `claude-plugins-official` is listed.

The local proof used Claude Code's plugin validator, marketplace add, plugin
install, and plugin details commands against a clean temp `HOME`.

### 5. Discovery content
A short README GIF of the label board moving `ready → in-progress → ready-for-human` on a clean proven PR, plus `needs-fix → in-progress → ready-for-human` when the reviewer finds a real defect, is the single most convincing artifact. Pair with a 60-second screen capture mirroring the source video's checkers/connect-four demo, but showing the **proof-anchored review/fix convergence** (the part the original glossed over) — that's your differentiation.

## Versioning

- `plugin.json` is at `0.1.7`. Bump to `1.0.0` only after the acceptance test passes on >=2 real repos.
- Marketplace entries should pin a `sha`, not a moving `ref`, given the autonomy/credential surface — users should opt into updates deliberately.

## Marketing: lead with the differentiator, not the novelty

"Loop engineering" is already a crowded term and `ralph-loop` already ships. Do **not** market this as "loops for Claude." Market the three things it has that nothing else does:

1. **Reviewed, not just retried.** Adversarial, proof-anchored review that converges on a clean proven pass and enters review→fix cycles only for real defects (most "autonomous PR" demos hand you unreviewed first-draft code). One-liner: *"It doesn't just write the PR — it reviews and hardens it until it converges."*
2. **Designed for guarded autonomy, not yet proven release-ready.** Trust-gated intake + proof-as-precondition + human gates + cost walls are the intended safety story. Strict trust and the guarded Codex runner now pass, but the wider matrix remains open. One-liner after the gate: *"It exposes the whole state machine in your issue labels and proves gates before claiming safety."*
3. **Portable and honest.** Works across Claude/Codex/any agent; state lives on the host so it's resumable and auditable; no hidden hosted service or unmanaged daemon. One-liner: *"No black box — the whole state machine is visible in your issue labels."*

### Channels
- **Show, don't tell**: the label-board GIF + the convergence demo. Post to the relevant agent-tooling communities and the comments of the source video (credit Neat Code).
- **Differentiation table** (already in `design/ECOSYSTEM.md`): ralph-loop vs. autonomous-work-loops. Reuse it verbatim in the launch post.
- **Trust angle for teams**: the safety section is the enterprise hook — "autonomy with guardrails" is what makes a team lead comfortable enabling it.

### What NOT to claim
- Don't claim "fully hands-off forever" — the human gate at merge is a feature, say so.
- Don't claim multi-host today — it's GitHub-only in v1 (the seam is built; the adapters aren't). Over-claiming here burns trust fast.
