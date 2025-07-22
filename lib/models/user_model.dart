class User {
  final String id;
  final String? email; // ✅ Made nullable
  final String username;
  final String? bio;
  final String? profileImageUrl;
  final List<String> followers;
  final List<String> following;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email, // now nullable
    required this.username,
    this.bio,
    this.profileImageUrl,
    this.followers = const [],
    this.following = const [],
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      email: json['email'] as String?, // ✅ handles missing or null
      username: json['username'] ?? '',
      bio: json['bio'] as String?,
       profileImageUrl: json['profileImageUrl'] is String
        ? json['profileImageUrl'] as String
        : null,
      followers: List<String>.from(json['followers'] ?? []),
      following: List<String>.from(json['following'] ?? []),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(), // fallback
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'email': email,
      'username': username,
      'bio': bio,
      'profileImageUrl': profileImageUrl,
      'followers': followers,
      'following': following,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? username,
    String? bio,
    String? profileImageUrl,
    List<String>? followers,
    List<String>? following,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
