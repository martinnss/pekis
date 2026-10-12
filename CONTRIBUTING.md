# Contributing to Pekis

Thanks for taking a look. Bug reports, fixes, new date ideas and doc improvements are all welcome. For anything bigger than a small fix, open an issue first so we can agree on the approach before you spend time on it.

By taking part you agree to follow the [Code of Conduct](CODE_OF_CONDUCT.md).

## Setup

1. Fork the repo and clone your fork.
2. Copy `.env.example` to `.env` and fill in a team ID, bundle ID and CloudKit container that you control.
3. Open `Pekis.xcodeproj` and build with `⌘B`.

Unit tests and most UI work need no signing. Anything that touches CloudKit (pairing, notes, photos) needs a signed build on a simulator or device that is logged into iCloud. See [DEVELOPMENT.md](DEVELOPMENT.md) for details and the `xcodebuild` commands.

## How the code is organized

Features use MVVM:

- **Views** only describe UI. No business logic.
- **ViewModels** are `@MainActor` `ObservableObject`s that own feature state.
- **Models** are plain structs with explicit CloudKit mappings.
- **Services** handle CloudKit, sharing, retries and game sessions, and sit behind protocols so they can be mocked.

[ARCHITECTURE.md](ARCHITECTURE.md) has the full picture, and [docs/ENGINEERING_NOTES.md](docs/ENGINEERING_NOTES.md) explains why some of the harder parts look the way they do.

## Style

- Use `async/await`. Avoid completion handlers for new code.
- No force unwraps (`!`) and no force casts.
- Booleans read like statements: `isLoading`, `hasError`.
- Comments explain why, not what. Don't leave history in comments ("fixed bug X"). Git has that.
- Keep lines under 140 characters.

SwiftLint enforces most of this (`brew install swiftlint`). The project has zero warnings, so please keep it that way.

## Tests

Unit tests live in `PekisTests/` and use Swift Testing (some older ones use XCTest). Run them with `⌘U`. CI runs the same tests on every pull request.

If you change logic, add a test for it. If you change how Word Search is generated or how a session starts, check that the same seed still gives the same board.

## Pull requests

1. Branch from `main` (for example `fix/invite-link-crash`).
2. Make small, focused commits with clear messages.
3. Open a pull request against `main` and fill in the template.
4. Make sure CI is green.

Good first issues are labeled `good first issue`.
