---
applyTo: '**'
---

# Mandatory Rules for GitHub Copilot

## 1. MVVM Architecture - Always Required

- **NEVER** put business logic in Views. Views are strictly for UI declaration.
- **ALWAYS** create a corresponding ViewModel for each View that requires state management.
- **ALWAYS** make ViewModels `final class` conforming to `ObservableObject`.
- **ALWAYS** use `@Published` properties for state that the View observes.
- **ALWAYS** use `@StateObject` when the View owns the ViewModel.
- **ALWAYS** use `@ObservedObject` when the ViewModel is passed in.
- **ALWAYS** keep Models as immutable structs conforming to `Codable` and `Identifiable`.

## 2. Build Verification - Always Required

- **ALWAYS** ensure the code compiles after making changes.
- **ALWAYS** verify imports are correct and complete.
- **ALWAYS** check that all referenced types and methods exist.
- **ALWAYS** ensure proper initialization of all properties.
- **NEVER** leave incomplete implementations or placeholder code that would break the build.

## 3. SwiftLint Compliance - Always Required

### Formatting
- **NEVER** leave trailing whitespace on any line.
- **ALWAYS** limit vertical whitespace to exactly one empty line.
- **ALWAYS** keep line length under 140 characters.
- **ALWAYS** use consistent indentation (4 spaces).

### Safety
- **NEVER** use force unwrapping (`!`). Always use `if let`, `guard let`, or nil coalescing (`??`).
- **NEVER** use force cast (`as!`). Always use `as?` with proper handling.
- **NEVER** use implicitly unwrapped optionals unless required by UIKit/AppKit.
- **ALWAYS** use `[weak self]` in closures to prevent retain cycles.

### Naming
- **ALWAYS** use UpperCamelCase for types (classes, structs, enums, protocols).
- **ALWAYS** use lowerCamelCase for properties, methods, and variables.
- **ALWAYS** prefix boolean properties with `is`, `has`, `should`, `can`, or `will`.
- **NEVER** use abbreviations in names.

### Code Quality
- **ALWAYS** remove unused code and imports.
- **NEVER** use `print()` statements in production code; use proper logging.
- **ALWAYS** handle all switch cases explicitly or use `@unknown default`.
- **ALWAYS** use `async/await` over completion handlers for new asynchronous code.
- **ALWAYS** mark classes as `final` unless inheritance is explicitly needed.
