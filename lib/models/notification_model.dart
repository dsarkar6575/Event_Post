import 'package:myapp/models/user_model.dart';

enum NotificationType { like, comment, message, follow, postInterest }

class AppNotification {
  final String id;
  final User recipient;
  final User? sender;
  final String? entityId; // ID of the post, message, etc.
  final NotificationType type;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.recipient,
    this.sender,
    this.entityId,
    required this.type,
    required this.message,
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['_id'],
      recipient: User.fromJson(json['recipient']),
      sender: json['sender'] != null ? User.fromJson(json['sender']) : null,
      entityId: json['entityId'],
      type: NotificationType.values.firstWhere(
          (e) => e.toString().split('.').last == json['type'],
          orElse: () => NotificationType.message), // Default
      message: json['message'],
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'recipient': recipient.toJson(),
      'sender': sender?.toJson(),
      'entityId': entityId,
      'type': type.toString().split('.').last,
      'message': message,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  AppNotification copyWith({
    bool? isRead,
  }) {
    return AppNotification(
      id: id,
      recipient: recipient,
      sender: sender,
      entityId: entityId,
      type: type,
      message: message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}