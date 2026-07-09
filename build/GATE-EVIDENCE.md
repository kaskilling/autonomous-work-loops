# Gate Evidence

Detailed gate evidence is intentionally not published here.

The private evidence archive contains raw transcripts, local proof logs, hosted
run URLs, private fixture repository names, and machine-local paths. Those
artifacts are useful for maintainers but are not appropriate for the public
package.

Public release notes should cite summarized outcomes only:

- trusted issues are claimed
- untrusted issues are skipped
- proof gates are required
- no-proof work routes to `unproven`
- failed proof routes to `needs-fix`
- review/fix cycles converge or escalate
- hosted checks are classified before handoff
- local supervisor status and stop controls work

If a future maintainer wants to publish detailed evidence, sanitize it first by
removing private owner names, repository names, local paths, hosted run URLs,
tokens, raw logs, prompt logs, and machine-specific error details.
