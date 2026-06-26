# GitHub Adapter Reference

Cites ADR-0002, ADR-0004, ADR-0008, ADR-0009.

V1 supports GitHub only, behind these eight named host operations. All playbooks call these names rather than embedding host commands. A local markdown queue or mkdir-lock backend can later implement the same contract, but V1 does not build that backend.

## `claim_work`

Purpose: atomically claim one trusted `ready` issue for the Implementer.

Recipe:

```sh
issue="$(gh issue list --label ready --state open --json number,author,labels,updatedAt --jq '.[0].number')"
branch="loop/impl/issue-${issue}"
git fetch origin
git switch -c "$branch" "origin/$(git remote show origin | sed -n '/HEAD branch/s/.*: //p')"
git commit --allow-empty -m "Claim issue #${issue}"
git push origin "HEAD:refs/heads/${branch}"
gh issue edit "$issue" --remove-label ready --add-label in-progress
```

If the push fails because the remote ref already exists, another tick won. Back off and exit without changing work.

## `read_state`

Purpose: read labels, issue or PR body, comments, checks, branch, and current workflow state.

Recipe:

```sh
gh issue view "$issue" --json number,title,body,author,labels,comments
gh pr view "$pr" --json number,title,body,author,labels,comments,headRefName,headRefOid,baseRefName,statusCheckRollup
```

## `post_marker`

Purpose: append a marker comment to the issue or PR.

Recipe:

```sh
gh issue comment "$issue" --body-file marker.md
gh pr comment "$pr" --body-file marker.md
```

The first line of `marker.md` must be the marker grammar from `state-model.md`.

## `read_markers`

Purpose: read prior machine markers for the item.

Recipe:

```sh
gh issue view "$issue" --json comments --jq '.comments[].body | select(test("<!-- loop:"))'
gh pr view "$pr" --json comments --jq '.comments[].body | select(test("<!-- loop:"))'
```

Select the latest marker for each role by timestamp and compare its `reviewed_sha` to the current head.

## `set_label`

Purpose: move coarse workflow state.

Recipe:

```sh
gh issue edit "$issue" --remove-label "$from_label" --add-label "$to_label"
gh pr edit "$pr" --remove-label "$from_label" --add-label "$to_label"
```

Labels are advisory state, not locks.

## `open_change`

Purpose: open or update the PR for a claimed issue or tiny playbook suggestion.

Recipe:

```sh
git push origin "HEAD:${branch}"
gh pr create --title "$title" --body-file pr-body.md --base "$base_branch" --head "$branch"
gh pr edit "$pr" --body-file pr-body.md
```

Use update when a PR already exists for the branch.

## `get_head_sha`

Purpose: get the current commit for a branch or PR.

Recipe:

```sh
git fetch origin "$branch"
git rev-parse "origin/${branch}"
gh pr view "$pr" --json headRefOid --jq '.headRefOid'
```

## `is_trusted_actor`

Purpose: decide whether an issue can be claimed.

Recipe:

```sh
actor="$1"
gh api "repos/{owner}/{repo}/collaborators/${actor}/permission" --jq '.permission'
gh issue view "$issue" --json author,labels,comments
```

Return trusted only when the actor is listed in `.agent-loops/config.yaml` `trusted_actors`, has sufficient inferred permission under the configured `trust_posture`, or a trusted actor has explicitly vouched for the item.
