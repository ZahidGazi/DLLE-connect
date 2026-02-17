import 'package:app/screens/admin_announcement.dart';
import 'package:app/screens/admin_setting%20screen.dart';
import 'package:app/screens/events_screen.dart';
import 'package:app/screens/manage_events.dart';
import 'package:flutter/material.dart';
import 'manage_stu_screen.dart';

class CoordinatorDashboardScreen extends StatelessWidget {
  const CoordinatorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          "Dashboard",
        ),
        centerTitle: true,
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          ),
        ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Manage",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [

                DashboardCard(
                  icon: Icons.group,
                  title: "Manage Students",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ManageStudentsScreen()),
                    );
                  },
                ),


                DashboardCard(
                  icon: Icons.campaign,
                  title: "Announcements", onTap: () {
                    Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AnnouncementScreens()),
                  );
                },
                ),

                DashboardCard(
                  icon: Icons.event,
                  title: "Create Event", onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ManageEventsScreen()),
                    );
                },
                ),

                DashboardCard(
                  icon: Icons.settings,
                  title: "Settings", onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminSettingsScreen()),
                    );
                },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- DASHBOARD CARD ----------------
class DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const DashboardCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1F2933),
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.blue.withOpacity(0.15),
              child: Icon(
                icon,
                size: 28,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
