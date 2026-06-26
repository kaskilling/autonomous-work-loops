# V1 is core-only, but with forward-compatible capture and human-gated playbook suggestions

V1 ships the proven core (ADRs 0001–0005): intake → claim → implement → prove → review → fix → converge, GitHub-only, three playbooks + `config.yaml` + emitted runners + enforced budgets. The full self-evolution machine (Maintainer Loop, evidence consolidation, Core Memory regeneration, auto-application, `loopctl`, multi-host) is deferred to V2.

But pure deferral was rejected because the user's core motivation is "stop repeating the same mistake," and "go edit the playbook yourself" is unacceptable manual labor. Three moves keep the core alive *and* evolving without building the risky machinery:

1. **Capture in the V2 schema from day one.** Loops write structured evidence to `evidence/inbox/` in the exact shape V2 will consume (themes, scope, references, capped excerpts). V1 lacks only the *consumer*. No reshape at upgrade.
2. **Human-gated suggestion, no autonomous mutation.** When evidence for the same theme+scope crosses a small threshold (e.g. 3), the Reviewer tick — at the end of its normal run — opens a **tiny PR against the playbook file** proposing the addition. The agent does the *noticing*; the human keeps the *deciding* via merge-click. No new loop, no silent edits, no unread log.
3. **V1→V2 is an additive enable, not a new setup.** File layout, schema, and config keys are the V2 ones from the start. Upgrading = re-run bootstrap in an `--enable evolution` mode that flips a flag and registers the Maintainer runner; accumulated `evidence/inbox/` becomes its input. A V1 repo evolves in place.

## Consequences

- V1's build surface stays small: structured append (agent writes the file directly — no helper) + a count check at tick end + "open a tiny PR when count ≥ N." `loopctl` proper still defers to V2.
- Suggestions go through PR review — same trust model as all durable-guidance changes (consistent with ADR-0004's spirit). "Yes" is a merge, not a hand-edit.
- The V2 ADRs and CONTEXT.md remain valid: they describe the target; V1 is an honest subset.
- Rejected: pure (B) defer-everything (leaves the user hand-editing); write-only log nobody reads (captures signal but never acts).
