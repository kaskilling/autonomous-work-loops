# Skill is a bootstrapper plus a stateless single-tick executor

A skill is invoked once per conversation and ends, so it cannot *be* a long-running loop. We decided the Autonomous Work Loop Skill operates in two modes from one definition: a **Bootstrap** mode that discovers the repo and renders `.agent-loops/`, and a **tick** mode where one invocation = one loop role doing one unit of work and exiting. An explicit runner surface re-invokes tick mode; the skill never owns a daemon.

## Considered Options

- **Bootstrapper only** — emits runner artifacts that re-interpret loop logic. Rejected: loop behavior would be defined twice (skill's idea of a reviewer vs. the emitted runner's), drifting over time.
- **Long-running orchestrator** — skill spawns background loops in its own session. Rejected: dies when the session closes; this is the daemon framework the design explicitly avoids.

## Consequences

- **Hard constraint: the agent carries zero memory between ticks.** Every tick must reconstruct all needed state from host state (labels, PR comments, checks, branch SHAs) and repo files (`.agent-loops/`). "Remembering last time" is only legal if it was written to the host or the repo.
- The skill needs a clean bootstrap-vs-tick mode switch; tick mode must be idempotent.
- This is the chosen path for recurring runner execution, not manual human re-invocation.
- V1 has one runner surface: the local foreground supervisor. App-native schedulers such as Codex Automations and Claude `/loop`, plus system cron and GitHub Actions scheduling, are outside V1.
