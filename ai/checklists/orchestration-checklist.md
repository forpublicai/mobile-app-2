# AI Orchestration Checklist

Use this when adding or changing agentic workflows.

## State

- What is the canonical state record?
- Is state restart-safe and inspectable?
- Are IDs stable across retries/resumes?
- Is there an event/audit trail for important transitions?

## Execution

- What starts the work?
- What can pause it?
- What resumes it?
- What retries safely?
- What must be idempotent?

## Human control

- Which actions need approval?
- What preview/risk/context does the user see before approving?
- Can the user deny, cancel, retry, or revise?

## Tool/provider boundaries

- Which provider/tool is an adapter only?
- What state must not be owned by the provider/tool?
- Where are credentials stored and scoped?
- What is logged, and are secrets redacted?

## Validation

- What unit tests cover state transitions?
- What integration tests cover pause/resume/failure?
- What manual walkthrough proves the user can understand status and recover from failure?
