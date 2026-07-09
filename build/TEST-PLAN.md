# Test Plan

This public test plan describes the validation shape without private fixture
repository names or local paths.

## Goal

Validate that one trusted GitHub issue labeled `ready` can become a proven,
reviewed PR that stops at a human merge gate.

Expected path:

```text
ready -> in-progress -> PR opened -> proof passed -> ready-for-human
```

or, when default-branch hosted checks are already red:

```text
ready -> in-progress -> PR opened -> proof passed -> ready-for-human-baseline-red
```

## Required Invariants

- Only trusted issues are claimed.
- One issue creates at most one loop branch and one PR.
- Proof is required before autonomous handoff.
- Reviewer/fixer cycles happen only for real blockers and respect the cycle cap.
- Re-running ticks on unchanged terminal heads no-ops.
- `unproven`, `did-not-converge`, and `stalled` remain separate from human-ready labels.
- Runtime walls prevent runaway local agent work.
- Marker comments remain parseable and tied to head SHAs.
- Nested role prompts receive bounded repo context.

## Surfaces To Validate

- Fresh install from a pinned tag.
- Bootstrap and setup-and-arm from a target GitHub repo.
- Local foreground supervisor.
- Hosted-check green, PR-only red, and default-branch baseline-red routing.
- No-proof routing to `unproven`.
- Duplicate-claim and stale-claim recovery.
- Reviewer/fixer cycle cap.

## Evidence Handling

Keep raw logs, local paths, hosted run URLs, and private fixture repo names in a
private validation archive. Public docs should include only sanitized summaries.
