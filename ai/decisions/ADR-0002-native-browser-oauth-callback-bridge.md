# ADR-0002: Use native browser OAuth with a mobile callback bridge

Date: 2026-05-17
Status: Accepted

## Context

Google passkey sign-in fails inside the embedded WebView used by the current SSO flow. The observed failure is a Google passkey challenge error, not an OpenWebUI token-capture problem. Embedded WebViews are the wrong durable surface for modern OAuth because passkeys, MFA, browser sessions, device trust, and provider anti-abuse checks are designed for system browser/auth sessions.

The app cannot safely scrape cookies from the system browser after login. The server must participate in mobile OAuth completion by redirecting back to the app and exchanging a short-lived credential for the OpenWebUI token.

Custom URL schemes are also interceptable on Android by other apps. Passing a production JWT directly in `publicai://...` is therefore not acceptable as the durable design.

## Decision

The mobile app will prefer native/system-browser OAuth for provider buttons such as Google.

Because PublicAI controls the `chat.publicai.co` OpenWebUI instance, the server-side bridge will reuse the existing OpenWebUI OAuth provider flow rather than implementing a second Google/OIDC stack. The bridge is an initiation/completion wrapper around the existing flow: mobile start records a temporary transaction, existing OpenWebUI OAuth validates Google and resolves the user, then the final successful redirect is changed to a mobile handoff when the flow was started by the native app.

The mobile contract is:

- app callback URI: `publicai://auth/callback`
- OAuth start endpoint: `/api/mobile/oauth/start`
- OAuth exchange endpoint: `/api/mobile/oauth/exchange`
- callback success shape: `publicai://auth/callback?code=<single-use-code>&state=<state>`
- callback error shape: `publicai://auth/callback?error=<code>&error_description=<safe-message>&state=<state>`

The app validates callback scheme/host/path and state before accepting the callback. Production flow uses a short-lived single-use `code` and exchanges it over HTTPS for the OpenWebUI JWT. Raw token-in-callback is not the production path.

Server implementation requirements:

- `/api/mobile/oauth/start` validates provider, redirect URI, and app state, creates a short-lived mobile OAuth transaction, then redirects into the existing OpenWebUI provider OAuth start path.
- The existing OpenWebUI OAuth callback remains the source of truth for provider verification, user provisioning, policy checks, and OpenWebUI JWT/session creation.
- At the final post-login redirect decision point, mobile-associated flows receive a server-issued handoff code instead of the normal web redirect.
- `/api/mobile/oauth/exchange` atomically consumes the handoff code and returns `{ "token": "<OpenWebUI JWT>" }` over HTTPS.
- Handoff codes must be opaque, high-entropy, stored hashed, bound to transaction/state/redirect URI/user/provider, short-lived, and single-use.
- Normal web OAuth behavior must remain unchanged for flows that did not start through `/api/mobile/oauth/start`.

Platform behavior:

- iOS uses `ASWebAuthenticationSession` with `prefersEphemeralWebBrowserSession = false` and a scene-aware presentation anchor.
- Android launches the system browser with `ACTION_VIEW` and receives `publicai://auth/callback` through a constrained intent filter.
- Android persists minimal pending OAuth state so an orphan callback after process death can be consumed on app resume.

Hardening posture:

- Current callback allowlist includes `publicai://auth/callback` for the initial TestFlight/mobile bridge.
- The server allowlist should be designed to also support a future verified HTTPS callback such as `https://chat.publicai.co/mobile/auth/callback`.
- Universal links/app links should be added after the bridge is proven by serving `/.well-known/apple-app-site-association` and `/.well-known/assetlinks.json`, adding app entitlements/verified intent filters, then preferring the HTTPS callback while keeping the custom scheme as a rollout fallback.
- The code-exchange principle does not change when moving from custom schemes to verified links.

The existing WebView SSO route remains as a fallback until the server bridge endpoint is deployed and validated. WebView navigation logs must redact query and fragment values because OAuth URLs can carry sensitive codes/state.

## Consequences

Benefits:

- Supports passkey-first Google auth and future MFA/provider flows more reliably.
- Aligns with OAuth provider expectations by using system browser/auth surfaces.
- Avoids scraping browser cookies or relying on embedded WebView localStorage timing.
- Keeps a controlled fallback path while the server bridge is rolled out.
- Reduces token leakage risk by exchanging a short-lived code over HTTPS rather than putting JWTs in custom-scheme URLs.
- Keeps OpenWebUI as the single OAuth authority instead of duplicating provider auth logic in a separate mobile-only service.

Tradeoffs:

- Requires server-side mobile OAuth bridge endpoints before end-to-end native OAuth can succeed.
- Android custom schemes remain weaker than verified app links; universal/app links are the planned hardening step after the initial bridge contract is proven.
- The fallback WebView path remains temporarily, so two auth paths must be maintained during rollout.

## Alternatives considered

### Keep embedded WebView SSO and improve token capture

Rejected as the durable fix. The failure is in Google/passkey challenge handling inside an embedded browser, not merely token capture after redirect.

### Change Google/OAuth server config to avoid passkey-first prompts

Deferred as a tactical unblock only. It may reduce failures short-term but is brittle, provider-dependent, and degrades the auth experience instead of supporting modern auth properly.

### Put the OpenWebUI JWT directly in the custom-scheme callback

Rejected for production. On Android another app can register the same custom scheme and intercept the callback. State validation prevents injection, not exfiltration. Use a short-lived single-use code plus HTTPS exchange instead.

### Start with universal links/app links only

Deferred. Universal links/app links are stronger against scheme hijacking but require domain association and entitlement setup. The initial bridge uses custom scheme plus code exchange; app links can harden the callback later without changing the server code-exchange principle.

### Build a separate mobile-only Google OAuth service

Rejected. PublicAI controls the OpenWebUI instance, so provider verification, user provisioning, access policy, and token minting should stay in the existing OpenWebUI OAuth path. A parallel service would duplicate sensitive auth logic and create drift between web and mobile login behavior.

## Links

- `ai/architecture.md`
- `ai/tasks/native-oauth-callback-bridge.md`
- `ai/tasks/openwebui-mobile-oauth-server-bridge.md`
- `lib/core/auth/mobile_oauth_bridge.dart`
- `lib/core/auth/native_browser_auth.dart`
- `ios/Runner/NativeBrowserAuthBridge.swift`
- `android/app/src/main/kotlin/ai/public/app/MainActivity.kt`
