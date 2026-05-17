# Design

This is the durable UI/UX and visual-language map for the app. If this project has no UI, mark this file as not applicable and keep it short.

For workflow rules, see `ai/PLAN.md` and `ai/agents.md`. If this file conflicts with `ai/PLAN.md` about process, `ai/PLAN.md` wins.

## Product experience thesis

`[WHAT_THE_PRODUCT_SHOULD_FEEL_LIKE_AND_HELP_THE_USER_DO]`

The user should always be able to answer:

- What can I do here?
- What is happening now?
- What needs my attention?
- What changed?
- What failed or is blocked?
- What side effects require confirmation?

## Primary UX primitives

- `[Primitive]` — `[definition]`
- `[Primitive]` — `[definition]`
- `[Primitive]` — `[definition]`

## Current visual language

`[CALM / DENSE / PLAYFUL / ENTERPRISE / MOBILE_FIRST / ETC.]`

Visual direction:

- Clear state over decorative complexity.
- The loudest element should be actionable or decision-relevant.
- Risk/destructive states must be visually unmistakable.
- Avoid relying on color alone for meaning.
- Prefer progressive disclosure over exposing every detail at once.

## Interaction principles

- Important state should be visible as structured UI, not buried in paragraphs.
- Side-effecting actions should use explicit confirmation UI with preview, risk, target account/tool, and allow/deny choices.
- Empty states should be concise and close to the relevant action.
- Failed or blocked work should be first-class and recoverable.
- Designs should survive larger text sizes and keyboard/screen-reader use.
- Important controls should have comfortable hit targets.
- Long-running work should have visible pending/progress states.
- The experience should remain useful when AI/providers/network calls are unavailable.

## Open design questions

- `[QUESTION]`
- `[QUESTION]`

## Update rules

Update this file when a change affects:

- navigation
- information architecture
- visual language
- product surfaces
- reusable UI primitives
- approval/confirmation UX
- permissions/settings UX
- artifact/task/thread/workflow interaction patterns

Do not use this file for implementation logs, temporary mockup notes, or milestone-specific task status. Put task-specific design decisions in the relevant plan; promote only durable design principles here.
