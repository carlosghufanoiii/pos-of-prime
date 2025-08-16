# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Prime Bar POS is a production-grade Point-of-Sale Flutter application for Android & iOS developed by Alatiris Inc. The app serves bars and restaurants with multi-role support (Waiter, Cashier, Kitchen, Bartender, Admin) and comprehensive order management.

**Key Technologies:**
- Flutter (Android, iOS, optional web admin)
- Backend: Firebase or Supabase with RBAC
- Currency: Philippine Peso (₱), Timezone: Asia/Manila
- Printing: ESC/POS thermal printers (58mm & 80mm)
- Google Integration: OAuth, Sheets sync, Drive export

## Essential Commands

### Development Workflow
```bash
# Setup and dependencies
flutter pub get              # Install dependencies
flutter doctor              # Check Flutter environment

# Development
flutter run                 # Run with hot reload
flutter run --release       # Performance testing
flutter devices             # List available devices

# Code Quality (Required before completing tasks)
flutter analyze             # Check for errors/warnings
flutter format .            # Format code
flutter test                # Run all tests

# Building
flutter build apk           # Android APK
flutter build ios           # iOS (macOS only)
flutter build web           # Web admin interface
```

### Testing Commands
```bash
flutter test                          # All tests
flutter test test/widget_test.dart    # Specific test
flutter test --coverage              # With coverage
```

## Architecture & Code Organization

### Current State
The project is in early development with Flutter's default template. Main entry point is `lib/main.dart`.

### Planned Architecture
```
lib/
├── main.dart
├── features/
│   ├── auth/           # Google OAuth + email/password
│   ├── orders/         # Order management (PENDING_APPROVAL → APPROVED → IN_PREP → READY → SERVED)
│   ├── inventory/      # Stock management with in/out adjustments
│   ├── kitchen_display/# Real-time food item queue
│   ├── bar_display/    # Real-time alcoholic item queue
│   ├── cashier/        # Payment processing, receipt printing
│   ├── waiter/         # Order creation by table/customer
│   └── admin/          # Employee management, product CRUD, reports
├── shared/
│   ├── widgets/        # Reusable UI components
│   ├── services/       # Firebase/Supabase integration
│   ├── models/         # Data models
│   └── utils/          # Helper functions, constants
└── core/
    ├── printer/        # ESC/POS thermal printer integration
    └── google/         # Sheets sync, Drive export
```

### Core Workflow Implementation
1. **Waiter** creates order → status: PENDING_APPROVAL
2. **Cashier** approves → prints receipt → routes items (alcohol → Bar, food → Kitchen)
3. **Kitchen/Bar** marks items Ready
4. **Waiter** serves → order closed
5. Inventory auto-decrements on approval

## Code Style & Conventions

- Uses `flutter_lints` package for code quality
- Follow Dart naming conventions: PascalCase for classes, camelCase for variables
- Use `const` constructors for performance
- Private members prefixed with underscore
- Comprehensive commenting for business logic
- State management: Consider Bloc/Riverpod for complex state

## Task Completion Requirements

Before marking any task complete:
1. Run `flutter analyze` (must pass with no errors)
2. Run `flutter format .` for consistent formatting
3. Run `flutter test` (all tests must pass)
4. Test `flutter run` in debug mode
5. For production features, test `flutter run --release`

## Key Features to Implement

### Authentication & Roles
- Google OAuth integration
- Role-based access control (Waiter, Cashier, Kitchen, Bartender, Admin)
- Employee account management

### Order Management
- Real-time order tracking with status updates
- Automatic item routing based on `isAlcoholic` flag
- Kitchen Display System (KDS) and Bar Display System (BDS)

### Payment & Printing
- ESC/POS thermal printer integration (58mm & 80mm)
- Receipt printing with Philippine Peso formatting
- Payment methods: cash, card, e-wallet

### Inventory & Reporting
- Real-time inventory tracking with stock adjustments
- Google Sheets sync (per-order append)
- Google Drive nightly snapshots
- Excel/CSV export capabilities

### Offline Support
- Local data storage with sync when online
- Queue operations for offline mode

## Development Priorities

1. **Authentication System**: Implement Google OAuth and role management
2. **Order Management**: Core workflow with status tracking
3. **Real-time Features**: Kitchen and Bar display systems
4. **Printing Integration**: ESC/POS thermal printer support
5. **Inventory System**: Stock tracking with adjustments
6. **Google Integration**: Sheets sync and Drive export
7. **Offline Support**: Local storage with synchronization

## Important Business Rules

- Items with `isAlcoholic: true` route to Bar Display
- Non-alcoholic items route to Kitchen Display
- Inventory decrements automatically on order approval
- All financial amounts in Philippine Peso (₱)
- Timezone: Asia/Manila for all date/time operations
- Support both 58mm and 80mm thermal printers
- Admin PIN required for large refunds/voids