class User {
  final String id;
  final String? email; // Nullable
  final String username;
  final String? bio;
  final String? profileImageUrl;
  final List<String> followers;
  final List<String> following;
  final DateTime createdAt;
  final String userType; // ✅ Added for personal/corporate

  User({
    required this.id,
    this.email, // ✅ Removed required
    required this.username,
    this.bio,
    this.profileImageUrl,
    this.followers = const [],
    this.following = const [],
    required this.createdAt,
    this.userType = 'personal', // default value
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      email: json['email'] as String?,
      username: json['username'] ?? '',
      bio: json['bio'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?, // ✅ simpler
      followers: (json['followers'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      following: (json['following'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      userType: json['userType'] ?? 'personal', // ✅ handle corporate/personal
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
      'userType': userType,
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
    String? userType,
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
      userType: userType ?? this.userType,
    );
  }
}
