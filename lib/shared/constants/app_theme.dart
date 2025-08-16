import 'package:flutter/material.dart';

class AppTheme {
  // Nightclub Brand Colors - Black & Pink Theme
  static const Color primaryColor = Color(0xFFE91E63); // Hot Pink
  static const Color primaryDark = Color(0xFFC2185B); // Darker Pink
  static const Color primaryLight = Color(0xFFF48FB1); // Light Pink
  static const Color secondaryColor = Color(0xFF212121); // Deep Black
  static const Color accentColor = Color(0xFFFF4081); // Bright Pink Accent
  static const Color errorColor = Color(0xFFE53935); // Error red
  static const Color successColor = Color(0xFF00E676); // Neon Green
  static const Color warningColor = Color(0xFFFFD740); // Gold
  
  // Nightclub Specific Colors
  static const Color neonPink = Color(0xFFFF1744); // Neon Pink
  static const Color deepBlack = Color(0xFF000000); // Pure Black
  static const Color darkGrey = Color(0xFF121212); // Dark Background
  static const Color lightGrey = Color(0xFF424242); // Card Background
  static const Color surfaceGrey = Color(0xFF1E1E1E); // Surface
  
  // Role-based Colors - Nightclub Theme
  static const Color waiterColor = Color(0xFFE91E63); // Hot Pink
  static const Color cashierColor = Color(0xFFFF4081); // Bright Pink
  static const Color kitchenColor = Color(0xFF00E676); // Neon Green
  static const Color barColor = Color(0xFFFFD740); // Gold
  static const Color adminColor = Color(0xFF9C27B0); // Purple

  static ThemeData get lightTheme {
    // For nightclub theme, we'll use the dark theme even for "light" mode
    return darkTheme;
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primarySwatch: MaterialColor(0xFFE91E63, const {
        50: Color(0xFFFCE4EC),
        100: Color(0xFFF8BBD9),
        200: Color(0xFFF48FB1),
        300: Color(0xFFF06292),
        400: Color(0xFFEC407A),
        500: Color(0xFFE91E63),
        600: Color(0xFFD81B60),
        700: Color(0xFFC2185B),
        800: Color(0xFFAD1457),
        900: Color(0xFF880E4F),
      }),
      fontFamily: 'SF Pro Display', // Modern font
      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        primary: primaryColor,
        onPrimary: Colors.white,
        primaryContainer: primaryDark,
        onPrimaryContainer: primaryLight,
        secondary: secondaryColor,
        onSecondary: primaryColor,
        secondaryContainer: lightGrey,
        onSecondaryContainer: primaryLight,
        tertiary: accentColor,
        onTertiary: Colors.white,
        error: errorColor,
        onError: Colors.white,
        errorContainer: Color(0xFF93000A),
        onErrorContainer: Color(0xFFFFDAD6),
        surface: deepBlack,
        onSurface: Colors.white,
        surfaceContainerHighest: lightGrey,
        onSurfaceVariant: Color(0xFFE0E0E0),
        outline: Color(0xFF616161),
        outlineVariant: Color(0xFF424242),
        shadow: Colors.black54,
        scrim: Colors.black87,
        inverseSurface: Color(0xFFE0E0E0),
        onInverseSurface: deepBlack,
        inversePrimary: primaryDark,
      ),
      // Modern AppBar with gradient
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(
          color: primaryColor,
          size: 24,
        ),
      ),
      // Modern elevated buttons with gradient effect
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          elevation: 8,
          shadowColor: primaryColor.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      // Modern cards with subtle glow
      cardTheme: CardThemeData(
        color: surfaceGrey,
        elevation: 8,
        shadowColor: primaryColor.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: primaryColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        margin: const EdgeInsets.all(8),
      ),
      // Modern input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: primaryColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: errorColor,
            width: 1,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.6),
          fontSize: 16,
        ),
        labelStyle: const TextStyle(
          color: primaryColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      // Modern floating action button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 12,
        focusElevation: 16,
        hoverElevation: 16,
        shape: CircleBorder(),
      ),
      // Modern bottom navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceGrey,
        elevation: 16,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.white.withValues(alpha: 0.6),
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 12,
        ),
        type: BottomNavigationBarType.fixed,
      ),
      // Modern list tiles
      listTileTheme: const ListTileThemeData(
        tileColor: Colors.transparent,
        selectedTileColor: primaryColor,
        selectedColor: Colors.white,
        textColor: Colors.white,
        iconColor: primaryColor,
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      // Modern text theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.w300,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.25,
        ),
        displaySmall: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w400,
        ),
        headlineLarge: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.25,
        ),
        headlineMedium: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
        headlineSmall: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
        titleMedium: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        titleSmall: TextStyle(
          color: primaryColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        bodyLarge: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
        ),
        bodyMedium: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
        ),
        bodySmall: TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
        ),
        labelLarge: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        labelMedium: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
        labelSmall: TextStyle(
          color: Colors.white70,
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
      // Modern divider
      dividerTheme: DividerThemeData(
        color: primaryColor.withValues(alpha: 0.2),
        thickness: 1,
        space: 16,
      ),
      // Modern dialog
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceGrey,
        elevation: 24,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: primaryColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  // Custom gradient decorations for special effects
  static BoxDecoration get primaryGradientDecoration => BoxDecoration(
    gradient: LinearGradient(
      colors: [primaryColor, primaryDark],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: primaryColor.withValues(alpha: 0.3),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration get surfaceGradientDecoration => BoxDecoration(
    gradient: LinearGradient(
      colors: [surfaceGrey, lightGrey],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: primaryColor.withValues(alpha: 0.1),
      width: 1,
    ),
  );

  static BoxDecoration get neonGlowDecoration => BoxDecoration(
    color: surfaceGrey,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: primaryColor,
      width: 2,
    ),
    boxShadow: [
      BoxShadow(
        color: primaryColor.withValues(alpha: 0.5),
        blurRadius: 16,
        spreadRadius: 2,
      ),
    ],
  );
}