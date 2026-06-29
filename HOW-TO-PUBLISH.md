# How to Publish — simple step-by-step

This is the practical checklist. For the *why* behind channel choices, see `PUBLISHING.md`. For what's proven vs. designed, see the status table in `README.md`.

---

## Are we ready to publish? — honest answer

**Ready for: private development and targeted validation only.**
**Not ready for: public soft launch, plugin distribution, or unattended use.**

| Check | State |
|---|---|
| Core skill implemented + internally consistent | ✅ done |
| Safety-critical trust gate enforced in the privileged op | ✅ T2/T3/T4 author-only retest passed (`build/GATE-RESULTS.md`) |
| Docs match shipped behavior (no phantom flags, no stale cycle claims) | ✅ swept |
| Baseline live run passed (GitHub + Codex + pytest) | ✅ once |
| Full validation matrix (strict-trust, no-proof, failed-proof, runner cadence, dup-claim, stale-claim, browser-compatible proof) | ✅ guarded-runner matrix is release-candidate ready in `build/GATE-RESULTS.md`; browser/Playwright proof still needs a compatible non-sandboxed surface |

**Recommendation:** keep this in targeted validation until one fresh-install release-candidate smoke passes on one V1 runner surface. The previous soft-launch recommendation is superseded by `build/GATE-RESULTS.md`.

---

## Step 0 — Confirm GitHub publishing state

The product repo is published at `https://github.com/kaskilling/autonomous-work-loops`. For a new fork or fresh clone, create the remote once:

```sh
cd <local checkout>/autonomous-work-loops
gh repo create kaskilling/autonomous-work-loops --public --source=. --remote=origin --push
# (use --private first if you want a closed soft-launch)
```

Tag the release so installs can pin it:
```sh
git tag v0.1.0 && git push origin v0.1.0
```

---

## Pick your channel by who you're serving

### Channel A — Cross-tool users (Claude + Codex + any agent) — **simplest, start here**

Anyone clones and runs the installer. Works for all three tools.

Tell users:
```sh
git clone https://github.com/<you>/autonomous-work-loops
cd autonomous-work-loops
./skill/autonomous-work-loops/assets/install.sh --symlink   # or omit --symlink to copy
```
That drops the skill into `~/.claude/skills`, `~/.codex/skills`, `~/.agents/skills`. Done — they invoke `/autonomous-work-loops` in any repo.

**Best for:** the security-conscious audience (they read the code before trusting it with credentials). This is the recommended lead channel.

### Channel B — Claude Code one-click (plugin marketplace)

The repo already has `.claude-plugin/plugin.json`. To make it `/plugin`-installable, create a tiny **marketplace repo** (or add a marketplace file to this one):

`.claude-plugin/marketplace.json`:
```json
{
  "name": "your-marketplace",
  "owner": { "name": "<you>" },
  "plugins": [
    {
      "name": "autonomous-work-loops",
      "source": { "source": "git", "url": "https://github.com/<you>/autonomous-work-loops.git", "ref": "v0.1.0" },
      "category": "automation"
    }
  ]
}
```

Users then run:
```
/plugin marketplace add https://github.com/<you>/autonomous-work-loops
/plugin install autonomous-work-loops
```

**Best for:** Claude Code users who want one-click + auto-update. Pin `ref` to the **tag** (`v0.1.0`), not a moving branch — this is autonomous code that runs with credentials, so updates should be deliberate.

### Channel C — Public discovery (the launch post)

Once A or B works, announce it. Use the material already written:
- The **ralph-loop vs autonomous-work-loops table** in `design/ECOSYSTEM.md` — paste verbatim.
- The **three one-liners** in `PUBLISHING.md` (reviewed-not-retried / guarded autonomy / no-black-box).
- A short **GIF of the label board moving** `ready → in-progress → ready-for-human` — the single most convincing artifact.
- Credit Neat Code's original video.

**Where:** agent-tooling communities, the source video's comments, and (when v1.0-ready) a PR to a community plugin marketplace.

---

## The one-paragraph version

1. Keep strict-trust semantics author-only and committed.
2. Treat T2/T3/T4 as passed only with auditor-verified evidence from `build/GATE-RESULTS.md`.
3. Rerun replacement T5 on a Git-capable Codex surface to prove allowlisted dispatch issues still work.
4. Only then create/push the public repo and tag a pre-release.
5. Continue the remaining validation matrix before any "leave it running" announcement.
