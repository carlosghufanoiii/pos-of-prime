# Code Style and Conventions for Prime POS

## Analysis Configuration
The project uses `flutter_lints` package for code quality enforcement via `analysis_options.yaml`.

## Dart/Flutter Conventions
Based on the current codebase and Flutter best practices:

### Code Style
- Uses Flutter recommended linting rules from `package:flutter_lints/flutter.yaml`
- Standard Dart formatting with `flutter format`
- Consistent naming conventions:
  - Class names: PascalCase (e.g., `MyHomePage`)
  - Variable names: camelCase (e.g., `_counter`)
  - File names: snake_case (e.g., `widget_test.dart`)
  - Private members: prefix with underscore (e.g., `_incrementCounter`)

### Widget Structure
- StatelessWidget for static widgets
- StatefulWidget for dynamic widgets with state
- Use `const` constructors where possible for performance
- Follow Widget tree structure with proper indentation
- Use descriptive names for widget classes and methods

### Key Requirements
- Use `super.key` for widget constructors
- Implement proper state management with `setState()`
- Follow Material Design principles
- Use proper commenting for complex logic
- Import organization: Flutter SDK imports first, then package imports, then local imports

### File Organization
- Main entry point: `lib/main.dart`
- Tests: `test/` directory
- Platform-specific code in respective directories (`android/`, `ios/`, etc.)

### Dependencies
- Use exact or compatible versions in `pubspec.yaml`
- Prefer official Flutter packages over third-party when available
- Keep dependencies up to date with `flutter pub upgrade`

### Testing Conventions
- Widget tests in `test/` directory
- Test file naming: `<feature>_test.dart`
- Use descriptive test names
- Follow Given-When-Then pattern in tests
- Use `testWidgets` for widget testing
- Use proper assertions with `expect()`