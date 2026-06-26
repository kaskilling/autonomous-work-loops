# Work Claim atomicity comes from atomic branch-ref push, not labels

GitHub labels are last-write-wins, not compare-and-swap, so flipping `ready`→`in-progress` does *not* prevent two ticks from claiming the same item. We resolve the claim ordering of PLAN.md concretely:

- **Label flip is advisory** — a cheap, human-visible pre-filter that makes the board readable and sheds most early contention. Best-effort only.
- **The atomic guarantee is the deterministic branch ref.** The Implementer attempts to create a branch named `loop/impl/issue-<id>`. A `git push` of a new ref is atomic at the remote: two ticks racing the same ref, one wins, the loser's non-fast-forward push fails, detects the existing branch, and backs off. The branch *is* the lock — and it costs nothing extra because the work is branch-isolated anyway. This is the video's `mkdir`-lock insight lifted to the remote: use an operation the host already makes atomic.
- Hosts that can't cheaply pre-create a ref fall back to the local `mkdir` lock.

## Branch naming

Keyed on **issue ID alone** (`loop/impl/issue-123`), not issue ID + content hash. "One issue = one in-flight implementer branch" is the invariant; a content hash would let two ticks with slightly different plans both create branches — the exact duplicate-work failure being locked against.

## Stale-claim reclaim

The claim carries timestamp + SHA in its marker. A tick finding `in-progress` older than `max_runtime_minutes × (kill_retries + 1)` with no branch progress treats it as **stale and reclaimable**, re-deriving from host state (safe per ADR-0001) and taking over. Expiry is state-derived — no daemon sweeping dead locks. Covers the case ADR-0007's runner-cleanup misses: a tick that died without the runner cleaning up (sleep, SIGKILL, power loss).

## Considered Options

- **Trust label-flip, accept rare dupes** — silent duplicate branches/PRs under simultaneity. Kept only as the advisory layer, not the guarantee.
- **Self-assignment as CAS** — better signal than labels, still not atomic. Rejected as the guarantee.
