import 'package:myapp/models/user_model.dart';

class Post {
  final String id;
  final String authorId;
  final User? author;
  final String title;
  final String description;
  final List<String> mediaUrls;
  final bool isEvent;
  final DateTime? eventDateTime;
  final String? location;
  final List<String> interestedUsers;
  final int interestedCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Post({
    required this.id,
    required this.authorId,
    this.author,
    required this.title,
    required this.description,
    this.mediaUrls = const [],
    this.isEvent = false,
    this.eventDateTime,
    this.location,
    this.interestedUsers = const [],
    this.interestedCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
  print('🔥 Parsing Post JSON: $json');

  // Safe author parsing
  User? parsedAuthor;
  String authorId = '';

  if (json['author'] is Map<String, dynamic>) {
    try {
      parsedAuthor = User.fromJson(json['author']);
      authorId = json['author']['_id']?.toString() ?? '';
    } catch (e) {
      print('❌ Error parsing author: $e');
    }
  } else if (json['author'] is String) {
    authorId = json['author'];
  } else {
    print('❗ Unexpected author type: ${json['author']}');
  }

  return Post(
    id: json['_id']?.toString() ?? 'UNKNOWN_ID',
    authorId: authorId,
    author: parsedAuthor,
    title: json['title']?.toString() ?? 'Untitled',
    description: json['description']?.toString() ?? '',
    mediaUrls: (json['mediaUrls'] is List)
        ? List<String>.from(json['mediaUrls'].whereType<String>())
        : [],
    isEvent: json['isEvent'] == true,
    eventDateTime: json['eventDateTime'] != null
        ? DateTime.tryParse(json['eventDateTime'].toString())
        : null,
    location: json['location']?.toString(),
    interestedUsers: (json['interestedUsers'] is List)
        ? List<String>.from(json['interestedUsers'].whereType<String>())
        : [],
    interestedCount: json['interestedCount'] is int
        ? json['interestedCount']
        : int.tryParse(json['interestedCount']?.toString() ?? '0') ?? 0,
    createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
        DateTime.now(),
    updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
        DateTime.now(),
  );
}


  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'author': authorId,
      'title': title,
      'description': description,
      'mediaUrls': mediaUrls,
      'isEvent': isEvent,
      'eventDateTime': eventDateTime?.toIso8601String(),
      'location': location,
      'interestedUsers': interestedUsers,
      'interestedCount': interestedCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
