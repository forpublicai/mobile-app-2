# Agent Operating Contract

This file defines how coding agents work in this repo and how they maintain the stable docs.

`ai/PLAN.md` is the primary workflow source of truth. If this file or any other stable doc conflicts with `ai/PLAN.md`, follow `ai/PLAN.md` and update the conflicting doc.

## Stable docs and when to use them

- `AGENTS.md`: repo entrypoint for coding agents. Keep short. It should point to the stable docs, not duplicate them.
- `CLAUDE.md`: Claude compatibility bridge. It should import `AGENTS.md` and avoid duplicate rules.
- `ai/PLAN.md`: primary planning/execution workflow and milestone/task template. Read before planning or implementing.
- `ai/agents.md`: this operating contract. Update when the agent workflow or doc-maintenance rules change.
- `ai/architecture.md`: durable product/system architecture. Update when changing primitives, data model, system boundaries, security model, orchestration, persistence, provider/tool boundaries, or major technical direction.
- `ai/design.md`: durable UI/UX and visual language. Update when changing navigation, layout, product surfaces, task/approval/artifact/memory UX, or visual language. Mark not applicable for non-UI repos.
- `ai/learnings.md`: durable lessons only. Update when a lesson will remain useful across future sessions. Do not add task logs, PR numbers, raw command output, or temporary status.
- `ai/decisions/`: ADRs. Add one when a decision would be expensive or confusing for future agents to relitigate.
- `ai/tasks/`: task-specific plans/handoffs for substantial work that is not a milestone plan.

## Engineering principles

- KISS: prefer the simplest design that satisfies current requirements.
- YAGNI: do not build speculative abstractions or integration layers before they are needed.
- DRY with judgment: remove harmful duplication, but do not hide simple flows behind premature generic frameworks.
- Make important state explicit and inspectable.
- Make side effects permissioned.
- Make failures legible and recoverable.
- Favor boring infrastructure until scale or correctness demands otherwise.

## Security rules

- Never commit secrets, tokens, raw API keys, passwords, private keys, cookies, or credential dumps.
- Do not print secrets into logs, reports, tests, screenshots, or agent transcripts.
- Treat external writes, emails, payments, account changes, deployments, deletes, and public posts as side-effecting actions that require explicit approval flows.
- Avoid storing sensitive user data unless the product requirement and retention model are explicit.
- Redact secrets from research or audit documents.


## Required workflow

For substantial planning or implementation, follow `ai/PLAN.md` exactly.

Short version:

1. Explore first.
   - Read `ai/PLAN.md`, this file, relevant architecture/design/learnings/ADRs, and relevant source files.
   - Discover repo/system facts before asking the user.
   - Ask only for product intent, preferences, or tradeoffs that cannot be discovered.

2. Plan.
   - Use the template from `ai/PLAN.md` or `ai/tasks/TASK_PLAN_TEMPLATE.md`.
   - Make plans self-contained and decision-complete.
   - Include validation, risks, blockers, and better-engineering concerns.

3. Validate the plan.
   - Use independent AI/code review when the plan is foundational, high-risk, or user-requested.
   - If the required reviewer/tool cannot run, stop and report the blocker.

4. Implement.
   - Make small, focused, reversible changes.
   - Prefer KISS, YAGNI, and boring durable engineering.
   - Do not create speculative abstractions or framework layers.

5. Validate implementation.
   - Run relevant tests/typechecks/lints/static checks.
   - Record validation results in the applicable plan or task file.

6. Review and better-engineer.
   - Fix blockers or document consciously deferred better-engineering work.
   - Check whether stable docs need updates.

7. Close.
   - Update stable docs only where their durable scope changed.
   - Do not promote temporary implementation details into stable docs.

## Doc consistency rules

When modifying stable docs, check for drift:

- If `ai/PLAN.md` changes, review `AGENTS.md`, `ai/README.md`, and this file for process conflicts.
- If architecture changes, review `ai/architecture.md`, relevant ADRs, `ai/learnings.md`, and active plans.
- If UI/UX changes, review `ai/design.md`, `ai/architecture.md` if primitives changed, and active plans.
- If a durable lesson is learned, add it to `ai/learnings.md` and remove duplicates from plans/docs if needed.
- If a stable doc restates another stable doc, prefer linking to the canonical source instead of duplicating.



## What not to do

- Do not contradict `ai/PLAN.md`.
- Do not turn `ai/learnings.md` into a changelog or task log.
- Do not put scratch thoughts into committed durable files.
- Do not claim work is complete without verification.
- Do not let provider-hosted agent state, framework state, or chat transcripts become the implicit canonical product database unless an ADR explicitly accepts that tradeoff.
