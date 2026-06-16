# Changelog

All notable changes to this project will be documented in this file.

The project did not previously maintain a changelog in-repo. The entries below establish the current documented baseline and future changes should extend this file.

## [Unreleased]

### Added

- Home Screen and Lock Screen countdown widget ("Together Countdown") that counts the days until the couple reunites, with five hand-tuned themes, a progress ring, and per-widget personalization (custom label, optional personal date for solo use) via an App Intents configuration
- App Group data sharing so the widget reads the couple's reunion date without touching CloudKit; the app refreshes widget timelines whenever the couple changes
- Public repository governance and support documents, including Code of Conduct, Security Policy, Privacy guide, Development guide, and GitHub issue and pull request templates

## [1.1.0] - 2026-05-31

### Added

- SwiftUI iOS application organized around feature-based MVVM
- CloudKit-backed pairing, shared couple state, love notes, shared moments, and This or That answers
- Deterministic Word Search gameplay with lightweight Google Apps Script matchmaking coordination
- Local content features such as Date Roulette and Topic Generator
- SwiftLint configuration, unit tests, UI test target, and GitHub Actions build-and-test workflow