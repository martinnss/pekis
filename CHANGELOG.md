# Changelog

All notable changes to this project are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Changed

- CI now fails when the build or tests fail, runs the `PekisTests` unit tests through the shared `Pekis` scheme, and lints with SwiftLint
- Consolidated the AI-assistant guidelines into `.github/copilot-instructions.md`
- App icon asset catalog reduced to a single compressed icon; removed an unused dashboard image

### Fixed

- The shared `Pekis` scheme is now configured for the test action, so `Cmd + U` and `xcodebuild test` run the unit tests

## [1.1.4] - 2026-07-01

Cumulative release covering everything since 1.1.0 (versions 1.1.1 to 1.1.3 were internal builds).

### Added

- Home Screen and Lock Screen countdown widget ("Together Countdown") that counts the days until the couple reunites, with five themes, a progress ring, and per-widget personalization (custom label, optional personal date for solo use) via an App Intents configuration
- App Group data sharing so the widget reads the reunion date without touching CloudKit; the app refreshes widget timelines whenever the couple changes
- "Cozy" light redesign with a code-drawn animated Peki mascot duo and a shared design system
- Public repository governance and support documents: Code of Conduct, Security Policy, Privacy guide, Development guide, and GitHub issue and pull request templates

### Changed

- Legacy CloudKit container identifiers are externalized into the untracked `.env` file; shared Xcode schemes are tracked

### Fixed

- CloudKit share acceptance, disconnect flow, settings, and the loading gate
- Couple share acceptance is reliable across cold launch and multiple scenes
- Onboarding rewires the CloudKit service when pairing completes, and the join instructions are clearer
- App Group access is guarded to silence the `CFPrefs` warning
- Falls back to the default CloudKit container when the container build variable is unresolved

## [1.1.0] - 2026-05-31

### Added

- SwiftUI iOS application organized around feature-based MVVM
- CloudKit-backed pairing, shared couple state, love notes, shared moments, and This or That answers
- Deterministic Word Search gameplay with CloudKit-backed session coordination (ready state, synchronized countdown, winner detection)
- Local content features such as Date Roulette and Topic Generator
- SwiftLint configuration, unit tests, UI test target, and GitHub Actions workflow
