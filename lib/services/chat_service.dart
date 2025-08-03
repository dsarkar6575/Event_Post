import 'package:myapp/core/api_constants.dart';
import 'package:myapp/models/chat_model.dart';
import 'package:myapp/models/message_model.dart';
import 'package:myapp/services/api_base_service.dart';

class ChatService {
  final ApiBaseService _apiService = ApiBaseService();

  Future<Chat> joinEventGroupChat(String postId) async {
    final response = await _apiService.post(
      ApiConstants.joinEventGroupChatEndpoint(postId),
      {},
    );
    return Chat.fromJson(response['chat']);
  }

  Future<Chat> startPrivateChat(String recipientId) async {
    final response = await _apiService.post(
      ApiConstants.startChatEndpoint,
      {'recipientId': recipientId},
    );
    return Chat.fromJson(response['chat']);
  }

  Future<Chat> createGroupChat(List<String> participantIds, String groupName) async {
    final response = await _apiService.post(
      ApiConstants.createGroupChatEndpoint,
      {'participantIds': participantIds, 'groupName': groupName},
    );
    return Chat.fromJson(response['chat']);
  }

  Future<List<Chat>> getUserChats() async {
    final response = await _apiService.get(ApiConstants.getUserChatsEndpoint);
    return (response as List).map((chat) => Chat.fromJson(chat)).toList();
  }

  Future<List<Message>> getChatMessages(String chatId) async {
    final response = await _apiService.get(ApiConstants.getChatMessagesEndpoint(chatId));
    return (response as List).map((message) => Message.fromJson(message)).toList();
  }

  Future<void> markMessageAsRead(String messageId) async {
    await _apiService.put(
      ApiConstants.markMessageAsReadEndpoint(messageId),
      {},
    );
  }

  // 🚨 NOTE: The sendMessage method has been removed from here.
  // It is now handled exclusively by the SocketService.
}