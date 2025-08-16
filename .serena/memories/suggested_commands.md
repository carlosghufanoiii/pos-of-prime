# Suggested Commands for Prime POS Development

## Environment Setup
```bash
# Check Flutter installation and environment
flutter doctor

# Get project dependencies
flutter pub get

# Clean build files
flutter clean
```

## Development Commands
```bash
# Run the app on connected device/emulator
flutter run

# Run with hot reload (default)
flutter run

# Run in debug mode (default)
flutter run --debug

# Run in release mode for performance testing
flutter run --release

# Run on specific device
flutter run -d <device-id>

# List available devices
flutter devices
```

## Testing Commands
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run tests with coverage
flutter test --coverage

# Run integration tests (when available)
flutter test integration_test/
```

## Code Quality Commands
```bash
# Analyze code for issues
flutter analyze

# Format code according to Dart style
flutter format .

# Format specific files
flutter format lib/main.dart

# Check for outdated dependencies
flutter pub outdated

# Upgrade dependencies
flutter pub upgrade
```

## Build Commands
```bash
# Build APK for Android
flutter build apk

# Build APK for specific flavor (when configured)
flutter build apk --flavor production

# Build for iOS (requires macOS)
flutter build ios

# Build for web
flutter build web

# Build app bundle for Google Play
flutter build appbundle
```

## Dependency Management
```bash
# Add a new dependency
flutter pub add <package_name>

# Add a dev dependency
flutter pub add --dev <package_name>

# Remove a dependency
flutter pub remove <package_name>

# Get dependencies (after pubspec.yaml changes)
flutter pub get
```

## Platform-Specific Commands
```bash
# Open iOS project in Xcode (macOS only)
open ios/Runner.xcworkspace

# Open Android project in Android Studio
open -a "Android Studio" android/
```

## Debugging Commands
```bash
# Enable debugging and profiling
flutter run --enable-experiment=non-nullable

# Run with specific target platform
flutter run --target-platform android-arm64

# Launch with specific entry point
flutter run --target lib/main.dart
```