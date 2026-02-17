import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/data_service.dart'; // Import DataService

void main() {
  runApp(const DLLEApp());
}

class DLLEApp extends StatelessWidget {
  const DLLEApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ ValueListenableBuilder listens to theme changes
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: DataService.instance.themeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'DLLE Connect',

          // ---------------- THEME MODE ----------------
          themeMode: currentMode,

          // ---------------- DARK THEME (Original) ----------------
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF020202), // Dark BG
            primaryColor: Colors.blueAccent,

            colorScheme: const ColorScheme.dark(
              primary: Colors.blueAccent,
              secondary: Colors.lightBlueAccent,
              surface: Color(0xFF020202), // GitHub Dimmed Card
              onPrimary: Colors.white,
              onSurface: Colors.white,
            ),

            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF294577),
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              iconTheme: IconThemeData(color: Colors.white),
            ),

            cardTheme: CardThemeData(
              color: const Color(0xFF0C2237),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),

            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF161B22),
              hintStyle: const TextStyle(color: Colors.white54),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),

          // ---------------- LIGHT THEME (New) ----------------
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFFFFFFF), // Light Grey BG
            primaryColor: Colors.black,

            colorScheme: const ColorScheme.light(
              primary: Colors.black,
              secondary: Colors.lightBlueAccent,
              surface: Color(0xFFD6DDE6), // White Card
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
            //  Light Bottom Nav Theme
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Color(0xFFFFFFFF), // White bar
              selectedItemColor: Colors.blueAccent,
              unselectedItemColor: Colors.black, // Grey icons on white bg
              elevation: 10,
            ),

            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF277BDA),
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
              iconTheme: IconThemeData(color: Colors.black87),
            ),

            cardTheme: CardThemeData(
              color: Color(0xFFD6DDE6),
              elevation: 2,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),

            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              hintStyle: const TextStyle(color: Colors.black45),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.black12), // Subtle border for light mode
              ),
            ),
            // Fix for text colors in light mode
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.black87),
              bodyMedium: TextStyle(color: Colors.black87),
              titleLarge: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
            ),
            iconTheme: const IconThemeData(color: Colors.black87),
          ),

          home: const LoginScreen(),
        );
      },
    );
  }
}