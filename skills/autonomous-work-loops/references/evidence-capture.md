# Evidence Capture

Cites ADR-0006, ADR-0009.

V1 captures evidence in the V2-compatible inbox schema. It does not consolidate evidence, regenerate Core Memory, run a Maintainer Loop, or apply playbook edits automatically.

## Inbox Location

Append one markdown or YAML file per notable event under:

```text
.agent-loops/evidence/inbox/
```

Use filenames that sort by time, for example:

```text
2026-06-26T12-30-00Z-reviewer-pr-42-proof-failed.yaml
```

## Schema

```yaml
schema: evidence.v2
ts: "<iso>"
role: implementer | reviewer | fixer
item: "<issue-or-pr>"
head_sha: "<sha>"
theme: "<short repeated pattern>"
scope: "<playbook-or-path-scope>"
severity: info | warning | blocking
summary: "<one sentence>"
references:
  - "<file, marker, proof command, or host URL>"
excerpt: "<capped relevant text>"
```

Keep excerpts short and specific. Do not copy secrets, tokens, private keys, or unrelated logs.

## Public Comments

GitHub issue and PR comments are a public product surface. Post structured
summaries with verdict, short reason, next action, and sanitized excerpts only.
Do not publish absolute runner paths, prompt-log paths, raw hook output, token
counts, secrets, or full local logs. Point humans to the local evidence folder
instead:

```text
.agent-loops/evidence/prove-the-gate/logs/
```

## Tiny PR Suggestion

At the end of a normal Reviewer tick, count inbox items with the same `theme` and `scope`. If the count is at least the configured threshold, open one tiny PR that edits only the relevant playbook. The PR body must cite the evidence files and ask for human review.

The suggestion is the only V1 evolution behavior. Merge is the human approval gate.
