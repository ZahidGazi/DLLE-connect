import 'package:flutter/material.dart';
import 'data_service.dart';
import 'event_model.dart';
import 'login_screen.dart';
import 'user_model.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  final TextEditingController deptController = TextEditingController();

  void signup() {
    final name = nameController.text.trim();
    final id = idController.text.trim();
    final dept = deptController.text.trim();

    if (name.isEmpty || id.isEmpty || dept.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    // 🔴 CHECK DUPLICATE ID
    final existingStudent = DataService.instance.students
        .any((s) => s.id == id);

    if (existingStudent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Student ID already exists")),
      );
      return;
    }

    // ✅ CREATE STUDENT
    final newStudent = Student(
      name: name,
      id: id,
      department: dept,
    );

    DataService.instance.students.add(newStudent);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Signup successful. Please login.")),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),

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
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            // -------- NAME --------
            inputField(nameController, "Full Name"),

            const SizedBox(height: 16),

            // -------- ID --------
            inputField(idController, "Student ID"),

            const SizedBox(height: 16),

            // -------- DEPARTMENT --------
            inputField(deptController, "Department"),

            const SizedBox(height: 30),

            // -------- SIGNUP BUTTON --------
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: signup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                ),
                child: const Text(
                  "SIGN UP",
                  style: TextStyle(
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
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(),
                    ),
                  );
                },
                child: const Text(
                  "Already have an account? Login",
                  style: TextStyle(color: Colors.lightBlueAccent),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------- INPUT FIELD --------
  Widget inputField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF1F2933),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
