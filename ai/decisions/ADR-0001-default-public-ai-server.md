# ADR-0001: Default clean installs to the Public AI chat server

Date: 2026-05-17
Status: Accepted

## Context

The mobile app inherited an OpenWebUI-style server connection screen as the first visible step. That is wrong for the Public AI app experience: normal users should not have to know or type the backend URL. They should either resume an existing session or authenticate against the Public AI chat service.

The app still needs to preserve developer/manual server workflows and existing user configurations. A forced migration that overwrites saved servers would be surprising and risky.

## Decision

On clean installs with no saved server configs, the app uses `https://chat.publicai.co` as the active server by default.

Normal Public AI startup should skip the server connection screen and route users into either:

- their existing authenticated session, or
- authentication against `https://chat.publicai.co`.

Saved/custom server configs continue to take precedence. The server connection screen remains available as a fallback/manual path; it is not deleted.

## Consequences

Benefits:

- Removes an implementation-detail screen from the first-run user journey.
- Keeps Public AI users on the canonical chat server without manual setup.
- Preserves existing saved/custom server behavior for developers and advanced users.
- Minimizes routing churn by making the default server available through the existing active-server provider path.

Tradeoffs:

- Public AI becomes a product default in app code, so future white-label/multi-tenant builds need an explicit build-time config strategy rather than relying on an empty server list.
- Manual server connection is now a fallback path, so QA must verify it remains reachable after startup/auth changes.

## Alternatives considered

### Keep showing the server connection screen

Rejected. It exposes backend plumbing to normal users and conflicts with the desired Public AI app flow.

### Seed Public AI into persisted server configs on first launch

Rejected for now. Returning a default active server from provider state is less invasive and avoids unnecessary writes/migration complexity.

### Force all users to Public AI regardless of saved configs

Rejected. It would break existing developer/custom-server usage and could strand users with existing sessions.

## Links

- `ai/architecture.md`
- `ai/tasks/native-oauth-callback-bridge.md`
- `lib/core/config/public_ai_server.dart`
- `lib/core/providers/app_providers.dart`
