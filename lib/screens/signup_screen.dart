import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'data_service.dart';
import 'login_screen.dart';
import 'email_confirmation_screen.dart';
import '../utils/responsive_helper.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController identifierController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? _selectedCourse;
  int? _selectedYear;
  final int _maxYear = 4;

  List<Map<String, dynamic>> _courses = [];
  bool _isLoadingCourses = true;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() => _isLoadingCourses = true);
    await DataService.instance.fetchCourses();
    if (mounted) {
      setState(() {
        _courses = DataService.instance.courses;
        _isLoadingCourses = false;
      });
    }
  }

  /// Returns the max year for the currently selected course.
  int get _currentMaxYear {
    if (_selectedCourse == null) return _maxYear;
    final course = _courses.firstWhere(
      (c) => c['name'] == _selectedCourse,
      orElse: () => {'max_year': _maxYear},
    );
    return (course['max_year'] as int?) ?? _maxYear;
  }

  void signup() async {
    final name = nameController.text.trim();
    final identifier = identifierController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (name.isEmpty ||
        identifier.isEmpty ||
        email.isEmpty ||
        _selectedCourse == null ||
        _selectedYear == null ||
        password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email)) {
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
      final response = await SupabaseService.signUp(
        identifier: identifier,
        email: email,
        password: password,
        name: name,
        department: _selectedCourse!,
        yearOfStudy: _selectedYear!,
        role: 'student',
      );

      if (mounted) {
        if (response.session == null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => EmailConfirmationScreen(email: email),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Signup successful! Please login to continue.")),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
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
          errorMessage =
              "A database error occurred. Ensure RLS is disabled on the 'users' table or policies are correct.";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(label: 'OK', onPressed: () {}),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color;
    final hintColor = theme.inputDecorationTheme.hintStyle?.color;
    final fillColor = theme.inputDecorationTheme.fillColor;
    final cardColor = theme.cardTheme.color;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sign Up"),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
        padding: ResponsiveHelper.padding(context),
        child: ResponsiveWrapper(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Create Student Account",
              style: theme.textTheme.titleLarge?.copyWith(fontSize: 22),
            ),
            const SizedBox(height: 20),

            // Full Name
            inputField(nameController, "Full Name"),
            const SizedBox(height: 16),

            // Student ID
            inputField(
              identifierController,
              "Student ID (Min 5 digits)",
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Email
            inputField(emailController, "Email",
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 16),

            // -------- COURSE DROPDOWN --------
            _isLoadingCourses
                ? Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: fillColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : _courses.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: fillColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber,
                                color: Colors.orange, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "No courses available. Contact admin.",
                                style: TextStyle(
                                    color: hintColor, fontSize: 13),
                              ),
                            ),
                            TextButton(
                              onPressed: _loadCourses,
                              child: const Text("Retry",
                                  style:
                                      TextStyle(color: Colors.blueAccent)),
                            ),
                          ],
                        ),
                      )
                    : DropdownButtonFormField<String>(
                        initialValue: _selectedCourse,
                        decoration: InputDecoration(
                          hintText: "Select Course",
                          hintStyle: TextStyle(color: hintColor),
                          filled: true,
                          fillColor: fillColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                        ),
                        style: TextStyle(color: textColor, fontSize: 16),
                        dropdownColor: cardColor,
                        icon: Icon(Icons.keyboard_arrow_down,
                            color: hintColor),
                        items: _courses.map((course) {
                          return DropdownMenuItem<String>(
                            value: course['name'] as String,
                            child: Text(course['name'] as String),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCourse = value;
                            if (_selectedYear != null &&
                                _selectedYear! > _currentMaxYear) {
                              _selectedYear = null;
                            }
                          });
                        },
                      ),
            const SizedBox(height: 16),

            // -------- YEAR OF STUDY DROPDOWN --------
            DropdownButtonFormField<int>(
              initialValue: _selectedYear,
              decoration: InputDecoration(
                hintText: _selectedCourse == null
                    ? "Select course first"
                    : "Year of Study",
                hintStyle: TextStyle(color: hintColor),
                filled: true,
                fillColor: fillColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 16),
              ),
              style: TextStyle(color: textColor, fontSize: 16),
              dropdownColor: cardColor,
              icon: Icon(Icons.keyboard_arrow_down, color: hintColor),
              items: _selectedCourse == null
                  ? []
                  : List.generate(_currentMaxYear, (i) => i + 1)
                      .map((year) => DropdownMenuItem<int>(
                            value: year,
                            child: Text("Year $year"),
                          ))
                      .toList(),
              onChanged: _selectedCourse == null
                  ? null
                  : (value) => setState(() => _selectedYear = value),
            ),
            const SizedBox(height: 16),

            // Password
            inputField(passwordController, "Password", isPassword: true),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: isLoading ? null : signup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
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
                child: Text(
                  "Already have an account? Login",
                  style: TextStyle(color: textColor),
                ),
              ),
            ),
          ],
        ),
        ),
        ),
      ),
    );
  }

  Widget inputField(
    TextEditingController controller,
    String hint, {
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: theme.inputDecorationTheme.hintStyle,
        filled: true,
        fillColor: theme.inputDecorationTheme.fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    identifierController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
