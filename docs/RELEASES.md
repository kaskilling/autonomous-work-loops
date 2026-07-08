# Releases

Use Git tags and GitHub releases for frozen states instead of committing copied repository snapshots.

Installable release train:

- `v0.1.11` - Public GitHub comments now use concise structured summaries, sanitize log excerpts, and keep runner-local prompt/proof/review/fixer paths out of PR and issue timelines.
- `v0.1.10` - Supervisor status now includes foreground/watch activity plus a current-work snapshot with issue, PR, phase, role, verdict, hosted checks, and next action.
- `v0.1.9` - Documentation cleanup: pinned copy install by default, explicit plugin invocation notes, current prerequisites, and clearer release-marker guidance.
- `v0.1.8` - Idempotent setup-and-arm reruns: existing `.agent-loops/` resumes without duplicate smoke issues; background durability docs now call out the persistent-terminal requirement.
- `v0.1.7` - Live setup-and-arm release gate: external-review fixer cycle fix, `tts-compare` PR #2 reached `ready-for-human`, managed background status/stop verified in a persistent terminal.
- `v0.1.6` - Setup-and-arm second-opinion hardening: supervisor status file, guided smoke failure cleanup, and recovery-focused bootstrap report.

Historical checkpoint tags:

- `v1.0.0` - V1 baseline before the guarded runner.
- `v1.5.0` - Guarded-runner V1.5 validation state.
- `v2-design` - Design-only V2 marker; V2 skill is not implemented.

Do not treat the historical checkpoint tags as newer installable releases.
Use the highest `v0.1.x` tag until the release train deliberately moves to
`v1.x`.

Keep raw logs, backups, and historical evidence in the private lab repository.
