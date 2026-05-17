# [PROJECT_NAME] AI Planning and Execution Workflow

This document is the primary workflow source of truth for substantial coding-agent work in this repo. If another stable doc conflicts with this file, follow this file and update the conflicting doc.

Use this file for milestone plans, substantial task plans, implementation execution, validation, review, and closure.

---

## HOW TO PLAN A MILESTONE OR SUBSTANTIAL TASK

If the user asks you to plan a milestone, feature, refactor, migration, or substantial task, these are the steps to take.

1. Read this document completely.
2. Read prior relevant plans in `ai/tasks/` and any milestone documents if they exist.
3. Read the stable docs needed for the work:
   - `AGENTS.md`
   - `ai/agents.md`
   - `ai/architecture.md`
   - `ai/design.md` if UI/UX is affected
   - `ai/learnings.md`
   - relevant ADRs in `ai/decisions/`
4. Explore before asking.
   - Discover repo/system facts from source, configs, schemas, tests, manifests, docs, and runtime commands.
   - Do not ask the user questions that can be answered from the repo or system.
   - Ask only when ambiguity changes the plan and cannot be resolved through research.
5. Clarify product intent and tradeoffs when needed.
   - Ask concrete, contextual questions with 2–4 meaningful options where possible.
   - Recommend a default.
   - If proceeding with an assumption, record it in the plan.
6. Research external dependencies and platform behavior when relevant.
   - Use official docs/source where possible.
   - Verify API/runtime assumptions instead of guessing.
7. Make the plan decision-complete and self-contained.
   - The implementer should not need hidden context.
   - Include exact files, interfaces, data flow, edge cases, failure modes, validation, rollout/rollback, and compatibility concerns as applicable.
8. Look for better-engineering blockers.
   - If the discovered problem is small, include it in the plan.
   - If it is a separate foundational issue, stop and report it instead of building on a bad foundation.
9. Validate the plan.
   - Use independent AI/code review when the plan is foundational, security-sensitive, architecture-changing, high-risk, or user-requested.
   - If a required reviewer/tool cannot run, stop and report the blocker.
   - Incorporate useful feedback. If rejecting feedback, explain why in the plan.
10. Present the plan for user signoff unless the user explicitly asked you to proceed autonomously.

## PLAN FILE FORMAT

Save substantial plans under `ai/tasks/` unless the repo has a separate milestone naming convention.

Use this format:

```markdown
# Task plan: [Title]

## Summary

[Brief summary of deliverables and validation.]

## HOW TO EXECUTE

[Include the HOW TO EXECUTE section from this document verbatim if the plan may be handed to another agent.]

## Locked user decisions

[All user-made decisions and assumptions being carried forward.]

## PLAN

[Decision-complete implementation plan. Include files, APIs/schemas, algorithms, migrations, rollout, edge cases, and tests as applicable.]

## BETTER ENGINEERING INSIGHTS + BACKLOG ADDITIONS

[Architectural insights, cleanup opportunities, deferred better-engineering work.]

## AI VALIDATION PLAN

[How the executor will prove the work is done: tests, typechecking, linting, builds, manual walkthroughs, independent review.]

## AI VALIDATION RESULTS

[Filled during execution with commands run and outcomes.]

## USER VALIDATION SUGGESTIONS

[Concrete steps the user can follow to inspect the result.]
```

---

## HOW TO EXECUTE

[Include this section verbatim inside handoff plans when useful.]

If the user asks you to execute on a plan, these are the steps to take.

1. Re-read the plan and relevant stable docs.
   - `AGENTS.md`
   - `ai/PLAN.md`
   - `ai/agents.md`
   - `ai/architecture.md`
   - `ai/design.md` if UI/UX is affected
   - `ai/learnings.md`
   - relevant ADRs
2. Confirm the working tree and current implementation state.
   - Do not assume the plan still matches reality.
   - If reality diverges materially, update the plan before continuing.
3. Implement in small, focused, reversible steps.
   - Prefer boring, durable engineering.
   - Avoid speculative abstractions.
   - Keep state, side effects, and failure modes explicit.
4. Validate continuously.
   - Run targeted tests after each meaningful change.
   - Run broader checks before closure: typecheck, lint, tests, build, or project-specific equivalents.
   - If validation cannot run, record why and what remains risky.
5. Record validation results.
   - Update the plan's `AI VALIDATION RESULTS` section with commands and outcomes.
   - Do not paste huge raw logs; summarize and include key failures/results.
6. Review the work.
   - Self-review for correctness, security, maintainability, and plan compliance.
   - Use independent AI/code review when required by the plan or risk level.
   - Fix blockers or document consciously deferred issues.
7. Better-engineer before closing.
   - Remove accidental duplication and dead code.
   - Check whether stable docs need updates.
   - Add/update ADRs for durable architecture decisions.
   - Add only durable lessons to `ai/learnings.md`.
8. Close with user validation guidance.
   - Tell the user what changed.
   - Tell the user exactly what was validated.
   - Tell the user what to test manually, if anything.

---

## BETTER-ENGINEERING DECISION TREE

Use this when deciding where to record information:

- `ai/architecture.md`: durable system shape, boundaries, data model, security model, orchestration, persistence, provider/tool boundaries, major technical direction.
- `ai/design.md`: durable UI/UX, navigation, interaction model, visual language, product surfaces, accessibility expectations.
- `ai/learnings.md`: durable lessons that prevent repeated mistakes across future sessions.
- `ai/decisions/`: ADRs for choices that would be expensive or confusing to relitigate.
- `ai/tasks/`: task-specific decisions, validation results, blockers, and temporary implementation details.
- Nowhere: scratch thoughts, stale status, raw logs, secrets, credentials, private user data.

## VALIDATION DEFAULTS

Every substantial implementation should identify and run the relevant checks for the repo. Common examples:

- unit tests
- integration tests
- typecheck
- lint/static analysis
- format check
- build/package check
- migration/schema validation
- smoke test or manual walkthrough
- security/secret scan when secrets, auth, logs, or external side effects are touched

Do not claim completion without verification. If verification is impossible, say exactly why and what risk remains.

## SECURITY DEFAULTS

- Never commit secrets, tokens, raw API keys, passwords, private keys, cookies, or credential dumps.
- Do not print secrets into logs, reports, tests, screenshots, or agent transcripts.
- Treat external writes, emails, payments, account changes, deployments, deletes, and public posts as side-effecting actions that require explicit approval flows.
- Redact secrets from research, audits, and durable docs.
- Keep provider/tool credentials behind explicit boundaries.

## ORCHESTRATION DEFAULTS

When building AI/agent workflows:

- The app should own canonical state unless an ADR says otherwise.
- Providers and frameworks should be adapters, not accidental product databases.
- Long-running work needs visible status and recoverable failure states.
- Approval pauses should persist state and resume cleanly.
- Tool calls should be auditable and permissioned.
- Memory should be user-visible/editable when it affects user experience.
- Structured work objects beat burying state in chat text.
