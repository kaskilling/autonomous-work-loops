# Work intake is trust-gated, with defaults inferred from repo shape

Under ADR-0001 the Implementer tick reads a `ready`-labeled issue unattended and treats the issue body as its prompt, then generates code and pushes a branch with the user's credentials on the user's machine. "Label = execute" is therefore a remote-code-execution / prompt-injection surface for any repo with more than one trusted human or any public issue creation.

We decided intake is **trust-gated**: the Implementer claims an issue only if it passes a trust check. Bootstrap detects repo visibility and the collaborator model and picks the default posture:
- solo / private -> permissive (the `ready` label can be enough when the repo is controlled by one trusted operator),
- multi-contributor / public -> strict (the issue author must be in `trusted_actors`).

For V1 strict mode, trust is author-only:

```text
strict trusted iff issue author is in trusted_actors
strict untrusted iff issue author is not in trusted_actors
```

External or untrusted issues do not become executable through a bare `vetted` label, a `loop-vouch:` comment, collaborator/admin permission, or issue text that claims authorization. A trusted maintainer instead creates a new trusted-authored dispatch issue that summarizes the accepted work, links the source issue when useful, and labels that dispatch issue `ready`.

Permissive mode may still use repo shape and collaborator context for solo private repos. Strict mode never treats broad repository permission as enough.

Intake trust is surfaced as a **Critical Decision** in the Bootstrap Report with the inferred default stated plainly.

## Consequences

- Corrects a priority inversion in the original design, which hardened the low-blast-radius evidence ledger against injection while leaving high-blast-radius work intake on the honor system.
- Intake trust is the *prior* gate ("should this be picked up at all"); path-scoped Human Gates (protected files, secrets) remain a *separate, later* gate.
- Dispatch issues keep V1 simple and deterministic: the gate checks one host fact, the issue author, before any branch push or label flip.
- Rejected for V1: trust-the-label-always (unsafe beyond solo repos), strict-mode vouch comments or label-actor verification (too much timeline parsing and ambiguity), always-require-human-vetting for solo repos (neuters the autonomy the loop exists to provide).
