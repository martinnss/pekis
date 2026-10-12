# Development Guide

How to build, test and work on Pekis locally.

## Prerequisites

- macOS with Xcode 16 or newer
- An Apple Developer team if you want to run CloudKit-backed flows on a real device or a signed simulator
- An iCloud account signed in on the device or simulator for pairing, sharing, and CloudKit testing
- Homebrew if you want to install optional local tooling such as SwiftLint

## Open the Project

1. Clone the repository.
2. Copy `.env.example` to `.env` and replace the values with identifiers you control.
3. Open `Pekis.xcodeproj` in Xcode.
4. Select the `Pekis` scheme.
5. Choose a simulator or device that matches your installed Xcode runtime.

## Signing and CloudKit Setup

CloudKit-backed flows require valid signing and an iCloud-enabled app identifier.

The repository reads these values from `.env`:

- Bundle identifier: an app identifier you control for your fork
- iCloud container: a CloudKit container you control for your fork
- Development team: your Apple Developer Team ID

If you are running your own fork, set those values in `.env` instead of editing multiple project files.

After changing identifiers:

1. Enable the iCloud and CloudKit capabilities in Xcode for your app target.
2. Create or select the matching CloudKit container in your Apple Developer account.
3. Confirm the app can access that container on a signed-in device or simulator.

## Running things locally

Build:

```bash
xcodebuild build \
  -project Pekis.xcodeproj \
  -scheme Pekis \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO
```

Unit tests (no signing or iCloud needed). If you have several simulators with the same name, use the UDID from `xcrun simctl list devices`:

```bash
xcodebuild test \
  -project Pekis.xcodeproj \
  -scheme Pekis \
  -destination 'platform=iOS Simulator,id=<SIMULATOR_UDID>' \
  -only-testing:PekisTests \
  CODE_SIGNING_ALLOWED=NO
```

Lint (`brew install swiftlint` first):

```bash
swiftlint
```

To look at the UI on an unsigned simulator build, launch the app with the environment variable `PEKIS_SKIP_CLOUDKIT=1`. It skips CloudKit and goes straight to onboarding. Creating a couple still needs a signed build.

## CloudKit notes

- `PekisApp` skips CloudKit setup under unit tests (and with `PEKIS_SKIP_CLOUDKIT=1`) because an unsigned build has no entitlements and `CKContainer` would crash.
- `CloudKitService` is split by feature: `CloudKitService.swift` (setup and couples), `+Content` (notes, answers, moments), `+Sharing` (share links and subscriptions), `+WordSearch`, and `+Account` (iCloud account changes).
- Test pairing and sharing with two real iCloud accounts. Unit tests can't cover that.
- Word Search shared play uses `CloudKitCoupleMatchmakingService` and a short-lived `WordSearchSession` record. `SimulationMatchmakingService` is the local stand-in for solo play.

## Before opening a pull request

- The `Pekis` scheme builds and the unit tests pass.
- SwiftLint reports nothing.
- If you touched onboarding, sharing or shared data, try it on a device or simulator signed into iCloud.
- Update the README, ARCHITECTURE or PRIVACY if your change alters them.
