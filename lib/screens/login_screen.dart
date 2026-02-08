import 'package:flutter/material.dart';
import 'Coordinator_dashboard.dart';
import 'data_service.dart';
import 'dashboard_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController idController = TextEditingController();

  void login() {
    if (nameController.text.isEmpty || idController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter all details")),
      );
      return;
    }

    // save login in DataService
    DataService.instance.login(
      nameController.text,
      idController.text,
    );

    // simple role logic
    final bool isCoordinator =
    idController.text.startsWith("C");

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => isCoordinator
            ? const CoordinatorDashboardScreen()
            : const DashboardScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              const Text(
                "Welcome to DLLE Connect",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "Sign in to continue",
                style: TextStyle(color: Colors.white70),
              ),

              const SizedBox(height: 40),

              // -------- NAME --------
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: inputDecoration("Name"),
              ),

              const SizedBox(height: 16),

              // -------- ID --------
              TextField(
                controller: idController,
                style: const TextStyle(color: Colors.white),
                decoration: inputDecoration("Student / Coordinator ID"),
              ),

              const SizedBox(height: 30),

              // -------- LOGIN BUTTON --------
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                  ),
                  child: const Text(
                    "LOGIN",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // -------- SIGNUP --------
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SignupScreen(),
                    ),
                  );
                },
                child: const Text(
                  "New user? Sign up",
                  style: TextStyle(
                    color: Colors.lightBlueAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------- INPUT DECORATION --------
  InputDecoration inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: const Color(0xFF1F2933),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
