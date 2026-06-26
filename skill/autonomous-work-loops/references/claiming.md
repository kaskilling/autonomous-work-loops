# Claiming

Cites ADR-0002, ADR-0004, ADR-0007, ADR-0008, ADR-0009.

The Work Claim is the atomic branch ref. Labels are advisory and human-visible.

## Claim Contract

1. Candidate issue must have the configured `ready` label.
2. Candidate issue must pass `is_trusted_actor`.
3. Implementer must be under active concurrency budget.
4. Implementer calls `claim_work`.
5. Only the tick that successfully creates `loop/impl/issue-<id>` owns the work.

The branch name is keyed on issue ID alone. Do not include title text, body hash, or implementation plan in the branch name.

## Stale Reclaim

A claim is stale when all are true:

- It is older than `max_runtime_minutes_per_loop * (kill_retries + 1)`.
- No branch progress or PR update exists after the claim timestamp.
- Latest markers do not show active proof, review, or fix progress on a newer SHA.

When stale, a later tick may reclaim by reading current state, posting a marker that explains the reclaim, and taking over the existing branch or creating a replacement branch only if the original cannot be used.

## Release on Runner Kill

If the runner reports an external-wall kill, the next tick should release or supersede the stale claim when possible. After `kill_retries`, route to `stalled`.
