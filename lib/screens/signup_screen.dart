import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController identifierController = TextEditingController(); // ID or Email
  final TextEditingController deptController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  
  String selectedRole = 'student'; // Default role
  bool isLoading = false;

  void signup() async {
    final name = nameController.text.trim();
    final identifier = identifierController.text.trim();
    final dept = deptController.text.trim();
    final password = passwordController.text.trim();

    if (name.isEmpty || identifier.isEmpty || dept.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    if (selectedRole == 'student') {
      if (identifier.length < 5 || !RegExp(r'^[0-9]+$').hasMatch(identifier)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Student ID must be at least 5 digits")),
        );
        return;
      }
    } else {
      // Basic email validation for admin
      if (!identifier.contains('@') || !identifier.contains('.')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a valid email address")),
        );
        return;
      }
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password must be at least 6 characters")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await SupabaseService.signUp(
        identifier: identifier,
        password: password,
        name: name,
        department: dept,
        role: selectedRole,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Signup successful. Please login.")),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Signup failed: ${e.toString()}")),
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
      appBar: AppBar(
        title: const Text("Sign Up"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Create Account",
              style: TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // -------- ROLE SELECTION --------
            Row(
              children: [
                const Text("Role:", style: TextStyle(color: Colors.black, fontSize: 16)),
                const SizedBox(width: 20),
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
                const SizedBox(width: 10),
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

            inputField(nameController, "Full Name"),
            const SizedBox(height: 16),
            inputField(
              identifierController, 
              selectedRole == 'student' ? "Student ID (Min 5 digits)" : "Admin Email",
              keyboardType: selectedRole == 'student' ? TextInputType.number : TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            inputField(deptController, selectedRole == 'student' ? "Course" : "Department"),
            const SizedBox(height: 16),
            inputField(passwordController, "Password", isPassword: true),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: isLoading ? null : signup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "SIGN UP",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: const Text(
                  "Already have an account? Login",
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
          ],
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
