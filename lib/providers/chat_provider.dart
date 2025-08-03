import 'dart:async';
import 'package:flutter/material.dart';
import 'package:myapp/models/chat_model.dart';
import 'package:myapp/models/message_model.dart';
import 'package:myapp/services/chat_service.dart';
import 'package:myapp/services/socket_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  final SocketService _socketService = SocketService();
  StreamSubscription? _messageSubscription;
  String? _activeChatId;

  List<Chat> _userChats = [];
  List<Message> _currentChatMessages = [];
  bool _isLoading = false;
  String? _error;

  List<Chat> get userChats => _userChats;
  List<Message> get currentChatMessages => _currentChatMessages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ChatProvider() {
    _listenToMessages();
  }

   void _listenToMessages() {
    _messageSubscription = _socketService.messageStream.listen((message) {
      // ✅ 2. USE the new, reliable check.
      if (_activeChatId == message.chat) {
        // This message belongs to the screen the user is currently viewing.
        if (!_currentChatMessages.any((m) => m.id == message.id)) {
          _currentChatMessages.add(message);
          notifyListeners(); // This updates the open ChatScreen.
        }
      }

      // This part updates the main chat list's last message regardless.
      final chatIndex = _userChats.indexWhere((chat) => chat.id == message.chat);
      if (chatIndex != -1) {
        _userChats[chatIndex] = _userChats[chatIndex].copyWith(lastMessage: message);
        _userChats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        notifyListeners(); // This updates the ChatListScreen.
      }
    });
  }

  void sendMessage(String chatId, String content, MessageType type) {
    _socketService.sendMessage(
      chatRoomId: chatId,
      content: content,
      type: type,
    );
  }

  Future<void> fetchUserChats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _userChats = await _chatService.getUserChats();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Chat?> joinEventGroupChat(String postId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final chat = await _chatService.joinEventGroupChat(postId);
      final existingChatIndex = _userChats.indexWhere((c) => c.id == chat.id);
      if (existingChatIndex == -1) {
        _userChats.insert(0, chat);
      } else {
        _userChats[existingChatIndex] = chat;
      }
      return chat;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchChatMessages(String chatId) async {
    _isLoading = true;
    _currentChatMessages = [];
    _error = null;
    // ✅ 3. SET the active chat ID when the user opens a chat screen.
    _activeChatId = chatId;
    notifyListeners();
    try {
      _currentChatMessages = await _chatService.getChatMessages(chatId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearActiveChat() {
    _activeChatId = null;
  }

  
  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }
}
