---
name: autonomous-work-loops
description: Sets up and executes autonomous implement/review/fix work loops that claim trusted GitHub issues, open proven PRs, review them adversarially, and route convergence through host-visible state. Use when the user mentions work loops, autonomous PR, implement/review/fix loop, ready label, bootstrapping agent loops, or running a single loop tick.
metadata:
  short-description: Set up autonomous implement/review/fix work loops in a repo
---

# Autonomous Work Loops

Operate in exactly one mode per invocation. The skill is a bootstrapper plus a stateless single-tick executor; it never runs a daemon and never relies on memory from a prior tick.

## Mode Selection

Use **Bootstrap mode** when the user asks to set up, install, initialize, bootstrap, or configure autonomous work loops in a repository. Read:

1. `references/bootstrap.md`
2. `references/adapter-github.md`
3. `references/safety.md`
4. `references/budgets.md`

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
- Use the named host operations from `references/adapter-github.md`; do not invent host-specific steps in playbooks.
- Treat proof as a precondition for autonomous convergence. If proof is absent, route to `unproven` and a human gate.
- Reviewer may mark `ready-for-human` once proof passes and the head has no blocking defects. A clean first pass converges immediately — no fix cycle is forced when there is nothing to fix.
- Append evidence in the V2-compatible inbox schema, but only suggest playbook changes by tiny human-reviewed PR.
