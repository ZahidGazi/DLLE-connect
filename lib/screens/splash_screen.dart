import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'data_service.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import 'coordinator_dashboard.dart';

/// Shown at app startup. Checks for an existing Supabase session and
/// restores the user's state before routing to the correct screen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;

      // No active session — send to login
      if (session == null) {
        _navigateTo(const LoginScreen());
        return;
      }

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        _navigateTo(const LoginScreen());
        return;
      }

      // Fetch the user's role and profile from the database
      final userData = await Supabase.instance.client
          .from('users')
          .select('role, full_name, identifier, department')
          .eq('id', user.id)
          .maybeSingle();

      if (userData == null) {
        // User record not found — clear any stale session and go to login
        await Supabase.instance.client.auth.signOut();
        _navigateTo(const LoginScreen());
        return;
      }

      final role = userData['role'] ?? 'student';
      final identifier = userData['identifier'] ?? '';

      if (role == 'student') {
        // Restore full student session via DataService (fetches events, hours, etc.)
        await DataService.instance.login(identifier);
        _navigateTo(const DashboardScreen());
      } else {
        // Restore admin session
        DataService.instance.updateProfile(
          name: userData['full_name'] ?? '',
          id: identifier,
          course: 'Admin',
        );
        await DataService.instance.saveLoginSession(identifier);
        DataService.instance.isLoggedIn = true;
        DataService.instance.studentId = identifier;
        DataService.instance.studentName = userData['full_name'] ?? '';
        _navigateTo(const CoordinatorDashboardScreen());
      }
    } catch (e) {
      debugPrint('[SplashScreen] Session restore error: $e');
      // On any error, fall back to login screen
      _navigateTo(const LoginScreen());
    }
  }

  void _navigateTo(Widget screen) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 130,
              child: Image.asset(
                'assets/login_image.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.account_circle, size: 100, color: Colors.blueAccent),
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Restoring your session…',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
