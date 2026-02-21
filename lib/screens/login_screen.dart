import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
      final isEmail = identifier.contains('@');
      final isNumeric = RegExp(r'^[0-9]+$').hasMatch(identifier);

      if (!isEmail && !isNumeric) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a valid Student ID or Email")),
        );
        return;
      } 

      if (!isEmail && identifier.length < 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Student ID must be at least 5 digits")),
        );
        return;
      }
    } else if (selectedRole == 'admin') {
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
        // Fetch actual role from the 'users' table in the database
        final userData = await Supabase.instance.client
            .from('users')
            .select('role, full_name, identifier')
            .eq('id', user.id)
            .maybeSingle();

        final actualRole = userData?['role'] ?? 'student';
        
        if (actualRole != selectedRole) {
          await SupabaseService.signOut();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Unauthorized: You are registered as a $actualRole.")),
            );
          }
          return;
        }

        String finalIdentifier = identifier;
        if (selectedRole == 'student' && identifier.contains('@')) {
          finalIdentifier = userData?['identifier'] ?? identifier;
        }

        if (actualRole == 'student') {
          await DataService.instance.login(finalIdentifier);
        } else {
          DataService.instance.updateProfile(
            name: userData?['full_name'] ?? identifier,
            id: identifier,
            course: 'Admin',
          );
          await DataService.instance.saveLoginSession(identifier);
          DataService.instance.isLoggedIn = true;
          DataService.instance.studentId = identifier;
          DataService.instance.studentName = userData?['full_name'] ?? identifier;
        }

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
          errorMessage = "Incorrect Credentials or Password";
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
              
              inputField(
                identifierController, 
                selectedRole == 'student' ? "Student ID or Email" : "Admin Email",
                keyboardType: selectedRole == 'student' ? TextInputType.text : TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              
              inputField(passwordController, "Password", isPassword: true),
              const SizedBox(height: 30),

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
              if (selectedRole == 'student')
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
                    "New student? Sign up",
                    style: TextStyle(color: Colors.black),
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
