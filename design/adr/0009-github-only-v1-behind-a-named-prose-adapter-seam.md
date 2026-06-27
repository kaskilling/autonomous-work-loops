# GitHub-only V1, but behind a named prose adapter seam

V1 ships exactly one host adapter (GitHub), but every host-touching operation goes through a small named contract rather than inlined `gh` calls: `list_ready_work`, `is_trusted_actor`, `claim_work`, `read_state`, `post_marker`, `read_markers`, `set_label`, `open_change`, `get_head_sha`. Tick logic and playbooks call the contract by name; only the adapter knows it's GitHub. Discovery (`list_ready_work`), trust classification (`is_trusted_actor`), and privileged claiming (`claim_work`) stay separate so the trust gate is enforced before host mutation.

This makes V2 multi-host an **addition** (a GitLab implementation of the same contract), consistent with ADR-0006's "additive enable, never a rewrite." The seam is discovered *from* the single GitHub implementation, avoiding speculative multi-host design — GitLab either fits the contract or teaches us where it's wrong, cheaply, from a second real case.

## Where the seam lives

**Prose contract in a reference doc**, not a code interface. The tick is an agent reading instructions; the adapter is a reference section ("here are the host operations and how to do each on GitHub"). This keeps V1 codeless, honoring the not-a-runtime-framework thesis (CONTEXT.md). V2's GitLab support is a new reference section — additive.

## Consequences

- The local `mkdir`-lock fallback (ADR-0008) and the "no-host markdown queue" case become just other implementations of the same contract, not special cases bolted onto GitHub logic.
- CONTEXT.md's "Host Adapter" term becomes real rather than aspirational from V1.

## Considered Options

- **Hardcode GitHub inline** — fastest, but makes V2 multi-host a rewrite, contradicting ADR-0006. Rejected.
- **Full multi-host abstraction now** — premature generalization from a single example; cannot design the seam well from one case. Rejected.
