# Pekis: AI Assistant Guidelines

These notes apply to AI coding assistants working in this repository. Human contributors should read [CONTRIBUTING.md](../CONTRIBUTING.md) and [ARCHITECTURE.md](../ARCHITECTURE.md).

## Architecture

- Feature-based MVVM. Views are declarative and hold no business logic.
- ViewModels are `@MainActor final class` types conforming to `ObservableObject`, exposing state through `@Published`.
- Models are value types (`struct`) and conform to `Codable`/`Identifiable` where it makes sense.
- Services sit behind protocols (see `CloudKitServiceProtocol`) and are injected through initializers.
- Prefer `async/await` and structured concurrency over closures and Combine for new code.

## Style

- Follow `.swiftlint.yml`: no force unwrapping, no force casts, lines under 140 characters, no trailing whitespace.
- Use full names (no abbreviations); booleans read like assertions (`isLoading`, `hasError`).
- Use `[weak self]` in escaping closures; mark classes `final` unless inheritance is needed.
- Use `PekisLogger`/`OSLog` rather than `print()`.
- Comment the *why*, not the *what*. Do not leave change-log style comments in code (history belongs in git).

## Quality bar

- Code must build and unit tests (`PekisTests`) must pass before a change is considered done.
- Add or update tests for ViewModel and service logic.
- Support Dynamic Type and VoiceOver, and use SF Symbols where an icon is needed.
- Never commit secrets or personal identifiers; local configuration lives in the untracked `.env`.
