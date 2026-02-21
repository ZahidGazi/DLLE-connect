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
  final TextEditingController identifierController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController deptController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  
  bool isLoading = false;

  void signup() async {
    final name = nameController.text.trim();
    final identifier = identifierController.text.trim();
    final email = emailController.text.trim();
    final dept = deptController.text.trim();
    final password = passwordController.text.trim();

    if (name.isEmpty || identifier.isEmpty || email.isEmpty || dept.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid email address")),
      );
      return;
    }

    if (identifier.length < 5 || !RegExp(r'^[0-9]+$').hasMatch(identifier)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Student ID must be at least 5 digits")),
      );
      return;
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
        email: email,
        password: password,
        name: name,
        department: dept,
        role: 'student',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Signup successful! Please login to continue.")),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        
        if (errorMessage.startsWith("Exception: ")) {
          errorMessage = errorMessage.replaceFirst("Exception: ", "");
        }
        
        if (errorMessage.contains("User already registered")) {
            errorMessage = "This email or Student ID is already registered.";
        } else if (errorMessage.contains("check constraint")) {
            errorMessage = "A database error occurred. Ensure RLS is disabled on the 'users' table or policies are correct.";
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
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
              "Create Student Account",
              style: TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            inputField(nameController, "Full Name"),
            const SizedBox(height: 16),
            inputField(
              identifierController, 
              "Student ID (Min 5 digits)",
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            inputField(emailController, "Email", keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 16),
            inputField(deptController, "Course"),
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
