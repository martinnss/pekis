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
3.  **Open the project** in Xcode:
    ```bash
    open Pekis.xcodeproj
    ```
4.  **Build the project** (`Cmd + B`) to ensure everything is set up correctly.

---

## 💻 Coding Standards

To maintain a high-quality codebase, we follow strict architectural and stylistic guidelines. Please review these before submitting a PR.

### Architecture: MVVM
*   **Views** are strictly declarative and should not contain business logic.
*   **ViewModels** (`ObservableObject`) handle all state and logic.
*   **Models** are immutable structs.

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
    *   Focus on testing ViewModels and Services.
2.  **UI Tests**:
    *   Located in `PekisUITests/`.
    *   Run specific UI tests if you are modifying user flows.

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
    *   [ ] I have commented my code, particularly in hard-to-understand areas.
    *   [ ] I have added tests that prove my fix is effective or that my feature works.
    *   [ ] New and existing unit tests pass locally with my changes.

---

## 💡 Need Ideas?

Check out the **Issues** tab! We label beginner-friendly tasks with `good first issue`.

Happy Coding! 🚀
