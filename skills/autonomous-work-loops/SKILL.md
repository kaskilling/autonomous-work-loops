---
name: autonomous-work-loops
description: Sets up and executes autonomous implement/review/fix work loops that claim trusted GitHub issues, open proven PRs, review them adversarially, and route convergence through host-visible state. Use when the user mentions work loops, autonomous PR, implement/review/fix loop, ready label, bootstrapping agent loops, or running a single loop tick.
metadata:
  short-description: Set up autonomous implement/review/fix work loops in a repo
---

# Autonomous Work Loops

The default user experience is product setup: when invoked from a target repo without an explicit role, set up autonomous-work-loops, prove the smoke path, and arm the managed local supervisor. The user should not have to choose an internal mode, run generated setup commands, or understand `.agent-loops/` before seeing whether the repo is ready.

The runtime remains host-state driven. Implementer, reviewer, and fixer ticks are stateless and reconstruct state from GitHub plus `.agent-loops/`. The managed background supervisor is only a local watch process with a PID file, log file, `--status`, and `--stop`; it is not cron, launchd, a hosted bot, Codex Automation, or Claude `/loop`. Durable background watch requires a persistent local terminal. If the current harness stops child processes after a command exits, use foreground `--watch` or tell the user the exact persistent-terminal command.

## Mode Selection

Use **Setup and Arm mode** when the user invokes the skill from a repository, asks to set up, install, initialize, bootstrap, configure, start, or "use" autonomous work loops, and does not provide an explicit tick role. Read:

1. `references/bootstrap.md`
2. `references/adapter-github.md`
3. `references/safety.md`
4. `references/budgets.md`

If `.agent-loops/` is absent, default to the guided-and-armed deterministic bootstrap:

```sh
<skill-root>/assets/bootstrap.sh --arm "$PWD"
```

If `.agent-loops/` already exists, do not overwrite it unless the user explicitly asks. Instead, run the generated checks and arm the managed supervisor:

```sh
.agent-loops/setup-labels.sh
.agent-loops/doctor.sh
.agent-loops/runners/local-supervisor.sh --preflight-runner "$PWD"
.agent-loops/runners/local-supervisor.sh --background "$PWD"
.agent-loops/runners/local-supervisor.sh --status "$PWD"
```

If status reports a stale or stopped background supervisor because the harness
reaped the child process, do not claim the repo is armed. Start foreground watch
in a persistent terminal or give the user the exact `--watch` command.

End Setup and Arm mode by telling the user:

- autonomous-work-loops is armed for this repo, or exactly what blocked setup
- the supervisor status/stop commands
- that new work starts by creating a trusted GitHub issue and adding the `ready` label
- that PRs appear from branches named `loop/impl/issue-N`

Use plain deterministic bootstrap only when the user explicitly asks for manual setup, dry setup, no GitHub mutation, or no background supervisor:

```sh
<skill-root>/assets/bootstrap.sh "$PWD"
```

Use agent-rendered bootstrap only when the script is unavailable.

Use **Tick mode** when the user or runner gives a role: `implementer`, `reviewer`, or `fixer`. Always reconstruct state from the host and `.agent-loops/` before acting. Read:

1. `references/adapter-github.md`
2. `references/state-model.md`
3. `references/convergence.md`
4. `references/claiming.md`
5. `references/budgets.md`
6. `references/evidence-capture.md`
7. the role playbook:
   - `references/loop-implementer.md`
   - `references/loop-reviewer.md`
   - `references/loop-fixer.md`

## Hard Rules

- Stay in V1 scope: no Maintainer Loop, no evidence consolidation, no Core Memory regeneration, no autonomous playbook mutation, no loopctl, no non-GitHub adapter.
- Do not ask the user to choose `bootstrap`, `implementer`, `reviewer`, or `fixer` when they simply invoke the skill from a repo. Choose Setup and Arm mode.
- Use the named host operations from `references/adapter-github.md`; do not invent host-specific steps in playbooks.
- Treat proof as a precondition for autonomous convergence. If proof is absent, route to `unproven` and a human gate.
- Reviewer may mark `ready-for-human` once proof passes, hosted checks are green or absent, and the head has no blocking defects. If hosted failures only match the default branch baseline, use `ready-for-human-baseline-red`. A clean first pass converges immediately; no fix cycle is forced when there is nothing to fix.
- Append evidence in the V2-compatible inbox schema, but only suggest playbook changes by tiny human-reviewed PR.
