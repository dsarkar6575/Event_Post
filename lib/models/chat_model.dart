import 'package:myapp/models/message_model.dart';
import 'package:myapp/models/user_model.dart';

class Chat {
  final String id;
  final String? chatName;
  final bool isGroupChat;
  final List<User> participants;
  final Message? lastMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  Chat({
    required this.id,
    this.chatName,
    this.isGroupChat = false,
    required this.participants,
    this.lastMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  Chat copyWith({
    String? id,
    String? chatName,
    bool? isGroupChat,
    List<User>? participants,
    Message? lastMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Chat(
      id: id ?? this.id,
      chatName: chatName ?? this.chatName,
      isGroupChat: isGroupChat ?? this.isGroupChat,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['_id'],
      chatName: json['chatName'],
      isGroupChat: json['isGroupChat'] ?? false,
      participants: (json['participants'] as List)
          .map((p) => User.fromJson(p))
          .toList(),
      lastMessage: json['lastMessage'] != null
          ? Message.fromJson(json['lastMessage'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'chatName': chatName,
      'isGroupChat': isGroupChat,
      'participants': participants.map((p) => p.toJson()).toList(),
      'lastMessage': lastMessage?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
