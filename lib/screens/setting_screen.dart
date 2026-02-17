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
              activeColor: Colors.blueAccent,
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
              activeColor: Colors.blueAccent,
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
}