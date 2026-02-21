/// AppUser model — renamed from 'User' to avoid conflict with Supabase's User class.
/// Note: The primary user/student data model used throughout the app is [Student] in event_model.dart.
class AppUser {
  final String name;
  final String id;
  final String course;

  AppUser({
    required this.name,
    required this.id,
    required this.course,
  });
}
