# Proof is a precondition; its absence degrades the loop, never fakes success

For autonomous code generation, "the proof passed" (tests/build/lint) is the entire safety net that lets a human *not* read every diff. We decided proof-command discovery is first-class in Bootstrap, written to `config.yaml` (`proof: { test, build, lint }`), with explicit tick-time behavior:

- proof exists and **passes** → normal flow.
- proof exists and **fails** → `needs-fix` (feeds the convergence machine of ADR-0003); never `ready-for-human`.
- proof **cannot be found** → Implementer may still do the work, but the change is flagged `unproven` and routed to a human gate, outside the autonomous converge path. The loop refuses to claim unproven work is ready.

Bootstrap surfaces a missing proof command as a **Critical Decision**.

Core principle: **the loop may produce unproven work, but must never launder unproven work as converged.** A PR reaching the human as `ready-for-human` *without* an `unproven` flag is a guarantee that proof actually ran.

## Agent-authored proof

When proof is absent, the Implementer may *create* a proof harness (e.g. a smoke test) as part of its work, but agent-authored proof is lower-trust: the first time a repo's proof is agent-authored it is a human gate; once a human accepts the harness, later work runs against it freely. This closes the self-certification loophole.

## Considered Options

- **Best-effort (implement anyway, no flag)** — turns the loop into a generator of unverified code and makes `ready-for-human` a lie. Rejected.
- **Refuse to run without proof** — too absolute; blocks the legitimate greenfield-scaffold use case. Rejected.

## Consequences

- `unproven` joins `did-not-converge` as a first-class human-triage outcome; both are marker-readable (ADR-0001/0002).

## Amendment (see ADR-0010)

Tightened: because the default reviewer is the *same model* as the implementer and is prone to self-agreement, a repo with **no proof command never runs the autonomous review→converge path** — it only produces `unproven` → human gate. Proof-present is a precondition for auto-convergence, not merely for a clean `ready-for-human`.
