# Contributing to Pekis 🐧

First off, thank you for considering contributing to Pekis! It's people like you that make the open source community such an amazing place to learn, inspire, and create. 

Whether you're fixing a bug, designing a new feature, or improving the documentation, we welcome your help.

## 🤝 Code of Conduct

This project and everyone participating in it is governed by the [Contributor Covenant](https://www.contributor-covenant.org). By participating, you are expected to uphold this code. Please report unacceptable behavior to the project maintainers.

### Our Pledge

In the interest of fostering an open and welcoming environment, we as contributors and maintainers pledge to making participation in our project and our community a harassment-free experience for everyone, regardless of age, body size, disability, ethnicity, sex characteristics, gender identity and expression, level of experience, education, socio-economic status, nationality, personal appearance, race, religion, or sexual identity and orientation.

---

## 🚀 Getting Started

1.  **Fork the repository** on GitHub.
2.  **Clone your fork** locally:
    ```bash
    git clone https://github.com/your-username/Pekis.git
    cd Pekis
    ```
3.  **Create your local environment file** by copying `.env.example` to `.env` and replacing the team ID, bundle identifier, and CloudKit container with values you control.
4.  **Open the project** in Xcode:
    ```bash
    open Pekis.xcodeproj
    ```
5.  **Build the project** (`Cmd + B`) to ensure everything is set up correctly.

If you are changing CloudKit-backed flows, test with a simulator or device that is signed into iCloud and has the required signing entitlements configured in Xcode.

---

## 🧭 Project Framing

When writing docs, PR descriptions, or code comments, keep the technical framing aligned with the implementation in this repo.

*   **Persistent shared data:** CloudKit stores couple state, notes, answers, and shared moments.
*   **Offline behavior:** The app uses selective local caching for some shared state; it is not a blanket offline-first system.
*   **Word Search:** The game uses deterministic board generation plus CloudKit session coordination; it is not a peer-to-peer or live shared-state multiplayer engine.
*   **Waiting-room UX:** Shared gameplay now shows local readiness, partner readiness, and a scheduled start before the puzzle begins.
*   **Automation:** GitHub Actions currently provides build-and-test verification, not a full deployment pipeline.

---

## 💻 Coding Standards

To maintain a high-quality codebase, we follow strict architectural and stylistic guidelines. Please review these before submitting a PR.

### Architecture: MVVM
*   **Views** are strictly declarative and should not contain business logic.
*   **ViewModels** are `@MainActor` `ObservableObject` types that handle state and feature logic.
*   **Models** are immutable structs and should keep storage mappings explicit.
*   **Services** own CloudKit, sharing, game-session coordination, and other side effects.
*   **Dependency Injection** should prefer protocols and constructor injection for ViewModels.

### Swift Style Guide
*   **Modern Concurrency**: Use `async/await` and `Task`. Avoid completion handlers or Combine for simple async tasks.
*   **Naming**:
    *   Types: `UpperCamelCase`
    *   Properties/Functions: `lowerCamelCase`
    *   Booleans: `isLoading`, `hasError` (assertion style)
*   **Safety**: **NO Force Unwrapping** (`!`). Always use `if let`, `guard let`, or `??`.
*   **Formatting**:
    *   No trailing whitespace.
    *   One empty line between functions.
    *   Line length < 140 characters.

### Linting
We use **SwiftLint** to enforce these rules.
1.  Install SwiftLint: `brew install swiftlint`
2.  The project is configured to run the linter automatically during the build phase.
3.  **Zero Warnings Policy**: Please fix all linting warnings before pushing.

---

## 🧪 Running Tests

We believe in shipping confidence.

1.  **Unit Tests**:
    *   Located in `PekisTests/`.
    *   Run with `Cmd + U` in Xcode.
    *   The repository currently uses both **Swift Testing** and **XCTest**.
    *   The strongest coverage today is around model-to-CloudKit mapping, cache behavior, HomeViewModel logic, and word-search generation/selection behavior.
2.  **UI Tests**:
    *   Located in `PekisUITests/`.
    *   Current coverage is lightweight launch validation.
    *   Add or expand UI coverage if your change affects onboarding or core user flows.

GitHub Actions runs the same build-and-test verification on pushes to `main` and pull requests, so local validation should match that bar before you open a PR.

If you modify shared-play flows, validate both the deterministic puzzle seed path and the CloudKit waiting/countdown state before opening a PR.

**Before submitting a PR, please ensure all tests pass.**

---

## 📥 Pull Request Process

1.  Create a new branch for your feature or fix:
    ```bash
    git checkout -b feature/amazing-new-feature
    ```
2.  Commit your changes with clear, descriptive messages.
3.  Push your branch to your fork.
4.  Open a Pull Request against the `main` branch of the original repository.
5.  **PR Checklist**:
    *   [ ] My code follows the style guidelines of this project.
    *   [ ] I have performed a self-review of my own code.
    *   [ ] I have documented non-obvious decisions where the code alone is not enough.
    *   [ ] I have added tests that prove my fix is effective or that my feature works.
    *   [ ] New and existing unit tests pass locally with my changes.

---

## 💡 Need Ideas?

Check out the **Issues** tab! We label beginner-friendly tasks with `good first issue`.

Happy Coding! 🚀
