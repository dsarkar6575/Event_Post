import 'package:flutter/material.dart';
import 'package:myapp/widgets/custom_text_field.dart';
import 'package:provider/provider.dart';
import 'package:myapp/models/chat_model.dart';
import 'package:myapp/models/message_model.dart';
import 'package:myapp/providers/auth_provider.dart';
import 'package:myapp/providers/chat_provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatScreen extends StatefulWidget {
  final String chatId;
  final Chat? chat; // Optional, can be passed from chat list for convenience

  const ChatScreen({super.key, required this.chatId, this.chat});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Chat? _currentChat;

  @override
  void initState() {
    super.initState();
    _currentChat = widget.chat;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchChatDetailsAndMessages();
    });
  }

  Future<void> _fetchChatDetailsAndMessages() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    if (_currentChat == null) {
      // If chat object not passed, fetch it (e.g., if navigating directly)
      final chats = await chatProvider.fetchUserChats(); // This will update _userChats
      _currentChat = chatProvider.userChats.firstWhere((c) => c.id == widget.chatId);
    }

    await chatProvider.fetchChatMessages(widget.chatId);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final content = _messageController.text.trim();
    _messageController.clear(); // Clear immediately for better UX

    await chatProvider.sendMessage(widget.chatId, content, MessageType.text);
    _scrollToBottom(); // Scroll after sending
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentChat?.chatName ?? 'Chat'),
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          if (chatProvider.isLoading && chatProvider.currentChatMessages.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (chatProvider.error != null) {
            return Center(child: Text('Error: ${chatProvider.error}'));
          }
          if (chatProvider.currentChatMessages.isEmpty) {
            return const Center(child: Text('No messages yet. Say hello!'));
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8.0),
                  itemCount: chatProvider.currentChatMessages.length,
                  itemBuilder: (context, index) {
                    final message = chatProvider.currentChatMessages[index];
                    final isMe = message.sender.id == currentUserId;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue[100] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Text(
                              isMe ? 'You' : message.sender.username,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            const SizedBox(height: 4.0),
                            Text(message.content),
                            const SizedBox(height: 4.0),
                            Text(
                              timeago.format(message.createdAt),
                              style: const TextStyle(color: Colors.grey, fontSize: 10),
                            ),
                            if (isMe) // Show read status for your messages
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Icon(
                                  message.readBy.contains(currentUserId)
                                      ? Icons.done_all // All read
                                      : Icons.done, // Sent
                                  size: 14,
                                  color: message.readBy.contains(currentUserId) ? Colors.blue : Colors.grey,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _messageController,
                        labelText: 'Type a message...',
                        onSubmitted: (value) => _sendMessage(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}