# Learnings

This file is for durable project learnings only. It is not a changelog, task log, scratchpad, or status report.

For workflow rules, follow `ai/PLAN.md` first and `ai/agents.md` second. If this file conflicts with those workflow docs, update this file.

## Rules for adding learnings

Add a learning only if it is likely to remain useful across future sessions.

Good examples:

- A stable architecture constraint.
- A recurring tool or platform pitfall.
- A product principle that prevents repeated mistakes.
- A security rule learned from implementation.
- A repo-specific command/runtime quirk that future agents will hit again.

Bad examples:

- “Today I changed file X.”
- PR numbers, commit hashes, issue numbers, or temporary status.
- Raw command output.
- Unverified hypotheses.
- Anything likely to be stale within a week.

## Product learnings

- `[Add durable product lessons here.]`

## Engineering learnings

- Root `AGENTS.md` is the cross-agent entrypoint; durable supporting docs live under `ai/`.
- Keep durable agent docs concise and scoped. Large instruction files become stale and consume agent context.
- `ai/PLAN.md` is the primary workflow source of truth; other stable docs should link to it instead of duplicating or overriding its process.
