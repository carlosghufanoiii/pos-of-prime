# Prime POS Codebase Structure

## Current Project State
This is a newly created Flutter project with basic template structure. The project is in early stages and will need significant development to implement the POS system requirements.

## Directory Structure
```
prime_pos/
├── android/          # Android-specific code and configuration
├── ios/              # iOS-specific code and configuration  
├── lib/              # Main Dart code
│   └── main.dart     # Application entry point
├── test/             # Test files
│   └── widget_test.dart
├── web/              # Web-specific files (for admin interface)
├── macos/            # macOS-specific files
├── linux/            # Linux-specific files
├── windows/          # Windows-specific files
├── pubspec.yaml      # Dependencies and project configuration
├── analysis_options.yaml  # Code analysis rules
├── README.md         # Project documentation
└── prime-pos.md      # Detailed project requirements
```

## Key Files
- **`lib/main.dart`**: Application entry point with basic Flutter counter app
- **`pubspec.yaml`**: Project dependencies and metadata
- **`analysis_options.yaml`**: Dart/Flutter linting configuration
- **`prime-pos.md`**: Comprehensive project requirements and specifications
- **`test/widget_test.dart`**: Basic widget test template

## Current Implementation Status
- **Template State**: Currently contains Flutter's default counter app template
- **Dependencies**: Basic Flutter dependencies (cupertino_icons, flutter_lints)
- **Platform Support**: Configured for Android, iOS, and Web platforms
- **Testing**: Basic widget test structure in place

## Planned Architecture (Based on Requirements)
The project will need to be restructured to implement:

### Feature-Based Structure (Recommended)
```
lib/
├── main.dart
├── app/
│   ├── app.dart
│   └── theme/
├── features/
│   ├── auth/
│   ├── orders/
│   ├── inventory/
│   ├── kitchen_display/
│   ├── bar_display/
│   ├── cashier/
│   ├── waiter/
│   └── admin/
├── shared/
│   ├── widgets/
│   ├── services/
│   ├── models/
│   ├── utils/
│   └── constants/
└── core/
    ├── network/
    ├── database/
    └── printer/
```

## Technology Integration Points
- **Firebase/Supabase**: Backend services integration
- **ESC/POS Printing**: Thermal printer integration
- **Google Services**: OAuth, Sheets, Drive integration
- **State Management**: Will need Redux/Bloc/Riverpod for complex state
- **Offline Support**: Local database with sync capabilities
- **Multi-platform**: Android, iOS, and Web admin interface

## Development Priorities
1. Set up proper project architecture
2. Implement authentication system
3. Create user role management
4. Build order management system
5. Integrate printing capabilities
6. Implement real-time features
7. Add offline support and sync