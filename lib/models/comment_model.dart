class Comment {
  final String id;
  final String content;
  final String authorUsername;
  final String? authorProfileImageUrl;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.content,
    required this.authorUsername,
    this.authorProfileImageUrl,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['_id'],
      content: json['content'],
      authorUsername: json['author']['username'],
      authorProfileImageUrl: json['author']['profileImageUrl'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
