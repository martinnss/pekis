# Development Guide

This guide describes how to work on Pekis locally and how the current repository is wired.

## Prerequisites

- macOS with a recent Xcode installation that can open `Pekis.xcodeproj`
- An Apple Developer team if you want to run CloudKit-backed flows on a real device or a signed simulator
- An iCloud account signed in on the device or simulator for pairing, sharing, and CloudKit testing
- Homebrew if you want to install optional local tooling such as SwiftLint

## Project Snapshot

The current repository is an iOS SwiftUI app with:

- Feature-based MVVM structure
- CloudKit for persistent shared couple data
- A selective local cache for some shared text features
- CloudKit-backed Word Search session coordination for shared puzzle starts
- A waiting-room UX that surfaces player readiness and a synced scheduled start before the game begins
- GitHub Actions CI that runs `xcodebuild build` and `xcodebuild test` on the `Pekis` scheme

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

## Local Validation Commands

Build the app locally:

```bash
xcodebuild build \
  -project Pekis.xcodeproj \
  -scheme Pekis \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO
```

Run tests locally:

```bash
xcodebuild test \
  -project Pekis.xcodeproj \
  -scheme Pekis \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO
```

Run SwiftLint if it is installed:

```bash
./scripts/run_swiftlint.sh
```

Install SwiftLint with Homebrew if needed:

```bash
brew install swiftlint
```

## CloudKit Development Notes

- `PekisApp` skips CloudKit setup when tests run with `CODE_SIGNING_ALLOWED=NO`, because test environments do not have the required entitlements
- Share acceptance is handled in `Pekis/App/PekisApp.swift` and uses the configured CloudKit container directly
- `CloudKitService` owns setup, zone creation, existing-couple discovery, sharing, and subscription refresh behavior
- Pairing and sharing flows should be tested with iCloud enabled, not only through simulator-only unit tests

## Shared Word Search Session Notes

- Word Search shared play now uses `CloudKitCoupleMatchmakingService`
- The active game is represented as a short-lived `WordSearchSession` record in the couple's shared CloudKit zone
- Both devices generate the board from the stored session seed and start from the same scheduled countdown time
- The waiting screen should show local readiness, partner readiness, and the synced countdown state while both players are joining
- `SimulationMatchmakingService` still exists as a local fallback when paired CloudKit context is unavailable

Focused validation for this slice:

```bash
xcodebuild test \
  -project Pekis.xcodeproj \
  -scheme Pekis \
  -destination 'platform=iOS Simulator,id=<SIMULATOR_UDID>' \
  CODE_SIGNING_ALLOWED=NO \
  -only-testing:PekisTests/WordSearchTests \
  -only-testing:PekisTests/WordSearchSessionTests
```

## Repository Structure

Key directories:

- `Pekis/App`: app entry point and lifecycle integration
- `Pekis/Core`: models, services, utilities, and shared content
- `Pekis/Features`: onboarding, dashboard, and activity features
- `PekisTests`: unit and model logic coverage
- `PekisUITests`: UI launch coverage
- `.github/workflows`: CI automation

## Before Opening a Pull Request

- Build the `Pekis` scheme successfully
- Run the relevant tests for your change
- Run SwiftLint if available in your environment
- Re-test CloudKit flows on a signed-in device or simulator if you changed onboarding, sharing, or shared-data behavior
- Update `README.md`, `ARCHITECTURE.md`, `PRIVACY.md`, or `SECURITY.md` if your change alters the public architecture or data-handling story