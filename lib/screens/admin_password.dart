import 'package:flutter/material.dart';
import 'data_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController oldController = TextEditingController();
  final TextEditingController newController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();

  bool _oldObscure = true;
  bool _newObscure = true;
  bool _confirmObscure = true;

  Future<void> changePassword() async {
    if (oldController.text.isEmpty ||
        newController.text.isEmpty ||
        confirmController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    if (newController.text != confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    final success = await DataService.instance.changeAdminPassword(
      oldController.text,
      newController.text,
    );

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Old password incorrect")),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Password updated successfully"),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final fillColor = Theme.of(context).inputDecorationTheme.fillColor ??
        Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Change Password"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Update your admin password below.",
              style: TextStyle(color: textColor?.withOpacity(0.6), fontSize: 13),
            ),
            const SizedBox(height: 24),
            _passwordField(
              controller: oldController,
              hint: "Old Password",
              obscure: _oldObscure,
              onToggle: () => setState(() => _oldObscure = !_oldObscure),
              fillColor: fillColor,
              textColor: textColor,
            ),
            const SizedBox(height: 16),
            _passwordField(
              controller: newController,
              hint: "New Password",
              obscure: _newObscure,
              onToggle: () => setState(() => _newObscure = !_newObscure),
              fillColor: fillColor,
              textColor: textColor,
            ),
            const SizedBox(height: 16),
            _passwordField(
              controller: confirmController,
              hint: "Confirm New Password",
              obscure: _confirmObscure,
              onToggle: () => setState(() => _confirmObscure = !_confirmObscure),
              fillColor: fillColor,
              textColor: textColor,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Update Password",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    required Color? fillColor,
    required Color? textColor,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: TextStyle(color: textColor?.withOpacity(0.6)),
        filled: true,
        fillColor: fillColor,
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.purpleAccent),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
