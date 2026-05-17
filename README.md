<h1 align="center">Public AI</h1>

<p align="center">
  <img
    src="assets/icons/icon.png"
    alt="Public AI icon"
    width="96"
    height="96"
  />
</p>

<p align="center">
  <strong>The native Open WebUI client for iOS and Android.</strong>
</p>

<p align="center">
  <img
    alt="Latest Release"
    src="https://img.shields.io/github/v/release/your-org/public-ai-mobile?display_name=tag&color=0A84FF"
  />
  <img
    alt="GitHub all downloads"
    src="https://img.shields.io/github/downloads/your-org/public-ai-mobile/total?style=flat-square&label=Downloads&logo=github&color=111827"
  />
  <img
    alt="License: GPL-3.0"
    src="https://img.shields.io/badge/License-GPL%203.0-16A34A"
  />
</p>

<p align="center">
  <a href="#why-public-ai">Why Public AI</a> |
  <a href="#feature-snapshot">Feature Snapshot</a> |
  <a href="#screenshots">Screenshots</a> |
  <a href="#quickstart">Quickstart</a> |
  <a href="#build-from-source">Build from Source</a> |
  <a href="#architecture">Architecture</a>
</p>

<p align="center">
  <img
    src="docs/screenshots/conduit-demo.gif"
    alt="Public AI demo"
    width="360"
  />
</p>

## Why Public AI

Open WebUI is excellent on the desktop, but mobile usually breaks down at the
edges: authentication, streaming stability, sharing content into a prompt, and
working quickly from the home screen. Public AI is built to close that gap with a
native client that respects self-hosted deployments and still feels polished
enough for daily use.

## Feature Snapshot

| Area | Included |
| --- | --- |
| Chat | Real-time streaming, model selection, temporary chats, conversation search, and folder management |
| AI workflows | File and image uploads, re-attaching previously uploaded server files, multimodal prompts, server-side tools, saved prompts with variables, model-specific toggle filters, and optional web search or image generation when supported by your server |
| Authentication | Username and password, LDAP, JWT, custom headers, SSO/OAuth, and reverse proxy login flows |
| Productivity | Notes with autosave, pinning, AI-generated titles, AI enhancement, audio attachments, channels with threads and reactions when enabled by the server, and sharing from other apps |
| Rendering | Syntax-highlighted code, LaTeX, Mermaid, Chart.js, citations, follow-up suggestions, reasoning blocks, tool-call details, and code execution rendering |
| Mobile UX | Voice input, full voice-call mode, home screen widgets, app quick actions, clipboard image paste, haptics, and adaptive Material/Cupertino UI |
| Personalization | Light, dark, and system themes plus a localized interface across 10 supported locales |
| Privacy | Native secure storage, no third-party analytics or ads, and no developer-operated backend relaying your data |

## Built for Self-Hosted Reality

- Handles direct Open WebUI sign-in as well as OAuth and SSO providers exposed
  by your deployment.
- Works with reverse proxy setups such as `oauth2-proxy`, Authelia,
  Authentik, Pangolin, and Cloudflare Tunnel by capturing the right cookies and
  session state on-device.
- Supports custom headers during connection setup for environments that depend
  on keys like `X-API-Key`, `Authorization`, or organization routing headers.
- Keeps credentials in Keychain or Keystore instead of plain-text local
  storage.
- Uses WebSocket-backed streaming for fast token-by-token responses and better
  long-running chat reliability.
- Surfaces optional server capabilities such as notes, channels, web search,
  and image generation only when your Open WebUI deployment exposes them.

## Assistant Output That Holds Up on Mobile

Public AI renders more than plain chat bubbles. The app includes native Flutter
surfaces for:

- syntax-highlighted code blocks with copy and preview affordances
- Mermaid diagrams and Chart.js embeds
- LaTeX and math rendering
- expandable reasoning, tool-call, and code-execution sections
- inline citations, source cards, and follow-up suggestions

## Platform Integrations

- Home screen widgets on iOS and Android with new chat, microphone, camera,
  photos, and clipboard entry points
- App quick actions for starting a new chat or jumping straight into voice call
- iOS App Intents and Shortcuts for opening chat, sending text, URLs, images,
  and starting a voice call
- Share-sheet ingestion and clipboard image paste to move content into a prompt
  without manual file juggling

## Screenshots

| Chat | Models | Navigation | Settings |
| --- | --- | --- | --- |
| <img src="docs/screenshots/1.png" alt="Public AI conversation screen" width="200" /> | <img src="docs/screenshots/2.png" alt="Public AI model selection screen" width="200" /> | <img src="docs/screenshots/3.png" alt="Public AI navigation screen" width="200" /> | <img src="docs/screenshots/4.png" alt="Public AI settings screen" width="200" /> |

## Quickstart

If you just want to use Public AI, install it from the App Store or Google Play,
connect it to your Open WebUI server, and sign in with the auth flow your
deployment already exposes.

1. Launch Public AI.
2. Enter the base URL for your Open WebUI instance.
3. Add any required custom headers.
4. Sign in with username and password, LDAP, JWT, SSO, or proxy auth.
5. Pick a model and start chatting.

Features such as channels, notes, web search, image generation, and toggle
filters appear when they are available on the connected server.

## Build from Source

### Requirements

- A recent Flutter SDK with Dart `3.8` or newer
- Java 17 for Android builds
- Android 7.0+ (API 24) or iOS 16.0+
- An Open WebUI instance for normal usage
- Xcode for iOS builds or Android Studio / Android SDK for Android builds

### Run locally

```bash
git clone https://github.com/your-org/public-ai-mobile.git
cd public-ai-mobile
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d ios
# or
flutter run -d android
```

### Developer checks

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart run custom_lint
flutter test
```

### Release builds

```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release
```

## Localization

Public AI currently ships localized UI strings for English, German, Spanish,
French, Italian, Korean, Dutch, Russian, Simplified Chinese, and Traditional
Chinese.

## Architecture

Public AI is a Flutter application organized around feature modules and shared
platform services. It uses Riverpod 3 with code generation for state management
and GoRouter for navigation, with persistent local storage and secure
credential handling built into the core layer.

### Stack

- Flutter for the UI layer
- Riverpod 3 and `riverpod_generator` for state and dependency wiring
- GoRouter for navigation
- Dio plus socket transport for API and streaming
- Hive and shared preferences for local persistence
- Flutter Secure Storage for credentials

### Project layout

```text
lib/
  core/         auth, routing, models, persistence, platform services
  features/
    auth/       server setup, login, SSO, and proxy auth
    chat/       conversations, attachments, tools, streaming, voice call
    channels/   channel browsing and messaging
    navigation/ chat shell, drawer, and responsive navigation
    notes/      note editor and AI-assisted note workflows
    profile/    theme, preferences, and app customization
    prompts/    prompt helpers and prompt variable UI
    tools/      tool integration surfaces
  shared/       reusable widgets, theme tokens, and task infrastructure
```

<details>
<summary>Platform permissions</summary>

- Android asks for internet, microphone, camera, and file access for chat,
  voice input, attachments, and image capture.
- iOS requests microphone, speech recognition, camera, and photo library access
  for voice and attachment workflows.

</details>

<details>
<summary>Troubleshooting</summary>

- If streaming stalls, verify WebSocket support is enabled on your Open WebUI
  deployment. The upstream guidance requires
  `ENABLE_WEBSOCKET_SUPPORT="true"`.
- If iOS device builds fail, run `cd ios && pod install` and confirm signing is
  configured in Xcode.
- If Android builds fail, confirm your Java and Gradle toolchain, then try
  `flutter clean`.
- If code generation fails, rerun
  `dart run build_runner build --delete-conflicting-outputs`.

</details>

## Security and Privacy

- Preferences stay on-device and credentials use platform secure storage.
- Public AI does not include third-party analytics or advertising SDKs.
- Diagnostic logging is local and transient, and Public AI does not relay your
  data through developer-operated backend infrastructure.
- Additional details are documented in [PRIVACY_POLICY.md](PRIVACY_POLICY.md).

## Contributing

Public AI is actively developed and feedback is welcome.

- Report bugs in [GitHub Issues](https://github.com/your-org/public-ai-mobile/issues).
- Start product and feature discussions in
  [GitHub Discussions](https://github.com/your-org/public-ai-mobile/discussions).
- Share deployment notes, questions, or ideas in
  [GitHub Discussions](https://github.com/your-org/public-ai-mobile/discussions).

At the moment, unsolicited pull requests are not the primary contribution path.
Open an issue or discussion first so changes can line up with the current
roadmap.

## Enterprise and White-Label

If you need private distribution, internal deployment support, or a custom
enterprise/white-label build, open a discussion or contact the maintainer
through the repository.

## License

Public AI is released under the [GPL-3.0 License](LICENSE).

Public AI is an independent client and is not affiliated with Open WebUI.
