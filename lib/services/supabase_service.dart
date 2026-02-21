import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Sign up
  static Future<AuthResponse> signUp({
    required String identifier, // Student ID
    required String email,
    required String password,
    required String name,
    required String department,
    required String role, // 'student'
  }) async {
    // We do not include 'role' in metadata as it's handled in the database 'users' table
    final AuthResponse response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': name,
        'identifier': identifier,
        'department': department,
        'email': email,
      },
    );

    // If session is null but user exists, email confirmation is pending — this is expected behavior
    return response;
  }

  // Resend confirmation email
  static Future<void> resendConfirmationEmail(String email) async {
    await _client.auth.resend(
      type: OtpType.signup,
      email: email,
    );
  }

  // Login
  static Future<AuthResponse> login({
    required String identifier, // Can be Student ID or Email
    required String password,
    required String role,
  }) async {
    String email = identifier;

    // For students, if they provide a Student ID (no @), we resolve it to their email
    if (role == 'student' && !identifier.contains('@')) {
      try {
        final userData = await _client
            .from('users')
            .select('email')
            .eq('identifier', identifier)
            .maybeSingle();
        
        if (userData != null && userData['email'] != null) {
          email = userData['email'];
        } else {
          // Fallback for older accounts that might still use synthetic emails
          email = '$identifier@dlle.com';
        }
      } catch (e) {
        // Fallback for older accounts
        email = '$identifier@dlle.com';
      }
    }
        
    final AuthResponse response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.session == null && response.user != null) {
      throw Exception("Email not confirmed. Please check your inbox and confirm your email before logging in.");
    }

    return response;
  }

  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  static User? get currentUser => _client.auth.currentUser;
}
