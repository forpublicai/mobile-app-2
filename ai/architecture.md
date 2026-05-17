# Architecture

This is the current architecture map for the product/system. Keep it concise and update it when the system shape changes.

For workflow rules, follow `ai/PLAN.md` first and `ai/agents.md` second. For UI/UX and visual language, use `ai/design.md`. If this file conflicts with `ai/PLAN.md` about process, `ai/PLAN.md` wins.

## Product/system thesis

`[ONE_SENTENCE_PROJECT_THESIS]`

## Current scope

`[WHAT_EXISTS_TODAY_AND_WHAT_IS_INTENTIONALLY_OUT_OF_SCOPE]`

## Core primitives

These names should remain stable unless an ADR changes them:

- `[Primitive]` — `[definition]`
- `[Primitive]` — `[definition]`
- `[Primitive]` — `[definition]`

## Target system shape

```text
[User / Client / External Surface]
        ↓
[API / Interface Boundary]
        ↓
[Domain Services / Orchestrator]
        ↓
[Policy / Validation / Permissions]
        ↓
[Persistence / External Tools / Providers]
```

## State ownership principle

The application should own its canonical product state. External providers, frameworks, and tools may assist, but they should not accidentally define the product's durable model unless an ADR explicitly accepts that dependency.

The app should own:

- canonical entities and relationships
- authorization and policy checks
- side-effect approval rules
- credentials and secret boundaries
- durable audit/history where applicable
- user-visible status and failure states

## Trust and security model

Document the honest security posture here:

- data in transit
- data at rest
- access control
- secret handling
- side-effect approvals
- retention/deletion
- auditability
- third-party provider exposure

## Initial build posture

Prefer the simplest durable foundation that meets current requirements.

- Frontend: `[framework, if any]`
- Backend: `[framework/runtime]`
- Persistence: `[database/storage]`
- Background work: `[none/simple queue/worker/etc.]`
- External providers: `[adapters, not canonical state owners]`
- Observability: `[logs/metrics/traces]`

## Open questions

- `[QUESTION]`
- `[QUESTION]`

## Decision log

- `ai/decisions/ADR_TEMPLATE.md`
