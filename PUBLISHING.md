# Publishing & Marketing

## Publishing status: targeted validation, not broad launch

The project is ready for private development and targeted validation. It is not ready for a broad public soft launch, unattended public use, or plugin marketplace distribution until the fresh-install smoke and packaging install tests pass.

Preserve the current proof: the baseline v1 acceptance test passed once on a live private GitHub repo, the author-only strict rejection retest now passes for untrusted authors and prompt-injection issues, allowlisted dispatch acceptance passes, and the guarded runners now claim and converge on live GitHub. No-proof routing, ready-for-human honesty, reviewer idempotency, duplicate-claim race behavior, stale-claim recovery, cost-wall recovery, cycle-cap escalation, foreground cadence, and planted-defect review routing also pass on guarded fixture runs. In strict mode, executable issues must be authored by `trusted_actors`; external work must be rewritten as a trusted-authored dispatch issue. The V1 product path is now one visible local foreground supervisor. Codex Automations and Claude `/loop` are removed from V1 setup.

Before broad public release, prove the release candidate from a fresh install:

1. Create a small repo with a real test command and 1–2 `ready` issues.
2. Bootstrap: `/autonomous-work-loops`.
3. Start the tested V1 runner surface: `.agent-loops/runners/local-supervisor.sh "$PWD"`.
4. Confirm: one `ready` issue -> claimed -> proven PR -> `ready-for-human`. A clean proven PR may converge on the first review; review->fix cycles happen only when defects are found.
5. Confirm later intervals no-op cleanly and create no duplicate branch, PR, or review marker.

Before broad plugin or installer distribution, prove each packaging path from a clean machine or clean agent home:

1. Standard skill installer: verify the installer can resolve and install the nested `skills/autonomous-work-loops` folder, or publish a wrapper that exposes that folder as the root skill.
2. Codex plugin: install from a pinned marketplace entry or pinned repo/tag and verify Codex loads the plugin metadata and skill.
3. Claude plugin: install from a pinned marketplace entry or pinned repo/tag and verify Claude Code loads the plugin metadata and skill.
4. Cross-tool installer: run `./skills/autonomous-work-loops/assets/install.sh --symlink` or copy mode into clean `~/.claude/skills`, `~/.codex/skills`, and `~/.agents/skills`, then invoke the skill in a target repo.

The guarded-runner matrix is a strong release-candidate signal for targeted validation, and the local foreground supervisor path has live fixture evidence. It is not public-launch proof by itself. Codex Automations were rerun on 2026-07-02 in local and worktree execution modes and failed to connect to `api.github.com`; Claude `/loop` passed but is also removed from V1 to keep one uniform setup path. The cadence row is foreground-style evidence for the runner/state machine, not actual system cron. System cron and GitHub Actions schedule are out of V1 scope. Browser/Playwright proof remains out of scope unless run in a compatible non-sandboxed surface.

## How to publish (five channels, pick based on audience)

### 1. Cross-tool (Claude + Codex + .agents) — plain git repo
This repo is already shaped for it. Users:
```sh
git clone <your-repo-url> autonomous-work-loops
cd autonomous-work-loops
./skills/autonomous-work-loops/assets/install.sh --symlink
```
`install.sh` drops it into `~/.claude/skills`, `~/.codex/skills`, and `~/.agents/skills`. This is the most auditable path — the security-conscious audience can read every line before trusting it with credentials. Lead with this for targeted validation.

### 2. Standard skill installer — public SKILL.md distribution
Treat this as a packaging target until the install test passes. Once the public repo path is stable, make the skill installable through a standard SKILL.md installer. The target experience should be:

```sh
npx skills@latest add kaskilling/autonomous-work-loops
```

or an equivalent installer command that pulls the `skills/autonomous-work-loops` folder from GitHub. This is the best "I just want the skill" path because it avoids a manual clone and still installs into the user's agent skill directories.

Before recommending this broadly, verify the installer resolves a nested skill folder correctly and loads the skill in a clean agent home. If it does not, publish a tiny wrapper repo or package that exposes `skills/autonomous-work-loops` as the root skill folder.

### 3. Codex plugin marketplace
The repo carries `.codex-plugin/plugin.json`. Treat this as a packaging target until a clean Codex plugin install passes. To make it installable as a Codex plugin, publish it through a Codex plugin marketplace entry that points at this repo and pins a tag or commit. The plugin manifest points Codex at the real `./skills/` tree and includes UI metadata for the Codex app.

Use this path when you want Codex users to install the workflow as a plugin rather than as a raw skill folder. Before recommending it broadly, verify Codex loads the pinned plugin and exposes `/autonomous-work-loops`. Pin versions deliberately; this workflow can mutate credentialed repositories.

### 4. Claude Code one-click — plugin marketplace
The repo carries `.claude-plugin/plugin.json`. Treat this as a packaging target until a clean Claude Code plugin install passes. To make it installable:
- **Your own marketplace**: create a repo with `.claude-plugin/marketplace.json` listing this plugin with a `git` (or `git-subdir`) source and a pinned `sha`. Users run `/plugin marketplace add <your-marketplace-url>` then `/plugin install autonomous-work-loops`.
- **Official directory**: submit a PR to `anthropics/claude-code` (or the relevant community marketplace) adding an entry pointing at this repo with a pinned `sha`. This is how every plugin in `claude-plugins-official` is listed.

Before recommending this broadly, verify Claude Code installs the pinned plugin and exposes `/autonomous-work-loops`.

### 5. Discovery content
A short README GIF of the label board moving `ready → in-progress → ready-for-human` on a clean proven PR, plus `needs-fix → in-progress → ready-for-human` when the reviewer finds a real defect, is the single most convincing artifact. Pair with a 60-second screen capture mirroring the source video's checkers/connect-four demo, but showing the **proof-anchored review/fix convergence** (the part the original glossed over) — that's your differentiation.

## Versioning

- `plugin.json` is at `0.1.0`. Bump to `1.0.0` only after the acceptance test passes on ≥2 real repos.
- Marketplace entries should pin a `sha`, not a moving `ref`, given the autonomy/credential surface — users should opt into updates deliberately.

## Marketing: lead with the differentiator, not the novelty

"Loop engineering" is already a crowded term and `ralph-loop` already ships. Do **not** market this as "loops for Claude." Market the three things it has that nothing else does:

1. **Reviewed, not just retried.** Adversarial, proof-anchored review that converges on a clean proven pass and enters review→fix cycles only for real defects (most "autonomous PR" demos hand you unreviewed first-draft code). One-liner: *"It doesn't just write the PR — it reviews and hardens it until it converges."*
2. **Designed for guarded autonomy, not yet proven release-ready.** Trust-gated intake + proof-as-precondition + human gates + cost walls are the intended safety story. Strict trust and the guarded Codex runner now pass, but the wider matrix remains open. One-liner after the gate: *"It exposes the whole state machine in your issue labels and proves gates before claiming safety."*
3. **Portable and honest.** Works across Claude/Codex/any agent; state lives on the host so it's resumable and auditable; no hidden daemon. One-liner: *"No black box — the whole state machine is visible in your issue labels."*

### Channels
- **Show, don't tell**: the label-board GIF + the convergence demo. Post to the relevant agent-tooling communities and the comments of the source video (credit Neat Code).
- **Differentiation table** (already in `design/ECOSYSTEM.md`): ralph-loop vs. autonomous-work-loops. Reuse it verbatim in the launch post.
- **Trust angle for teams**: the safety section is the enterprise hook — "autonomy with guardrails" is what makes a team lead comfortable enabling it.

### What NOT to claim
- Don't claim "fully hands-off forever" — the human gate at merge is a feature, say so.
- Don't claim multi-host today — it's GitHub-only in v1 (the seam is built; the adapters aren't). Over-claiming here burns trust fast.
