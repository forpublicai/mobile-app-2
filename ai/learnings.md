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
- The real iOS app for TestFlight is the Flutter workspace `ios/Runner.xcworkspace` with scheme/target `Runner`; root-level standalone Xcode projects are not the shipping app and should not be archived.
- Flutter iOS CI must run `flutter pub get` before Xcode resolves `ios/Flutter/Generated.xcconfig`, and must run `cd ios && pod install` before building targets that reference CocoaPods xcconfig files.
- TestFlight CI for this repo uses GitHub Actions (`.github/workflows/testflight.yml`) rather than Xcode Cloud. It installs signing assets from GitHub Secrets, builds a signed IPA, and uploads to TestFlight on `main` pushes that touch app-impacting paths.
- TestFlight Release/Profile signing is manual App Store distribution signing for `com.publicai.chat`, `com.publicai.chat.ShareExtension`, and `com.publicai.chat.ConduitWidget`; extension bundle IDs must remain prefixed by the parent app bundle ID.
- GitHub Actions macOS/Xcode 26 runners currently require a CocoaPods `xcodeproj` compatibility shim for project `objectVersion = 70` until the gem supports that object version natively.
