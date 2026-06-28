# Publishing & Marketing

## Before broad public release: the gates that matter

The baseline v1 acceptance test passed once on a live private GitHub repo, the author-only strict rejection retest now passes for untrusted authors and prompt-injection issues, allowlisted dispatch acceptance passes, and the guarded Codex runner now claims and converges on live GitHub. No-proof routing, ready-for-human honesty, reviewer idempotency, duplicate-claim race behavior, and stale-claim recovery also pass on guarded live runs. Public release is still blocked by the remaining workability and quality matrix. In strict mode, executable issues must be authored by `trusted_actors`; external work must be rewritten as a trusted-authored dispatch issue. Continue the remaining validation matrix on throwaway repos:

1. Create a small repo with a real test command and 1–2 `ready` issues.
2. Bootstrap: `/autonomous-work-loops`.
3. Run the three roles a few ticks each (locally, under `timeout`).
4. Confirm: one `ready` issue → claimed → proven PR → `ready-for-human`. A clean proven PR may converge on the first review; review→fix cycles happen only when defects are found. The remaining unproven public-release checks are cost wall kill proof, cron cadence, planted-defect review quality, and a hard issue capping out at `did-not-converge` rather than looping forever.

Do not market this, including to early testers, until the remaining matrix passes. The variants and new testing still matter, but strict trust, Codex claim transport, no-proof routing, duplicate claims, and stale-claim recovery are no longer the active blockers. Everything below is a post-gate publishing path, not current permission to launch.

## How to publish (three channels, pick based on audience)

### 1. Cross-tool (Claude + Codex + .agents) — plain git repo
This repo is already shaped for it. Users:
```sh
git clone <your-repo-url> autonomous-work-loops
cd autonomous-work-loops
./skill/autonomous-work-loops/assets/install.sh --symlink
```
`install.sh` drops it into `~/.claude/skills`, `~/.codex/skills`, and `~/.agents/skills`. This is the most auditable path — the security-conscious audience can read every line before trusting it with credentials. Lead with this for a security-aware launch.

### 2. Claude Code one-click — plugin marketplace
The repo carries `.claude-plugin/plugin.json`. To make it installable:
- **Your own marketplace**: create a repo with `.claude-plugin/marketplace.json` listing this plugin with a `git` (or `git-subdir`) source and a pinned `sha`. Users run `/plugin marketplace add <your-marketplace-url>` then `/plugin install autonomous-work-loops`.
- **Official directory**: submit a PR to `anthropics/claude-code` (or the relevant community marketplace) adding an entry pointing at this repo with a pinned `sha`. This is how every plugin in `claude-plugins-official` is listed.

### 3. Discovery content
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
