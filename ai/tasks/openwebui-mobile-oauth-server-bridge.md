# Task plan: OpenWebUI mobile OAuth server bridge

## Summary

Implement the smallest server bridge needed for the mobile app to reuse the already-working `https://chat.publicai.co` OAuth flow. Do not build a second Google/OIDC service and do not point Cognito directly at the mobile app. The server should start the existing OpenWebUI OAuth flow, let it complete normally, then replace only the final successful web redirect with a mobile one-time-code handoff when the flow was started by the native app.

## HOW TO EXECUTE

If the user asks you to execute on this plan, these are the steps to take.

1. Re-read the plan and relevant stable docs.
   - `ai/plan.md` / repo workflow docs
   - `ai/architecture.md`
   - `ai/decisions/ADR-0002-native-browser-oauth-callback-bridge.md`
   - `ai/tasks/native-oauth-callback-bridge.md`
2. Confirm the actual backend source repo that builds the deployed image.
   - `chat.publicai.co` is the Helm/deployment repo.
   - It currently deploys `ghcr.io/forpublicai/open-webui`.
   - Patch the OpenWebUI fork/source repo that produces that image, not only the Helm repo.
3. Inspect the current OAuth routes before editing.
   - Existing start route: `/oauth/{provider}/login`
   - Existing callback routes: `/oauth/{provider}/login/callback` and `/oauth/{provider}/callback`
   - Existing callback implementation: `OAuthManager.handle_callback(...)` in `open_webui/utils/oauth.py`
4. Implement in small reversible steps.
5. Validate normal web OAuth behavior remains unchanged when the mobile handoff cookie is absent.
6. Validate mobile handoff returns a one-time code, never a JWT in the callback URL.
7. Record validation results and rollout notes.

## Locked decisions

- The website OAuth flow at `https://chat.publicai.co` already works and is the source of truth.
- The mobile bridge must reuse existing OpenWebUI/Cognito/OIDC OAuth completion.
- Do not implement a second Google/OIDC stack.
- Do not register `publicai://auth/callback` directly with Cognito/Google for the initial bridge.
- Do not put the OpenWebUI JWT directly in a custom-scheme callback.
- The callback carries only a short-lived single-use mobile handoff code plus the original app state.
- The app exchanges the handoff code over HTTPS for the OpenWebUI JWT.
- Normal web OAuth behavior must remain unchanged for flows that did not start through `/api/mobile/oauth/start`.
- PublicAI's displayed provider may be Google, but the OpenWebUI provider key may be `oidc`; use the configured provider key, not a hardcoded display label.

## KISS architecture

### Chosen approach: cookie-marked web OAuth flow + Redis handoff code

The minimal flow:

1. Mobile calls `/api/mobile/oauth/start?provider=<provider>&redirect_uri=publicai%3A%2F%2Fauth%2Fcallback&state=<app-state>`.
2. Server validates the request.
3. Server sets a short-lived signed HTTP-only secure cookie, for example `mobile_oauth`, containing provider, redirect URI, state, issued-at, and expiry.
4. Server redirects to the already-working OpenWebUI route: `/oauth/{provider}/login`.
5. Cognito/OIDC/provider login completes exactly as it does for the website.
6. OpenWebUI callback verifies the provider response, resolves/provisions the user, stores OAuth session state, and mints the normal OpenWebUI JWT exactly as it does today.
7. At the final redirect branch only:
   - If no valid `mobile_oauth` cookie exists, return the current web response unchanged.
   - If a valid `mobile_oauth` cookie exists for the same provider, store the minted OpenWebUI JWT behind a short-lived one-time Redis code and redirect to `publicai://auth/callback?code=<code>&state=<state>`.
8. Mobile calls `/api/mobile/oauth/exchange` with `code`, `state`, and `redirect_uri`.
9. Server atomically consumes the Redis code and returns `{ "token": "<OpenWebUI JWT>" }`.

### Why this is minimal

- No Cognito redirect URI changes for mobile.
- No duplicate OIDC client.
- No provider-token exchange from the app.
- No new database table unless Redis is unavailable.
- No changes to web OAuth start/provider/callback semantics except the final redirect branch when explicitly mobile-started.
- Rollback is disabling `/api/mobile/oauth/start`; the app falls back to WebView SSO.

## Wire contract

### Start

```http
GET /api/mobile/oauth/start?provider=oidc&redirect_uri=publicai%3A%2F%2Fauth%2Fcallback&state=<app-state>
```

Notes:

- `provider=oidc` is likely for PublicAI because the deployment uses OIDC/Cognito config. Verify the actual provider key exposed by the backend.
- Do not hardcode `google` unless the deployed OpenWebUI provider is actually direct Google.

Required validation:

- `provider` is present and enabled in OpenWebUI OAuth config.
- `redirect_uri` exactly matches an allowlisted mobile redirect URI.
- `state` is present, URL-safe, and bounded in length.
- Request is HTTPS in production.

Success response:

```http
302 Location: /oauth/{provider}/login
Set-Cookie: mobile_oauth=<signed-intent>; HttpOnly; Secure; SameSite=Lax; Max-Age=600
```

The signed intent cookie is server-only control state. It is not trusted after expiry and must be validated before use.

### Callback after provider success

For web flows, unchanged:

```http
302 Location: https://chat.publicai.co/auth
Set-Cookie: token=<OpenWebUI JWT>; ...
```

For mobile-started flows only:

```text
publicai://auth/callback?code=<single-use-mobile-code>&state=<original-app-state>
```

Error shape for mobile-started flows:

```text
publicai://auth/callback?error=<safe-code>&error_description=<safe-message>&state=<original-app-state>
```

Rules:

- `code` is not the provider authorization code.
- `code` is an opaque server-issued mobile handoff code.
- `state` is the exact original app-provided state from `/api/mobile/oauth/start`.
- Do not include JWTs, cookies, raw provider errors, provider authorization codes, refresh tokens, or PII in the callback URL.

### Exchange

```http
POST /api/mobile/oauth/exchange
Content-Type: application/json

{
  "code": "<single-use-mobile-code>",
  "state": "<original-app-state>",
  "redirect_uri": "publicai://auth/callback"
}
```

Success:

```json
{
  "token": "<OpenWebUI JWT>"
}
```

Recommended error statuses:

- `400 invalid_request` — malformed body or missing fields.
- `400 invalid_state` — state does not match the handoff record.
- `400 invalid_grant` — code is unknown or invalid.
- `409 already_used` — code was already consumed, if the implementation can distinguish this cheaply.
- `410 expired_code` — code expired, if the implementation can distinguish this cheaply.

KISS note: if Redis TTL expiration makes `expired` indistinguishable from `unknown`, returning `400 invalid_grant` is acceptable for v1. The security property is single-use + short TTL, not perfect error taxonomy.

## Storage model

Use Redis unless the actual OpenWebUI fork lacks usable Redis helpers.

### Signed mobile intent cookie

Fields:

- `provider`
- `redirect_uri`
- `state`
- `iat`
- `exp`

Requirements:

- Signed with existing server secret material, preferably `WEBUI_SECRET_KEY` or an existing signing helper.
- HTTP-only.
- Secure in production.
- Short-lived, recommended 5–10 minutes.
- Deleted after callback handling.
- Never logged raw.

### Redis handoff code

Key:

```text
mobile-oauth:<hash-or-hmac-of-code>
```

Value:

```json
{
  "token": "<OpenWebUI JWT>",
  "state": "<app-state>",
  "redirect_uri": "publicai://auth/callback",
  "provider": "oidc",
  "user_id": "<openwebui-user-id>",
  "created_at": 1234567890
}
```

Requirements:

- Generate at least 128 bits of entropy; 256 bits preferred.
- Store using a hash/keyed representation of the code, not the raw code as a log-visible value.
- TTL 60–180 seconds.
- Consume atomically with Redis `GETDEL` or Lua fallback.
- Bind to state, redirect URI, provider, and user id.

## Implementation tasks

### Task 1: Locate the deployed OpenWebUI source and provider key

Objective: Confirm the exact backend source and configured provider before patching.

Inspect:

- `chat.publicai.co` Helm values/deployment image.
- OpenWebUI fork/source repo that builds `ghcr.io/forpublicai/open-webui`.
- Existing OAuth routes/functions:
  - `backend/open_webui/main.py`
  - `backend/open_webui/utils/oauth.py`
  - `backend/open_webui/config.py`
  - `backend/open_webui/env.py`

Verification:

- Identify current deployed image tag.
- Identify provider key used for PublicAI web login, likely `oidc`.
- Identify where `OAuthManager.handle_login` redirects to provider.
- Identify where `OAuthManager.handle_callback` mints `jwt_token` and builds the final web redirect.
- Identify available Redis helper and whether it supports atomic get-delete.

### Task 2: Add mobile bridge configuration

Objective: Add small env/config values without affecting web OAuth.

Config:

- `ENABLE_MOBILE_OAUTH_BRIDGE`, default `false`.
- `MOBILE_OAUTH_REDIRECT_URIS`, default empty or `publicai://auth/callback` only in PublicAI deployment values.
- `MOBILE_OAUTH_INTENT_TTL_SECONDS`, default `600`.
- `MOBILE_OAUTH_CODE_TTL_SECONDS`, default `120`.

Helm/deploy repo additions for `chat.publicai.co`:

- Add env entries to the OpenWebUI deployment template only after backend supports them.
- Set `ENABLE_MOBILE_OAUTH_BRIDGE="true"` during rollout.
- Set `MOBILE_OAUTH_REDIRECT_URIS="publicai://auth/callback"`.

Tests:

- Defaults keep bridge disabled.
- Disabled bridge returns 404 or 403 for `/api/mobile/oauth/start` and `/api/mobile/oauth/exchange`.

### Task 3: Add signed mobile intent helpers

Objective: Implement tiny helpers for creating and verifying the mobile handoff cookie.

Create if useful:

- `backend/open_webui/utils/mobile_oauth.py`

Functions:

- `create_mobile_oauth_intent(provider, redirect_uri, state, ttl_seconds) -> str`
- `read_mobile_oauth_intent(request) -> MobileOAuthIntent | None`
- `validate_mobile_redirect_uri(redirect_uri) -> bool`
- `clear_mobile_oauth_cookie(response)` if helpful

Requirements:

- Use existing server secret material.
- Reject expired, malformed, mismatched, or unsigned payloads.
- Do not log raw state/cookie/code/token values.

Tests:

- Valid signed intent round-trips.
- Expired intent is rejected.
- Tampered intent is rejected.
- Redirect URI allowlist is exact-match only.

### Task 4: Add `/api/mobile/oauth/start`

Objective: Mark the browser session as mobile-started and enter existing web OAuth.

Behavior:

1. If bridge disabled, reject.
2. Read `provider`, `redirect_uri`, `state`.
3. Validate provider is enabled.
4. Validate redirect URI against allowlist.
5. Validate state length/shape.
6. Set `mobile_oauth` signed HTTP-only cookie.
7. Redirect to `/oauth/{provider}/login`.

Tests:

- Valid request returns 302 to `/oauth/{provider}/login` and sets secure HTTP-only cookie.
- Unknown provider returns 400/404.
- Unallowlisted redirect URI returns 400.
- Missing/oversized state returns 400.
- Disabled bridge rejects request.

### Task 5: Branch existing OAuth callback final redirect for mobile-started flows

Objective: Reuse existing provider callback logic and branch only after successful JWT creation.

Patch location:

- `OAuthManager.handle_callback(...)` after `jwt_token` is minted and before returning the current web `RedirectResponse`.

Behavior:

1. Existing provider callback validates provider result normally.
2. Existing user provisioning/access-control logic runs normally.
3. Existing OpenWebUI JWT/session token creation runs normally.
4. Existing OAuth session storage remains as-is.
5. If no valid mobile intent cookie exists, preserve existing web behavior exactly.
6. If a valid mobile intent cookie exists and provider matches:
   - generate one-time handoff code,
   - store token/state/redirect_uri/provider/user_id in Redis with TTL,
   - redirect to stored redirect URI with `code` and original `state`,
   - clear mobile intent cookie,
   - do not set the web-readable token cookie unless needed by existing code path before the branch; prefer no web token cookie on the mobile redirect response.
7. If provider auth fails and a valid mobile intent exists, redirect to mobile callback with safe error fields and state.

Tests:

- Existing web OAuth flow remains unchanged when no mobile intent cookie exists.
- Mobile OAuth success redirects to `publicai://auth/callback?code=...&state=...`.
- Mobile OAuth error redirects to `publicai://auth/callback?error=...&state=...`.
- Raw OpenWebUI JWT never appears in redirect URL.
- Provider authorization code never appears in redirect URL.
- Provider mismatch ignores or rejects the mobile intent safely.

### Task 6: Add `/api/mobile/oauth/exchange`

Objective: Convert a valid one-time handoff code into the OpenWebUI JWT over HTTPS.

Behavior:

1. If bridge disabled, reject.
2. Parse JSON body.
3. Validate `code`, `state`, and `redirect_uri` are present and bounded.
4. Hash/HMAC the submitted code into the Redis key.
5. Atomically consume the Redis record.
6. Validate stored state and redirect URI match the submitted values.
7. Return `{ "token": "<OpenWebUI JWT>" }`.

Tests:

- Valid exchange returns token.
- Reusing the same code fails.
- State mismatch returns 400.
- Redirect URI mismatch returns 400.
- Unknown code returns 400.
- Expired code fails safely.

### Task 7: Add logging redaction and minimal observability

Objective: Make auth debuggable without leaking credentials.

Requirements:

- Redact query strings and fragments from OAuth URLs in logs.
- Never log tokens, cookies, provider codes, handoff codes, raw callback URLs, or raw state.
- Log safe fields:
  - transaction phase
  - provider
  - redirect target type: `custom_scheme` / `verified_link`
  - safe error code
  - user id only where existing auth logs already do so

Optional counters/log events:

- mobile oauth start accepted/rejected
- mobile callback handoff issued
- mobile exchange success/failure by safe reason

### Task 8: Deployment and rollout

Objective: Ship without risking web OAuth.

Order:

1. Patch OpenWebUI fork with bridge disabled by default.
2. Build/publish new OpenWebUI image.
3. Update `chat.publicai.co` Helm values to use the new image with bridge disabled.
4. Deploy and verify normal web OAuth unchanged.
5. Enable bridge config:
   - `ENABLE_MOBILE_OAUTH_BRIDGE=true`
   - `MOBILE_OAUTH_REDIRECT_URIS=publicai://auth/callback`
6. Test mobile native OAuth against `chat.publicai.co`.
7. Keep WebView fallback in the app.
8. Add universal/app links later after the custom-scheme bridge is proven.

Rollback:

- Disable `ENABLE_MOBILE_OAUTH_BRIDGE` or roll back the OpenWebUI image.
- Mobile native OAuth fails and falls back to WebView SSO.
- Web OAuth should remain unaffected.

## Validation plan

Server-side:

- Unit tests for signed intent helper.
- Unit tests for Redis handoff consume-once behavior.
- Route tests for start/exchange validation.
- Callback tests proving normal web OAuth response is unchanged without mobile cookie.
- Callback tests proving mobile response contains code/state only, never JWT/provider code.
- Logging tests or review proving sensitive URL/token values are not logged.

Mobile/server integration:

1. Fresh install mobile app.
2. Confirm startup skips server connection screen and uses `https://chat.publicai.co`.
3. Tap provider button.
4. Confirm system browser/auth session opens.
5. Complete existing Cognito/Google/passkey login.
6. Confirm server redirects to app callback with `code`, not `token`.
7. Confirm app exchanges code and lands authenticated.
8. Retry same exchange code and confirm replay fails.
9. Wait past handoff-code TTL and confirm exchange fails safely.
10. Confirm WebView fallback still works while rollout is incomplete or disabled.

Web regression:

1. Visit `https://chat.publicai.co` in a browser.
2. Complete normal OAuth login.
3. Confirm redirect to `/auth` still works.
4. Confirm token/session cookie behavior matches previous production behavior.
5. Confirm logout still works.

## Open questions for implementation

- Which repository is the canonical OpenWebUI fork that builds `ghcr.io/forpublicai/open-webui`?
- What is the exact PublicAI provider key exposed by the deployed backend: `oidc`, `google`, or another value?
- Does the current Redis helper support atomic `GETDEL`, or do we need a small Lua consume helper?
- Is there an existing signing helper we should use for the mobile intent cookie, or should we add a stdlib HMAC helper using existing server secret material?
- Does the mobile `loginWithApiKey(..., authType: 'sso')` path expect exactly the same JWT shape currently stored in the web `token` cookie? The current OpenWebUI callback appears to mint that token directly, so this should be true but must be verified end-to-end.

## Deferred hardening

- Add verified HTTPS callback: `https://chat.publicai.co/mobile/auth/callback`.
- Serve `/.well-known/apple-app-site-association`.
- Serve `/.well-known/assetlinks.json`.
- Add iOS associated domains entitlement.
- Add Android verified App Links intent filter with `android:autoVerify="true"`.
- Prefer HTTPS verified callback while keeping custom scheme fallback during rollout.

The exchange model does not change when moving from custom scheme to verified links.
