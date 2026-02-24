import 'package:flutter/material.dart';

/// Centralized color palette for the DLLE Connect app.
/// Import this wherever you need named color constants.
class AppColors {
  AppColors._(); // prevent instantiation

  // ── Shared / Brand ──────────────────────────────────────────────────────────
  static const Color primary     = Colors.blueAccent;
  static const Color accent      = Colors.lightBlueAccent;
  static const Color buttonText  = Colors.white;
  static const Color error       = Colors.redAccent;
  static const Color success     = Colors.green;

  // ── Light Theme ─────────────────────────────────────────────────────────────
  static const Color lightBackground    = Color(0xFFFFFFFF);
  static const Color lightSurface       = Color(0xFFD6DDE6);
  static const Color lightInputFill     = Color(0xFFF1F1F1);
  static const Color lightAppBar        = Color(0xFF277BDA);
  static const Color lightCard          = Color(0xFFD6DDE6);
  static const Color lightText          = Color(0xDD000000); // ~Colors.black87
  static const Color lightTextSecondary = Color(0x8A000000); // ~Colors.black54
  static const Color lightHint          = Color(0x73000000); // ~Colors.black45
  static const Color lightNavBar        = Color(0xFFFFFFFF);
  static const Color lightNavSelected   = Colors.blueAccent;
  static const Color lightNavUnselected = Colors.black;
  static const Color lightBorder        = Color(0x1F000000); // Colors.black12

  // ── Dark Theme ──────────────────────────────────────────────────────────────
  static const Color darkBackground    = Color(0xFF020202);
  static const Color darkSurface       = Color(0xFF0C2237);
  static const Color darkInputFill     = Color(0xFF161B22);
  static const Color darkAppBar        = Color(0xFF294577);
  static const Color darkCard          = Color(0xFF0C2237);
  static const Color darkText          = Colors.white;
  static const Color darkTextSecondary = Color(0xB3FFFFFF); // Colors.white70
  static const Color darkHint          = Color(0x8AFFFFFF); // Colors.white54
  static const Color darkNavBar        = Color(0xFF0C2237);
  static const Color darkNavSelected   = Colors.blueAccent;
  static const Color darkNavUnselected = Colors.white54;
  static const Color darkBorder        = Color(0x1AFFFFFF); // Colors.white10
}

/// Provides light and dark [ThemeData] for the DLLE Connect app.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.lightBackground,
        primaryColor: Colors.black,
        colorScheme: const ColorScheme.light(
          primary: Colors.black,
          secondary: AppColors.accent,
          surface: AppColors.lightSurface,
          onPrimary: AppColors.buttonText,
          onSurface: AppColors.lightText,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.lightNavBar,
          selectedItemColor: AppColors.lightNavSelected,
          unselectedItemColor: AppColors.lightNavUnselected,
          elevation: 10,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.lightAppBar,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: AppColors.buttonText,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: AppColors.buttonText),
        ),
        cardTheme: CardThemeData(
          color: AppColors.lightCard,
          elevation: 2,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.lightInputFill,
          hintStyle: const TextStyle(color: AppColors.lightHint),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.lightBorder),
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge:  TextStyle(color: AppColors.lightText),
          bodyMedium: TextStyle(color: AppColors.lightTextSecondary),
          titleLarge: TextStyle(
              color: AppColors.lightText, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: AppColors.lightText),
        dividerColor: AppColors.lightBorder,
      );

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.darkBackground,
        primaryColor: Colors.blueAccent,
        colorScheme: const ColorScheme.dark(
          primary: Colors.blueAccent,
          secondary: AppColors.accent,
          surface: AppColors.darkBackground,
          onPrimary: AppColors.buttonText,
          onSurface: AppColors.darkText,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.darkNavBar,
          selectedItemColor: AppColors.darkNavSelected,
          unselectedItemColor: AppColors.darkNavUnselected,
          elevation: 10,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.darkAppBar,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: AppColors.buttonText,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: AppColors.buttonText),
        ),
        cardTheme: CardThemeData(
          color: AppColors.darkCard,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.darkInputFill,
          hintStyle: const TextStyle(color: AppColors.darkHint),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge:  TextStyle(color: AppColors.darkText),
          bodyMedium: TextStyle(color: AppColors.darkTextSecondary),
          titleLarge: TextStyle(
              color: AppColors.darkText, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: AppColors.darkText),
        dividerColor: AppColors.darkBorder,
      );
}
