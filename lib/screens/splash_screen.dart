import 'dart:async';

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
  /// Maximum time we wait for the entire session-restore flow before
  /// giving up and sending the user to the login screen.
  static const _sessionTimeout = Duration(seconds: 10);

  /// Prevents double navigation (e.g. timeout fires after normal navigation).
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    // Wait until the first frame is rendered so the Navigator is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkSession());
  }

  Future<void> _checkSession() async {
    try {
      // Wrap the entire restore flow in a timeout so the app never hangs.
      await _restoreSession().timeout(
        _sessionTimeout,
        onTimeout: () {
          debugPrint('[SplashScreen] Session restore timed out');
          _navigateTo(const LoginScreen());
        },
      );
    } catch (e) {
      debugPrint('[SplashScreen] Session restore error: $e');
      _navigateTo(const LoginScreen());
    }
  }

  Future<void> _restoreSession() async {
    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;

    // ── No session at all → login ──────────────────────────────────
    if (session == null) {
      _navigateTo(const LoginScreen());
      return;
    }

    // ── Session exists but token may be expired → try to refresh ───
    if (session.isExpired) {
      debugPrint('[SplashScreen] Session token expired, attempting refresh…');
      try {
        final refreshResponse = await supabase.auth.refreshSession();
        if (refreshResponse.session == null) {
          debugPrint('[SplashScreen] Refresh returned no session');
          await _signOutAndLogin();
          return;
        }
      } catch (e) {
        debugPrint('[SplashScreen] Token refresh failed: $e');
        await _signOutAndLogin();
        return;
      }
    }

    final user = supabase.auth.currentUser;
    if (user == null) {
      _navigateTo(const LoginScreen());
      return;
    }

    // ── Fetch user profile from the database ───────────────────────
    final userData = await supabase
        .from('users')
        .select('role, full_name, identifier, department')
        .eq('id', user.id)
        .maybeSingle();

    if (userData == null) {
      await _signOutAndLogin();
      return;
    }

    final role = userData['role'] ?? 'student';
    final identifier = userData['identifier'] ?? '';

    if (role == 'student') {
      await DataService.instance.login(identifier);
      _navigateTo(const DashboardScreen());
    } else {
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
  }

  /// Sign out any stale session and navigate to the login screen.
  Future<void> _signOutAndLogin() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {
      // Ignore sign-out errors — we're heading to login anyway.
    }
    _navigateTo(const LoginScreen());
  }

  void _navigateTo(Widget screen) {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
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
