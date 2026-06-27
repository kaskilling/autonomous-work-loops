# How to Publish — simple step-by-step

This is the practical checklist. For the *why* behind channel choices, see `PUBLISHING.md`. For what's proven vs. designed, see the status table in `README.md`.

---

## Are we ready to publish? — honest answer

**Ready for: a soft launch to early testers / a public repo people can read and try.**
**Not yet ready for: a "1.0, trust it unattended on your repos" announcement.**

| Check | State |
|---|---|
| Core skill implemented + internally consistent | ✅ done |
| Safety-critical trust gate enforced in the privileged op | ✅ fixed + verified |
| Docs match shipped behavior (no phantom flags, no stale cycle claims) | ✅ swept |
| Baseline live run passed (GitHub + Codex + pytest) | ✅ once |
| Full validation matrix (strict-trust, no-proof, failed-proof, cron, dup-claim, stale-claim, browser/CI proof) | ⏳ not run |

**Recommendation:** publish now as **v0.1.0, labeled "early / GitHub + non-browser proof tested"**, with the README status table visible. Hold the **v1.0 "leave it running" announcement** until the validation matrix passes. The status table already tells this truth, so a soft launch is honest.

---

## Step 0 — Put it on GitHub (required for every channel)

The repo currently has no remote. One time:

```sh
cd /Users/mkamar/Non_Work/Projects/autonomous-work-loops
gh repo create autonomous-work-loops --public --source=. --remote=origin --push
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
- The **three one-liners** in `PUBLISHING.md` (reviewed-not-retried / safe-to-leave-running / no-black-box).
- A short **GIF of the label board moving** `ready → in-progress → ready-for-human` — the single most convincing artifact.
- Credit Neat Code's original video.

**Where:** agent-tooling communities, the source video's comments, and (when v1.0-ready) a PR to a community plugin marketplace.

---

## The one-paragraph version

1. `gh repo create … --public --push`, then `git tag v0.1.0 && git push --tags`.
2. For most people: point them at **Channel A** (clone + `install.sh`). It just works across Claude/Codex.
3. For Claude one-click: add a **marketplace.json** pinned to `v0.1.0` (Channel B).
4. Announce with the **ECOSYSTEM table + a label-board GIF** (Channel C), honestly labeled **early/v0.1**.
5. Run the **validation matrix** (`build/TEST-PLAN.md`) → then cut **v1.0** and do the big "leave it running" announcement.
