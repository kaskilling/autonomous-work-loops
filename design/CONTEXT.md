# Loop Skill Design

This context defines the language for a portable skill that helps agents set up autonomous work loops in a software repository.

## Language

**Autonomous Work Loop Skill**:
A Codex skill that teaches an agent how to design and run repo-specific loops for selecting work, implementing changes, reviewing pull requests, fixing review feedback, and handing finished work back to a human.
_Avoid_: Runtime loop system, daemon framework, hardcoded automation product

**Runtime Component**:
An optional script, command, or scheduled process generated for a specific repository when plain skill instructions are not enough.
_Avoid_: Required daemon, platform, framework

**Host-Agnostic Setup**:
A setup approach that starts by discovering where a repository tracks work and code review, then selects host-specific instructions only after that discovery.
_Avoid_: GitHub-first setup, GitHub-only labels, hardcoded pull request workflow

**Host Adapter**:
A focused reference document or helper that maps the common loop concepts onto one work host or review host, such as GitHub, GitLab, Bitbucket, Jira, Linear, or a local markdown queue.
_Avoid_: Provider lock-in, platform plugin

**Canonical Loop**:
One of the base roles in an autonomous work system: Implementer, Reviewer, or Fixer. Canonical Loops define the stable lifecycle responsibilities that specialized behavior builds on.
_Avoid_: One-off agent, ad hoc loop, custom daemon

**Implementer Loop**:
The Canonical Loop that claims ready work, isolates the work in a branch or worktree, implements the requested change, proves it, and opens it for review.
_Avoid_: Builder, coder

**Reviewer Loop**:
The Canonical Loop that examines unreviewed or updated changes, leaves actionable feedback when needed, and marks the change ready for human review when no blocking feedback remains.
_Avoid_: Finalizer, approver

**Fixer Loop**:
The Canonical Loop that claims changes with unresolved feedback, failed proof, or conflicts, applies fixes, proves the result, and responds to or resolves the feedback.
_Avoid_: Repair bot, comment resolver

**Loop Variant**:
A specialized version of a Canonical Loop that adds domain, language, framework, quality, security, or product guidance without changing the base loop responsibility.
_Avoid_: Fourth loop type, separate workflow family

**Guidance Source**:
A source of operating instructions for a loop. Guidance Sources are applied in this order: repository guidance first, skill-provided templates second, and run parameters third.
_Avoid_: Prompt blob, hidden system prompt

**Loop Playbook**:
A repo-local, versioned guidance file that tells one Canonical Loop or Loop Variant how to operate in that repository. Loop Playbooks hold durable standards; runtime configuration selects and overrides them for a specific run.
_Avoid_: Hidden prompt, generated note, transient instruction

**Guideline Feedback**:
Human or agent feedback that can improve a Loop Playbook when it repeats, corrects a wrong pattern, or reveals a missing repository convention.
_Avoid_: Every PR comment, raw review dump, chat transcript

**Playbook Maintainer Loop**:
An optional loop that reviews accumulated Guideline Feedback and proposes versioned updates to Loop Playbooks. It runs on evidence thresholds or explicit requests, not on every issue or review.
_Avoid_: Always-on fourth loop, automatic prompt mutator

**Evidence Ledger**:
A repo-local record of summarized Guideline Feedback gathered by loops while they work. It stores concise evidence events and links, not full transcripts or raw review dumps.
_Avoid_: Prompt memory, chat log, analytics warehouse

**Evidence Inbox**:
A low-conflict holding area for new evidence events written by working loops before the Playbook Maintainer Loop consolidates them into the Evidence Ledger.
_Avoid_: Single shared append file for every branch, noisy evidence commits

**Playbook Update Change**:
A proposed repository change that edits one or more Loop Playbooks based on Evidence Ledger patterns. It should include evidence links and a rationale so a human or reviewer loop can judge the update.
_Avoid_: Silent guideline mutation, automatic policy change

**Bootstrap Run**:
The first setup pass of the Autonomous Work Loop Skill in a repository. It should discover host, tooling, repo guidance, proof commands, and safe defaults, then ask only for critical human decisions.
_Avoid_: Manual setup wizard, questionnaire, one-size-fits-all install

**Critical Decision**:
A bootstrap choice that changes autonomy, write access, cost, repository ownership, security posture, or irreversible workflow structure. Non-critical choices should be inferred and written as editable defaults.
_Avoid_: Preference, cosmetic setting, trivial parameter

**Self-Evolving Setup**:
A default setup mode where loops write lightweight evidence while working and the Playbook Maintainer Loop can propose playbook updates over time.
_Avoid_: Silent self-modification, uncontrolled memory

**Loop Extension**:
An added loop role or specialization that plugs into the core loop system without changing the core contract. Loop Extensions can add security review, accessibility review, release notes, deployment checks, or other repo-specific work.
_Avoid_: Forked loop system, hardcoded special case

**Execution Surface**:
The place where loops run, such as a local machine, host CI, host scheduler, Codex session, Claude Code session, Cursor session, OpenCode session, or a server. Bootstrap should select a working default when obvious and ask only when multiple viable surfaces carry different trade-offs.
_Avoid_: Required runtime, single blessed platform

**Credential Profile**:
The selected identity and model access used by loops. A Credential Profile names the product, authentication mode, allowed actions, and cost posture without storing secrets in repo guidance.
_Avoid_: Raw token, hidden auth assumption, global user identity

**Loop Budget**:
The concurrency, frequency, model, and task-size limits that keep autonomous loops from spending unbounded time or money.
_Avoid_: Unlimited mode, best effort spending

**Human Gate**:
A boundary where loops must stop and ask for human approval. Human Gates protect high-risk actions such as merging, deployment, secret access, production data, billing, destructive operations, and permanent policy changes.
_Avoid_: Manual review for everything, silent privileged action

**Loop Trigger**:
A host-native or local signal that starts a loop, such as a ready work item, opened review change, unresolved blocking feedback, failed checks, merge conflict, manual request, or low-frequency schedule.
_Avoid_: Poll everything, run constantly, hidden timer

**Fallback Workflow Vocabulary**:
The portable status terms bootstrap creates when a repository has no obvious host-native workflow vocabulary: ready, in-progress, needs-fix, and ready-for-human.
_Avoid_: GitHub-only labels, custom statuses without mapping

**Core Memory**:
A short generated summary of the most useful current loop guidance for a repository. Core Memory is derived from Loop Playbooks and the Evidence Ledger; it is not the source of truth.
_Avoid_: Unbounded memory file, hidden prompt state, policy source

**Evidence Reference**:
A stable pointer from an Evidence Ledger event to the work item, review comment, CI run, commit, conversation, or local artifact that caused the evidence. Evidence References support auditability without copying raw content into the ledger.
_Avoid_: Full transcript, copied PR thread, unlinked claim

**Evidence Excerpt**:
A short, sanitized quote or summary from an Evidence Reference that lets the Playbook Maintainer Loop understand the signal without fetching every source. Evidence Excerpts are capped and must not include secrets, full logs, or full threads.
_Avoid_: Raw comment dump, copied CI log, stored secret

**Loop Control Helper**:
A small repo-local command that handles deterministic loop mechanics such as recording evidence, regenerating Core Memory, and validating loop configuration.
_Avoid_: Large runtime framework, hidden daemon, manual JSON editing

**Execution Profile**:
An editable configuration entry that describes where and how a loop can run. Bootstrap should create a local interactive profile first when viable, and add host CI or scheduler profiles when the repository supports them.
_Avoid_: Single runtime assumption, daemon-first setup

**Bootstrap Report**:
A concise output from a Bootstrap Run that states what was detected, what files were created, what defaults were selected, which Human Gates apply, how to start the loops, and which Critical Decisions remain unresolved.
_Avoid_: Long installation guide, hidden setup result

**Skill Router**:
The top-level skill instructions that decide which references and templates to use for the current repository. The Skill Router should stay concise and delegate details to references.
_Avoid_: Monolithic skill file, host-specific blob

**Loop Template**:
A reusable starter asset copied and adapted during Bootstrap Run to create `.agent-loops/` files. A Loop Template provides structure, not final repository-specific policy.
_Avoid_: Fixed install, generated boilerplate from scratch

**Loop Invocation Contract**:
The minimal instructions needed to run a loop with any supported agent product: role, target, playbooks, allowed actions, budget, evidence behavior, and stop conditions.
_Avoid_: Product-specific daemon, vague "run the loop" instruction

**Work Claim**:
A host-native or local lock proving that one loop owns a work item or review change for the current attempt. Work Claims prevent duplicate implementation or fixer work.
_Avoid_: Best-effort polling, duplicate branch creation

**Guidance Scope**:
The repository area where a playbook rule, evidence event, or Core Memory item applies, such as a package, path prefix, language, framework, service, or bounded context.
_Avoid_: Globalizing local rules, repo-wide assumptions from one folder

**Automation Coexistence**:
A setup mode where the loop system detects existing bots, review tools, CI automations, or host workflows and integrates with them instead of duplicating their behavior.
_Avoid_: Competing reviewer bots, duplicate comments, ignored existing configuration

## Example Dialogue

Developer: "Do we need to ship a daemon for every project?"

Domain expert: "No. The Autonomous Work Loop Skill should first guide an agent through setup in the current repo. Runtime Components are optional and repo-specific."

Developer: "Can the skill assume GitHub labels and pull requests?"

Domain expert: "No. The skill is Host-Agnostic. It should detect the host first, then load the right Host Adapter."

Developer: "Do specialized security reviewers and frontend fixers create new loop types?"

Domain expert: "No. They are Loop Variants layered onto the Reviewer Loop or Fixer Loop."

Developer: "Where should a Reviewer Loop learn project standards from?"

Domain expert: "Start with repository guidance, add skill-provided templates, then apply run parameters for the current invocation."

Developer: "Should learned loop guidance stay hidden in generated prompts?"

Domain expert: "No. Durable guidance belongs in versioned Loop Playbooks. Runtime config can choose which playbooks and overrides to use."

Developer: "Should playbook updates happen after every review?"

Domain expert: "No. A Playbook Maintainer Loop should run only when enough Guideline Feedback accumulates or a human explicitly asks for it."

Developer: "Who turns repeated feedback into durable guidance?"

Domain expert: "Working loops write summarized evidence to the Evidence Ledger. The Playbook Maintainer Loop reads that ledger and proposes a Playbook Update Change when the evidence is strong enough."

Developer: "Should bootstrap ask about every setup detail?"

Domain expert: "No. Bootstrap should infer safe editable defaults and ask only for Critical Decisions."

Developer: "Can users add new specialized loops later?"

Domain expert: "Yes. The core loop system should be open to Loop Extensions without changing the Implementer, Reviewer, Fixer, and Maintainer contracts."

Developer: "Should loops edit Core Memory directly?"

Domain expert: "No. The Playbook Maintainer Loop updates Loop Playbooks through a Playbook Update Change, then regenerates Core Memory from the accepted playbooks and high-confidence evidence."

Developer: "Should Core Memory be committed?"

Domain expert: "Yes. Commit generated Core Memory so changes are portable and reviewable, but mark it as generated and regenerate it from playbooks and evidence."

Developer: "Should the Evidence Ledger copy full review comments?"

Domain expert: "No. Store Evidence References plus capped Evidence Excerpts."

Developer: "Should agents hand-edit evidence and generated memory?"

Domain expert: "No. Use a Loop Control Helper for deterministic mechanics, and keep judgment in the Loop Playbooks."

Developer: "Where should loops run by default?"

Domain expert: "Bootstrap should prefer a local interactive Execution Profile when viable, then add host CI or scheduler profiles as editable alternatives."

Developer: "Which credentials should bootstrap use by default?"

Domain expert: "Use the current user's working credentials with least-privilege loop actions, write Credential Profiles without secrets, and support bot or service profiles later."

Developer: "What starts each loop?"

Domain expert: "Use host-native Loop Triggers when present. If none exist, create the Fallback Workflow Vocabulary."

Developer: "What can loops do without human approval?"

Domain expert: "Loops may work on isolated branches, open or update review changes, and record evidence. Human Gates protect merge, deploy, secrets, production data, billing, destructive actions, security policy, durable playbook changes, and cost escalation."

Developer: "Should loops run without cost limits by default?"

Domain expert: "No. Loop Budgets should be conservative by default and easy to raise through reviewed configuration."

Developer: "How should specialized loops plug in?"

Domain expert: "A Loop Extension extends one Canonical Loop and declares triggers, playbooks, allowed actions, evidence themes, budget overrides, and Human Gates without changing the core lifecycle."

Developer: "What should bootstrap leave behind?"

Domain expert: "Bootstrap should create the repo-local loop files and a Bootstrap Report. It may open a review change when the host and credentials allow it."

Developer: "Should the skill generate all setup files from scratch?"

Domain expert: "No. Use a Loop Template for stable structure, then adapt it through repository discovery."

Developer: "Should bootstrap copy the template before discovery?"

Domain expert: "No. Bootstrap should discover first, fill a setup model, then render the Loop Template with safe defaults and report unknowns."

Developer: "How do loops avoid duplicate work?"

Domain expert: "Each loop must create or verify a Work Claim before making changes."

Developer: "Should one evidence file be appended from every branch?"

Domain expert: "No. Working loops should write to an Evidence Inbox, and the Playbook Maintainer Loop should consolidate durable patterns into the Evidence Ledger."

Developer: "Should bootstrap ignore existing AI review tools?"

Domain expert: "No. Bootstrap should use Automation Coexistence to integrate with existing tools and avoid duplicate review behavior."
