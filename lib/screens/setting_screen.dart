import 'package:flutter/material.dart';
import 'data_service.dart';
import 'login_screen.dart';

class StudentSettingsScreen extends StatefulWidget {
  const StudentSettingsScreen({super.key});

  @override
  State<StudentSettingsScreen> createState() => _StudentSettingsScreenState();
}

class _StudentSettingsScreenState extends State<StudentSettingsScreen> {
  late bool notificationsEnabled;
  late bool darkModeEnabled;

  @override
  void initState() {
    super.initState();
    notificationsEnabled = DataService.instance.notificationEnabled;
    darkModeEnabled = DataService.instance.isDarkMode;
  }

  @override
  Widget build(BuildContext context) {
    final data = DataService.instance;
    final cardColor = Theme.of(context).cardTheme.color;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
    final subTextColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Settings"),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // -------- PROFILE CARD (READ ONLY) --------
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.studentName,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                          "ID: ${data.studentId}",
                          style: TextStyle(color: subTextColor, fontSize: 14)
                      ),
                      Text(
                          "Course: ${data.studentCourse}", // ✅ Shows Department
                          style: TextStyle(color: subTextColor, fontSize: 13)
                      ),
                    ],
                  ),
                ),
                // ❌ Edit Button REMOVED
              ],
            ),
          ),

          const SizedBox(height: 24),

          // -------- APP SETTINGS --------
          sectionTitle("App Settings", textColor),

          settingsTile(
            icon: Icons.lock,
            title: "Change Password",
            textColor: textColor,
            cardColor: cardColor,
            onTap: () => _showChangePasswordDialog(context),
          ),

          settingsTile(
            icon: Icons.notifications,
            title: "Notifications",
            textColor: textColor,
            cardColor: cardColor,
            trailing: Switch(
              value: notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  notificationsEnabled = value;
                  DataService.instance.notificationEnabled = value;
                });
              },
              activeThumbColor: Colors.blueAccent,
            ),
          ),

          settingsTile(
            icon: Icons.dark_mode,
            title: "Dark Mode",
            textColor: textColor,
            cardColor: cardColor,
            trailing: Switch(
              value: darkModeEnabled,
              onChanged: (value) {
                setState(() {
                  darkModeEnabled = value;
                  DataService.instance.toggleTheme(value);
                });
              },
              activeThumbColor: Colors.blueAccent,
            ),
          ),

          const SizedBox(height: 24),

          // -------- LOGOUT --------
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                DataService.instance.logout();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Logout", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  // -------- HELPERS --------
  Widget sectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: TextStyle(color: color.withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.bold)),
    );
  }

  Widget settingsTile({
    required IconData icon,
    required String title,
    required Color textColor,
    required Color? cardColor,
    Widget? trailing,
    VoidCallback? onTap
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: textColor),
        title: Text(title, style: TextStyle(color: textColor)),
        trailing: trailing ?? Icon(Icons.arrow_forward_ios, size: 16, color: textColor.withOpacity(0.5)),
        onTap: onTap,
      ),
    );
  }

  // -------- CHANGE PASSWORD DIALOG --------
  void _showChangePasswordDialog(BuildContext context) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Change Password"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: oldPasswordController,
                    decoration: const InputDecoration(labelText: "Old Password"),
                    obscureText: true,
                    
                  ),
                  Padding(padding: const EdgeInsets.symmetric(vertical: 8)),
                  TextField(
                    controller: newPasswordController,
                    decoration: const InputDecoration(labelText: "New Password"),
                    obscureText: true,
                  ),
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 16.0),
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : () async {
                    final oldPassword = oldPasswordController.text.trim();
                    final newPassword = newPasswordController.text.trim();

                    if (oldPassword.isEmpty || newPassword.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please fill all fields")),
                      );
                      return;
                    }

                    setState(() {
                      isLoading = true;
                    });

                    final result = await DataService.instance.changeStudentPasswordWithVerification(
                      oldPassword: oldPassword,
                      newPassword: newPassword,
                    );

                    setState(() {
                      isLoading = false;
                    });

                    if (result == "success") {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Password changed successfully")),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(result)),
                      );
                    }
                  },
                  child: const Text("Change"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}