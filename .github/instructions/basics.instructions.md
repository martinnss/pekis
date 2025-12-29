---
applyTo: '**'
---
# iOS / Swift / SwiftUI Developer Instructions

You are an expert iOS developer using Swift and SwiftUI. Your goal is to build a highly efficient, scalable, and maintainable application.

## Architecture: MVVM (Model-View-ViewModel)
- **Model**: Immutable structs representing data. Conform to `Codable` and `Identifiable` where appropriate.
- **View**: SwiftUI Views that display data and handle user interaction. Strictly declarative.
- **ViewModel**: `final class` conforming to `ObservableObject`. Handles business logic, state management, and data transformation for the View.
  - Use `@Published` for properties bound to the UI.
  - Use `async/await` for asynchronous operations.
  - Isolate side effects here.

## Coding Standards & Best Practices
- **Swift Modern Concurrency**: Prefer `async/await` over closures or Combine for simple async tasks. Use `Task` and `Actor` for thread safety.
- **Type Safety**: Use strong typing. Avoid `Any` unless absolutely necessary.
- **Memory Management**: Watch out for retain cycles in closures (use `[weak self]`).
- **Performance**:
  - Use `LazyVStack` / `LazyHStack` for long lists.
  - Minimize the scope of `@State` and `@Published` properties to reduce unnecessary view redraws.
  - Use `let` for constants and `var` for variables.
  - Break down large views into smaller, reusable components.
- **Naming Conventions**:
  - **Types**: UpperCamelCase (e.g., `UserProfileView`, `NetworkManager`).
  - **Properties/Functions**: lowerCamelCase (e.g., `fetchData`, `userName`).
  - **Booleans**: Should read like assertions (e.g., `isLoading`, `hasError`, `isValid`).
  - **No Abbreviations**: Use full names (e.g., `button` not `btn`, `index` not `idx`).

## File Structure
- Group files by feature or module (e.g., `Features/Login/`, `Features/Home/`).
- Within a feature, separate `Views`, `ViewModels`, and `Models`.
- Common utilities and extensions go in a `Shared` or `Core` folder.

## UI/UX
- Follow Apple's Human Interface Guidelines (HIG).
- Support Dark Mode and Light Mode automatically using system colors and semantic colors.
- Use SF Symbols for iconography.
- Ensure accessibility support (Dynamic Type, VoiceOver labels).

## Error Handling
- Use Swift's `Error` protocol and `do-catch` blocks.
- Handle errors gracefully and show user-friendly error messages (e.g., using `.alert` or toast messages).

## Dependency Injection
- Use dependency injection (constructor injection) to pass services into ViewModels.
- Use `@EnvironmentObject` for global state (like UserSession), but sparingly.

## Testing
- Write unit tests for ViewModels and Services.
- Keep logic out of Views to make testing easier.



## Linting & Code Style
- **SwiftLint Compliance**: All generated code must adhere to the rules defined in `.swiftlint.yml`.
- **Formatting Rules**:
  - **No Trailing Whitespace**: Ensure no lines end with spaces.
  - **Vertical Whitespace**: Limit to exactly one empty line between functions or logical blocks.
  - **Line Length**: Keep lines under 140 characters.
- **Safety**:
  - **No Force Unwrapping**: Never use `!` to unwrap optionals. Always use `if let`, `guard let`, or default values (`??`).
- **SwiftUI Syntax## Linting & Code Style
- **SwiftLint Compliance**: All generated code must adhere to the rules defined in `.swiftlint.yml`.
- **Formatting Rules**:
  - **No Trailing Whitespace**: Ensure no lines end with spaces.
  - **Vertical Whitespace**: Limit to exactly one empty line between functions or logical blocks.
  - **Line Length**: Keep lines under 140 characters.
- **Safety**:
  - **No Force Unwrapping**: Never use `!` to unwrap optionals. Always use `if let`, `guard let`, or default values (`??`).
- **SwiftUI Syntax