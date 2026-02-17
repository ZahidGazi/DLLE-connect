import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'coordinator_dashboard.dart';
import 'data_service.dart';
import 'dashboard_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController identifierController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String selectedRole = 'student'; // Default role
  bool isLoading = false;

  void login() async {
    final identifier = identifierController.text.trim();
    final password = passwordController.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter all details")),
      );
      return;
    }

    if (selectedRole == 'student') {
      if (identifier.length < 5 || !RegExp(r'^[0-9]+$').hasMatch(identifier)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a valid Student ID (min 5 digits)")),
        );
        return;
      }
    } else {
      if (!identifier.contains('@')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a valid Admin Email")),
        );
        return;
      }
    }

    setState(() => isLoading = true);

    try {
      final response = await SupabaseService.login(
        identifier: identifier,
        password: password,
        role: selectedRole,
      );

      final user = response.user;
      if (user != null) {
        final metadata = user.userMetadata;
        final actualRole = metadata?['role'] ?? 'student';
        final name = metadata?['full_name'] ?? 'User';

        // Check if the user is logging in with the correct role
        if (actualRole != selectedRole) {
          await SupabaseService.signOut();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Unauthorized: You are registered as a $actualRole.")),
            );
          }
          return;
        }

        // Update local DataService session
        await DataService.instance.login(name, identifier);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => actualRole == 'admin'
                  ? const CoordinatorDashboardScreen()
                  : const DashboardScreen(),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        if (errorMessage.contains("Invalid login credentials")) {
          errorMessage = "Incorrect ID/Email or Password";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 150,
                child: Image.asset(
                  'assets/login_image.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => 
                      const Icon(Icons.account_circle, size: 100, color: Colors.blueAccent),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                "Welcome to DLLE Connect",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Sign in to continue",
                style: TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 30),

              // -------- ROLE SELECTION --------
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text("Student"),
                    selected: selectedRole == 'student',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          selectedRole = 'student';
                          identifierController.clear();
                        });
                      }
                    },
                  ),
                  const SizedBox(width: 15),
                  ChoiceChip(
                    label: const Text("Admin"),
                    selected: selectedRole == 'admin',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          selectedRole = 'admin';
                          identifierController.clear();
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // -------- ID / EMAIL --------
              inputField(
                identifierController, 
                selectedRole == 'student' ? "Student ID" : "Admin Email",
                keyboardType: selectedRole == 'student' ? TextInputType.number : TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              
              // -------- PASSWORD --------
              inputField(passwordController, "Password", isPassword: true),
              const SizedBox(height: 30),

              // -------- LOGIN BUTTON --------
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isLoading ? null : login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "LOGIN",
                          style: TextStyle(
                            color: Colors.white,
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
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget inputField(TextEditingController controller, String hint, {bool isPassword = false, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black45),
        filled: true,
        fillColor: const Color(0xFFF1F1F1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
