import 'package:myapp/models/user_model.dart';

enum MessageType { text, image, video }

class Message {
  final String id;
  final User sender;
  final String chat;
  final String content;
  final MessageType type;
  final List<String> readBy; // User IDs
  final DateTime createdAt;

  Message({
    required this.id,
    required this.sender,
    required this.chat,
    required this.content,
    this.type = MessageType.text,
    this.readBy = const [],
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['_id'],
      sender: User.fromJson(json['sender']),
      chat: json['chat'],
      content: json['content'],
      type: MessageType.values.firstWhere(
          (e) => e.toString().split('.').last == json['type'],
          orElse: () => MessageType.text),
      readBy: List<String>.from(json['readBy'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'sender': sender.toJson(),
      'chat': chat,
      'content': content,
      'type': type.toString().split('.').last,
      'readBy': readBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}