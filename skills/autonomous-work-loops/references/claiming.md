# Claiming

Cites ADR-0002, ADR-0004, ADR-0007, ADR-0008, ADR-0009.

The Work Claim is the atomic branch ref. Labels are advisory and human-visible.

## Claim Contract

1. Implementer calls `list_ready_work` to discover candidate issues. Discovery is read-only.
2. Candidate issue must have the configured `ready` label.
3. Candidate issue must pass `is_trusted_actor(issue_id)`.
4. Implementer must be under active concurrency budget.
5. Implementer calls `claim_work(issue_id)`.
6. `claim_work` re-asserts `is_trusted_actor(issue_id)` before any branch push or label flip. A safety decision must not depend on agent discipline alone.
7. Only the tick that successfully creates `loop/impl/issue-<id>` owns the work.

Under `strict`, `is_trusted_actor` means the issue author is in `trusted_actors`. Skip every other candidate before reading its body as execution instructions. External or untrusted work must arrive through a trusted-authored dispatch issue.

The branch name is keyed on issue ID alone. Do not include title text, body hash, or implementation plan in the branch name.

Never let `claim_work` choose the next issue by itself. Selection, trust classification, and privileged claiming are distinct steps.

## Stale Reclaim

A claim is stale when all are true:

- It is older than `max_runtime_minutes_per_loop * (kill_retries + 1)`.
- No branch progress or PR update exists after the claim timestamp.
- Latest markers do not show active proof, review, or fix progress on a newer SHA.

When stale, a later tick may reclaim by reading current state, posting a marker that explains the reclaim, and taking over the existing branch or creating a replacement branch only if the original cannot be used.

## Release on Runner Kill

If the runner reports an external-wall kill, the next tick should release or supersede the stale claim when possible. After `kill_retries`, route to `stalled`.
