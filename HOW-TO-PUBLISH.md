# How to Publish — simple step-by-step

This is the practical checklist. For the *why* behind channel choices, see `PUBLISHING.md`. For what's proven vs. designed, see the status note in `README.md`.

---

## Are we ready to publish? — honest answer

**Ready for: private development and targeted validation installs.**
**Not ready for: broad public launch or unattended public use without external user trials and pinned release tags.**

| Check | State |
|---|---|
| Core skill implemented + internally consistent | ✅ done |
| Safety-critical trust gate enforced in the privileged op | ✅ T2/T3/T4 author-only retest passed (`build/GATE-RESULTS.md`) |
| Docs match shipped behavior (no phantom flags, no stale cycle claims) | ✅ swept |
| Baseline live run passed (GitHub + Codex + pytest) | ✅ once |
| Guarded-runner matrix (strict-trust, no-proof, failed-proof, runner cadence, dup-claim, stale-claim) | ✅ strong targeted-validation signal in `build/GATE-RESULTS.md` |
| Browser-compatible proof | ⏳ still needs a compatible non-sandboxed surface |
| Fresh-install release-candidate smoke | ✅ passed 2026-07-06 on `kaskilling/awl-live-smoke-20260706` |
| Standard skill installer install | ✅ nested `skills/autonomous-work-loops` resolution passed |
| Codex plugin install | ✅ clean temp-home local-marketplace install passed |
| Claude plugin install | ✅ clean temp-home local-marketplace install passed |
| Root license | ✅ MIT `LICENSE` present and detected by GitHub |

**Recommendation:** keep this in targeted validation until at least one external
user repeats the fresh-install smoke from a pinned tag. The previous soft-launch
recommendation is superseded by `build/GATE-RESULTS.md`.

---

## Step 0 — Confirm GitHub publishing state

The product repo is published at `https://github.com/kaskilling/autonomous-work-loops`. That is not broad-launch approval. For a new fork or fresh clone, create the remote once:

```sh
cd <local checkout>/autonomous-work-loops
gh repo create kaskilling/autonomous-work-loops --public --source=. --remote=origin --push
# (use --private first if you want a closed soft-launch)
```

Tag targeted-validation builds so installs can pin them:
```sh
git tag v0.1.5 && git push origin v0.1.5
```

---

## Pick your channel by who you're serving

### Channel A — Cross-tool users (Claude + Codex + any agent) — **simplest, start here**

Anyone clones and runs the installer. Works for all three tools.

Tell users:
```sh
git clone https://github.com/<you>/autonomous-work-loops
cd autonomous-work-loops
./skills/autonomous-work-loops/assets/install.sh --symlink   # or omit --symlink to copy
```
That drops the skill into `~/.claude/skills`, `~/.codex/skills`, `~/.agents/skills`. Done — they invoke `/autonomous-work-loops` in any repo.

**Best for:** the security-conscious audience (they read the code before trusting it with credentials). This is the recommended lead channel for targeted validation.

### Channel B — Standard skill installer

The clean install test passed on 2026-07-06. The nested skill can be installed
with a standard skill installer:

```sh
npx skills@latest add kaskilling/autonomous-work-loops
```

For an explicit Codex copy install:

```sh
npx skills@latest add kaskilling/autonomous-work-loops --skill autonomous-work-loops --agent codex --copy
```

### Channel C — Codex plugin marketplace

The clean temp-home local-marketplace install test passed on 2026-07-06. The
repo now has `.codex-plugin/plugin.json`. To make it Codex-installable through a
marketplace, add a marketplace entry that points at this repo and pins a tag or
commit. The manifest points Codex at the real `./skills/` tree and includes
app-facing metadata.

Pin releases deliberately because the plugin can mutate credentialed repos.

### Channel D — Claude Code one-click (plugin marketplace)

The clean temp-home local-marketplace install test passed on 2026-07-06. The
repo already has `.claude-plugin/plugin.json`. To make it
`/plugin`-installable, create a tiny **marketplace repo** (or add a marketplace
file to this one):

`.claude-plugin/marketplace.json`:
```json
{
  "name": "your-marketplace",
  "owner": { "name": "<you>" },
  "plugins": [
    {
      "name": "autonomous-work-loops",
      "source": { "source": "git", "url": "https://github.com/<you>/autonomous-work-loops.git", "ref": "v0.1.5" },
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

Pin `ref` to the **tag** (`v0.1.5`), not a moving branch — this is autonomous code that runs with credentials, so updates should be deliberate.

### Channel E — Public discovery (the launch post)

Once an external user repeats the fresh-install smoke from a pinned tag,
announce it. Use the material already written:
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
4. Use the 2026-07-06 fresh-install smoke as the internal baseline.
5. Ask one external user to repeat standard skill installer, Codex plugin, and Claude plugin installs from clean agent homes before any broad public plugin or "leave it running" announcement.
