import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';
import 'screens/data_service.dart';
import 'supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  // Load saved theme preference before building the UI
  await DataService.instance.loadThemePreference();

  // Start Supabase Realtime subscription for announcements (notifies all users)
  DataService.instance.initRealtimeSubscriptions();

  runApp(const DLLEApp());
}

class DLLEApp extends StatelessWidget {
  const DLLEApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: DataService.instance.themeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'DLLE Connect',
          themeMode: currentMode,
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF020202),
            primaryColor: Colors.blueAccent,
            colorScheme: const ColorScheme.dark(
              primary: Colors.blueAccent,
              secondary: Colors.lightBlueAccent,
              surface: Color(0xFF020202),
              onPrimary: Colors.white,
              onSurface: Colors.white,
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Color(0xFF0C2237),
              selectedItemColor: Colors.blueAccent,
              unselectedItemColor: Colors.white54,
              elevation: 10,
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
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.white),
              bodyMedium: TextStyle(color: Colors.white70),
              titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFFFFFFF),
            primaryColor: Colors.black,
            colorScheme: const ColorScheme.light(
              primary: Colors.black,
              secondary: Colors.lightBlueAccent,
              surface: Color(0xFFD6DDE6),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Color(0xFFFFFFFF),
              selectedItemColor: Colors.blueAccent,
              unselectedItemColor: Colors.black,
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
                borderSide: const BorderSide(color: Colors.black12),
              ),
            ),
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
