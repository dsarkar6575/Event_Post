import 'package:flutter/material.dart';
import 'package:myapp/models/chat_model.dart';
import 'package:myapp/models/message_model.dart';
import 'package:myapp/services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  List<Chat> _userChats = [];
  List<Message> _currentChatMessages = [];
  bool _isLoading = false;
  String? _error;

  List<Chat> get userChats => _userChats;
  List<Message> get currentChatMessages => _currentChatMessages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchUserChats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _userChats = await _chatService.getUserChats();
    } catch (e) {
      _error = e.toString();
      print('Fetch User Chats Error: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Chat?> startPrivateChat(String recipientId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final chat = await _chatService.startPrivateChat(recipientId);
      // Optional: Add to userChats if it's a new chat
      if (!_userChats.any((c) => c.id == chat.id)) {
        _userChats.insert(0, chat);
      }
      return chat;
    } catch (e) {
      _error = e.toString();
      print('Start Private Chat Error: $_error');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Chat?> createGroupChat(List<String> participantIds, String groupName) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final chat = await _chatService.createGroupChat(participantIds, groupName);
      _userChats.insert(0, chat);
      return chat;
    } catch (e) {
      _error = e.toString();
      print('Create Group Chat Error: $_error');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchChatMessages(String chatId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _currentChatMessages = await _chatService.getChatMessages(chatId);
    } catch (e) {
      _error = e.toString();
      print('Fetch Chat Messages Error: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String chatId, String content, MessageType type) async {
    _error = null;
    // Don't set _isLoading to true for sending message to avoid UI block
    try {
      final message = await _chatService.sendMessage(chatId, content, type);
      _currentChatMessages.add(message);
      // Update the last message in _userChats
      final chatIndex = _userChats.indexWhere((chat) => chat.id == chatId);
      if (chatIndex != -1) {
        _userChats[chatIndex] = _userChats[chatIndex].copyWith(lastMessage: message);
        _userChats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt)); // Sort by most recent
      }
    } catch (e) {
      _error = e.toString();
      print('Send Message Error: $_error');
    } finally {
      notifyListeners();
    }
  }

  Future<void> markMessageAsRead(String messageId) async {
    _error = null;
    try {
      await _chatService.markMessageAsRead(messageId);
      final messageIndex = _currentChatMessages.indexWhere((msg) => msg.id == messageId);
      if (messageIndex != -1) {
        // This part needs to be more robust, ideally the backend sends back the updated message
        // For now, we'll assume it worked and just mark it locally
        if (!_currentChatMessages[messageIndex].readBy.contains('current_user_id_placeholder')) {
          _currentChatMessages[messageIndex].readBy.add('current_user_id_placeholder');
        }
      }
    } catch (e) {
      _error = e.toString();
      print('Mark Message As Read Error: $_error');
    } finally {
      notifyListeners();
    }
  }

  // Method to add new message received via Socket.IO
  void addReceivedMessage(Message message) {
    if (_currentChatMessages.any((msg) => msg.id == message.id)) return; // Avoid duplicates
    _currentChatMessages.add(message);
    // Also update the last message in _userChats
    final chatIndex = _userChats.indexWhere((chat) => chat.id == message.chat);
    if (chatIndex != -1) {
      _userChats[chatIndex] = _userChats[chatIndex].copyWith(lastMessage: message);
      _userChats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }
    notifyListeners();
  }
}