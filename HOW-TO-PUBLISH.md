# How to Publish — simple step-by-step

This is the practical checklist. For the *why* behind channel choices, see `PUBLISHING.md`. For the current proof record, see `build/GATE-RESULTS.md`.

---

## Publishing Gate

Before publishing a new channel or announcing a broader release, check
`PUBLISHING.md` for the release posture and `build/GATE-RESULTS.md` for the
current proof record. This file is only the mechanical checklist.

---

## Step 0 — Confirm GitHub publishing state

The product repo is published at `https://github.com/kaskilling/autonomous-work-loops`. That is not broad-launch approval. For a new fork or fresh clone, create the remote once:

```sh
cd <local checkout>/autonomous-work-loops
gh repo create kaskilling/autonomous-work-loops --public --source=. --remote=origin --push
```

Tag targeted-validation builds so installs can pin them:
```sh
git tag v0.1.10 && git push origin v0.1.10
```

---

## Pick your channel by who you're serving

### Channel A — Cross-tool users (Claude + Codex + any agent) — **simplest, start here**

Anyone clones and runs the installer. Works for all three tools.

Tell users:
```sh
git clone --branch v0.1.10 --depth 1 https://github.com/kaskilling/autonomous-work-loops.git
cd autonomous-work-loops
./skills/autonomous-work-loops/assets/install.sh
```
That drops a fixed copy of the skill into `~/.claude/skills`, `~/.codex/skills`,
and `~/.agents/skills`. Done — they invoke `/autonomous-work-loops` in any repo.
Use `--symlink` only for development checkouts.

**Best for:** the security-conscious audience (they read the code before trusting it with credentials). This is the recommended lead channel for targeted validation.

### Channel B — Standard skill installer

The clean install test passed. The nested skill can be installed with a standard
skill installer:

```sh
npx skills@latest add kaskilling/autonomous-work-loops
```

For an explicit Codex copy install:

```sh
npx skills@latest add kaskilling/autonomous-work-loops --skill autonomous-work-loops --agent codex --copy
```

### Channel C — Codex plugin marketplace

The clean temp-home local-marketplace install test passed. The repo now has
`.codex-plugin/plugin.json`. To make it Codex-installable through a
marketplace, add a marketplace entry that points at this repo and pins a tag or
commit. The manifest points Codex at the real `./skills/` tree and includes
app-facing metadata.

Pin releases deliberately because the plugin can mutate credentialed repos.

### Channel D — Claude Code one-click (plugin marketplace)

The clean temp-home local-marketplace install test passed. The repo already has
`.claude-plugin/plugin.json`. To make it
`/plugin`-installable, create a tiny **marketplace repo** (or add a marketplace
file to this one):

`.claude-plugin/marketplace.json`:
```json
{
  "name": "your-marketplace",
  "owner": { "name": "kaskilling" },
  "plugins": [
    {
      "name": "autonomous-work-loops",
      "source": { "source": "git", "url": "https://github.com/kaskilling/autonomous-work-loops.git", "ref": "v0.1.10" },
      "category": "automation"
    }
  ]
}
```

After that marketplace repository exists, users add its actual GitHub URL with
`/plugin marketplace add ...`, then run `/plugin install autonomous-work-loops`.

Pin `ref` to the **tag** (`v0.1.10`), not a moving branch — this is autonomous code that runs with credentials, so updates should be deliberate.

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
2. Treat live hosted-check routing as proven only by the green, PR-only red, and baseline-red rows in `build/GATE-RESULTS.md`.
3. Use the fresh-install smoke plus setup-and-arm live runs as the internal baseline.
4. Ask one external user to repeat install and setup from a pinned tag before any broad public plugin or "leave it running" announcement.
