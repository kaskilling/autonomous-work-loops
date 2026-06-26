# Work intake is trust-gated, with defaults inferred from repo shape

Under ADR-0001 the Implementer tick reads a `ready`-labeled issue unattended and treats the issue body as its prompt, then generates code and pushes a branch with the user's credentials on the user's machine. "Label = execute" is therefore a remote-code-execution / prompt-injection surface for any repo with more than one trusted human or any public issue creation.

We decided intake is **trust-gated**: the Implementer claims an issue only if it passes a trust check. Bootstrap detects repo visibility and the collaborator model and picks the default posture:
- solo / private → permissive (whoever set `ready` is trusted),
- multi-contributor / public → strict (`ready` must be applied by an allowlisted actor; untrusted-origin issues need a trusted human to vouch, e.g. a `vetted` label).

"Trusted actor" defaults to host-permission inference (write-access = trusted) but bootstrap emits an editable `trusted_actors` allowlist in `config.yaml` so the stricter "broad write access, few dispatchers" case is one edit away.

Intake trust is surfaced as a **Critical Decision** in the Bootstrap Report with the inferred default stated plainly.

## Consequences

- Corrects a priority inversion in the original design, which hardened the low-blast-radius evidence ledger against injection while leaving high-blast-radius work intake on the honor system.
- Intake trust is the *prior* gate ("should this be picked up at all"); path-scoped Human Gates (protected files, secrets) remain a *separate, later* gate.
- Rejected: trust-the-label-always (unsafe beyond solo repos); always-require-human-vetting (neuters the autonomy the loop exists to provide).
