# AI Working Docs

This folder contains durable context for humans and coding agents working on this repo.

## Authority order

1. `PLAN.md` is the primary workflow source of truth. If another stable doc conflicts with it, follow `PLAN.md` and fix the other doc.
2. `agents.md` explains how agents use and maintain these docs.
3. `architecture.md`, `design.md`, `learnings.md`, and `decisions/` provide durable context within their scopes.

## Files

- `PLAN.md` — primary milestone/task planning, execution, validation, and review workflow.
- `agents.md` — stable operating contract for coding agents and doc-maintenance rules.
- `architecture.md` — current architecture map, product/system primitives, boundaries, risks, and durable decisions.
- `design.md` — UI/UX direction, visual language, interaction patterns, and user-experience constraints. Mark not applicable for non-UI projects.
- `learnings.md` — durable project learnings only.
- `decisions/` — architecture decision records (ADRs).
- `tasks/` — task-specific plans and handoffs for substantial work that is not a milestone plan.

## Rules

- Keep these files short, factual, and maintained.
- Do not store secrets or raw credentials in this folder.
- Do not put temporary scratch notes in durable files.
- Do not duplicate `PLAN.md` workflow text elsewhere; link to it and keep it authoritative.
- If implementation drifts from the active plan, update the plan before continuing.
- If a change affects architecture, persistence, API contracts, security, permissions, agent state, or major dependencies, update `architecture.md` and/or add an ADR.
- If a change affects UI/UX, visual language, navigation, product surface, or interaction behavior, update `design.md`.
- If a lesson will likely be stale within a week, do not add it to `learnings.md`.
- Prefer links to canonical docs/files over duplicating long content.
