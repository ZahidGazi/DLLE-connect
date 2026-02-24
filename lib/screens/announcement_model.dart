class Announcement {
  final String? id;
  final String title;
  final String message;
  final DateTime createdAt;
  final String? imageUrl;

  Announcement({
    this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    this.imageUrl,
  });

  /// Returns a human-readable date string from createdAt
  String get formattedDate {
    return "${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}";
  }
}
