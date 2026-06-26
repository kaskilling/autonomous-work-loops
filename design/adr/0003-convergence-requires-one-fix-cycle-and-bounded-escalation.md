# Convergence on a clean proven pass; bounded escalation on defects

**Status: amended 2026-06-26.** This ADR originally *required* at least one fix cycle before `ready-for-human` (a mandatory adversarial hardening round). That rule was dropped — see "Superseded decision" below. The bounded-escalation half stands unchanged.

## Current decision

The Reviewer Loop flips a change to `ready-for-human` as soon as (i) proof passed **and** (ii) the current head SHA has no blocking defects. A clean, proven first pass converges immediately — no fix cycle is forced when there is nothing to fix.

Fix cycles arise only when the reviewer finds real blocking defects. Termination of those cycles is bounded by `max_reviewer_fixer_cycles_per_change`:
- At cap with only **non-blocking** items remaining → flip to `ready-for-human`, listing the remaining items so the human inherits a known state.
- At cap with **blocking** items still unresolved → escalate to the `did-not-converge` terminal label, route to human. Never exceed the cap.

## Superseded decision (why the mandatory cycle was dropped)

The original rule forced ≥1 fixer cycle even on a clean PR, to guard against same-model self-agreement (implementer and reviewer are the same model, so a clean first review might be a rubber stamp). The first live test exposed the flaw: on a clean change the forced cycle ran the fixer, the fixer found nothing, posted "no code changes needed," and the reviewer then approved **byte-identical code**. Two extra agent invocations, zero verification gained.

The rule only ever fired in the one case it helped least: proof-passed + reviewer-found-nothing. Where a real defect exists, a fix cycle happens *naturally* (the mandate is irrelevant); where proof is absent, ADR-0005 already blocks auto-convergence. And the "second look" the forced cycle bought came from the *same model* as the reviewer, so it carried the same blind spots — weak exactly where it needed to be strong. The mandate was largely redundant with proof-as-precondition, which was always doing the real verification work.

## What now guards rigor instead

- **Proof-as-precondition (ADR-0005):** no convergence without a green proof run; no-proof repos never auto-converge.
- **Adversarial reviewer stance (ADR-0010):** the reviewer is prompted to disconfirm and anchor to diff/proof facts, and same-model review without proof is barred from auto-converging.
- **Cross-model review (ADR-0010, opt-in):** the real antidote to same-model self-agreement, available when stronger review is wanted.

## Considered Options

- **Drop the mandatory cycle, approve on first clean proven pass (chosen).** Removes ceremony on every clean PR; leans on proof + adversarial stance for rigor.
- **Keep the blanket mandatory cycle (original).** Rejected: it bought motion, not rigor, and was redundant with proof.
- **Size/risk- or model-gated cycle (converge trivial/cross-model immediately, force a cycle only for same-model non-trivial changes).** Considered; rejected for V1 as more logic than the evidence justifies. Can be revisited if same-model rubber-stamping is observed in practice.

## Consequences

- "Are we at the cap?" is still answered by reading marker `cycle=N` — no agent memory (ADR-0001/0002).
- `did-not-converge` remains a first-class terminal state the human can see and triage.
- A clean PR now reaches the human in one implementer + one reviewer tick (cheaper, faster), which is the common case.
