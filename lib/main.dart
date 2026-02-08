import 'package:flutter/material.dart';

// -------- SCREENS --------
import 'screens/login_screen.dart';

// -------- DATA --------

void main() {
  runApp(const DLLEApp());
}

class DLLEApp extends StatelessWidget {
  const DLLEApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DLLE Connect',

      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D1117),

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0D1117),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
      ),

      // -------- START SCREEN --------
      home: const LoginScreen(),
    );
  }
}
