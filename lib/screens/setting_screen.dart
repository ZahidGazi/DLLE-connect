import 'package:flutter/material.dart';
import 'data_service.dart';
import 'login_screen.dart';

class StudentSettingsScreen extends StatefulWidget {
  const StudentSettingsScreen({super.key});

  @override
  State<StudentSettingsScreen> createState() =>
      _StudentSettingsScreenState();
}

class _StudentSettingsScreenState extends State<StudentSettingsScreen> {
  bool notificationsEnabled = true;
  bool darkModeEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),

      appBar: AppBar(
        title: const Text("Settings"),
        centerTitle: true,
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // -------- PROFILE --------
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2933),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DataService.instance.studentName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "ID: ${DataService.instance.studentId}",
                      style:
                      const TextStyle(color: Colors.white70),
                    ),
                  ],
                )
              ],
            ),
          ),

          const SizedBox(height: 24),

          // -------- APP SETTINGS --------
          sectionTitle("App Settings"),

          settingsTile(
            icon: Icons.notifications,
            title: "Notifications",
            trailing: Switch(
              value: notificationsEnabled,
              onChanged: (value) {
                setState(() => notificationsEnabled = value);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      value
                          ? "Notifications Enabled"
                          : "Notifications Disabled",
                    ),
                  ),
                );
              },
              activeColor: Colors.blueAccent,
            ),
          ),

          settingsTile(
            icon: Icons.dark_mode,
            title: "Dark Mode",
            trailing: Switch(
              value: darkModeEnabled,
              onChanged: (value) {
                setState(() => darkModeEnabled = value);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      value
                          ? "Dark Mode Enabled"
                          : "Dark Mode Disabled",
                    ),
                  ),
                );
              },
              activeColor: Colors.blueAccent,
            ),
          ),

          const SizedBox(height: 24),

          // -------- SUPPORT --------
          sectionTitle("Support"),

          settingsTile(
            icon: Icons.help_outline,
            title: "Help",
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => infoDialog(
                  "Help",
                  "Contact your coordinator for support regarding events or hours.",
                ),
              );
            },
          ),

          settingsTile(
            icon: Icons.info_outline,
            title: "About App",
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => infoDialog(
                  "About DLLE Connect",
                  "DLLE Connect helps students track events, upload proof, and manage DLLE hours.",
                ),
              );
            },
          ),

          const SizedBox(height: 30),

          // -------- LOGOUT --------
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                DataService.instance.logout();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const LoginScreen()),
                      (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Logout",
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------- HELPERS --------
  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget settingsTile({
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2933),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(title,
            style: const TextStyle(color: Colors.white)),
        trailing: trailing ??
            const Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.white54),
        onTap: onTap,
      ),
    );
  }

  AlertDialog infoDialog(String title, String content) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1F2933),
      title: Text(title,
          style: const TextStyle(color: Colors.white)),
      content: Text(content,
          style: const TextStyle(color: Colors.white70)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close",
              style:
              TextStyle(color: Colors.lightBlueAccent)),
        ),
      ],
    );
  }
}
