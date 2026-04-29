class Announcement {
  final String id;
  final String title;
  final String body;
  final bool isImportant;
  final DateTime createdAt;
  final String? category;

  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.isImportant,
    required this.createdAt,
    this.category,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        isImportant: json['isImportant'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
        category: json['category'] as String?,
      );
}
