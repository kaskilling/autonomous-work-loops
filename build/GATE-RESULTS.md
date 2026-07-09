# Gate Results

This public summary lists the release gates that passed without exposing private
fixture repositories, local paths, hosted run URLs, or raw transcripts.

## Current Status

Targeted validation is passing. Broad public launch still benefits from at
least one external user repeating install and setup from a pinned tag.

## Passed Gates

| Area | Result |
|---|---|
| Fresh install from public checkout | PASS |
| Standard skill installer path | PASS |
| Cross-tool installer into Claude, Codex, and `.agents` skill dirs | PASS |
| Codex plugin manifest install path | PASS |
| Claude plugin manifest validation/install path | PASS |
| Setup-and-arm happy path | PASS |
| Strict trusted-actor intake | PASS |
| Untrusted intake rejection | PASS |
| No-proof routing to `unproven` | PASS |
| Failed proof routing to `needs-fix` | PASS |
| Reviewer/fixer convergence | PASS |
| Cycle-cap escalation | PASS |
| Duplicate-claim prevention | PASS |
| Stale-claim recovery | PASS |
| Runtime wall and retry handling | PASS |
| Local supervisor status/stop | PASS |
| Hosted checks: green | PASS |
| Hosted checks: PR-only red | PASS |
| Hosted checks: default-branch baseline red | PASS |
| Public marker comment sanitization | PASS |
| Adaptive validation guidance | PASS |
| Successful smoke artifact cleanup | PASS |

## Evidence Policy

The detailed evidence archive contains private fixture repository names, local
paths, and run-specific logs. Keep it private unless separately sanitized.
