# Same-model review must be adversarial and proof-anchored; no-proof + same-model never auto-converges

The Implementer and Reviewer are, by default, the same model running the same skill in different roles. An LLM reviewing near-identical-model output tends toward self-agreement, which would make the review→fix cycle (the value per ADR-0003) theatre. V1's answer:

- **Adversarial framing.** The Reviewer playbook forces disconfirmation: assume defects exist, find what's wrong, verify diff claims don't lie.
- **Proof anchor.** The Reviewer is anchored to objective signal it cannot rubber-stamp away — proof results (ADR-0005), changed-files, actual diff inspection — not vibes. Even if framing fails, there is a hard floor: "did proof actually pass."
- **Opt-in cross-model review.** `reviewer_model: <override>` in config; if the user has a second model, cross-model review (which genuinely reduces correlated blind spots) is one line away, supported by per-role Credential Profiles. Default is same-model; docs name cross-model as the highest-leverage quality upgrade.

## Tightening of ADR-0005

Because same-model review with *no* objective anchor makes the reviewer the sole gate — too weak to mean anything — **a repo with no proof command never runs the autonomous review→converge path.** It only produces `unproven` → human gate. Proof-present is a precondition for auto-convergence, not just for a clean `ready-for-human`. (Cross-model review is what *could* justify auto-converge without proof, but that is a V2-shaped concern.)

## Considered Options

- **Same model, plain "now review" prompt** — self-agreement bias; shallow review, meaningless fast convergence. Rejected as the default posture.
- **Mandatory different model in V1** — violates model-agnostic simplicity, requires two configured model accesses. Kept as opt-in, not required.
