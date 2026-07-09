# Prove The Gate Plan

This is the public-safe validation plan. Raw command transcripts and private
fixture details belong in the private evidence archive.

## Validation Shape

1. Create an isolated GitHub fixture repository.
2. Install AWL from a pinned public tag.
3. Bootstrap and arm the fixture.
4. Create trusted and untrusted issues.
5. Run the local supervisor.
6. Verify state through GitHub labels, PR branches, and marker comments.
7. Verify proof, review, hosted-check, and fixer behavior.
8. Clean up fixture artifacts after validation.

## Required Assertions

- Trusted `ready` issues can be claimed.
- Untrusted issues are ignored in strict mode.
- Every claim creates at most one loop branch and one PR.
- Proof failures do not converge to human-ready labels.
- No-proof repos route to `unproven`.
- Reviewer/fixer cycles stop at the configured cap.
- Hosted checks are green, pending, failed, or baseline-red classified before
  human handoff.
- Repeated ticks are idempotent on terminal heads.
- Supervisor status and stop commands work.

## Public Evidence Rules

Do not commit private fixture repo names, local checkout paths, hosted run URLs,
raw logs, prompt logs, or machine-specific config paths. Public docs should use
`example-owner/example-repo`, `$FIXTURE_ROOT`, or summarized outcome language.
