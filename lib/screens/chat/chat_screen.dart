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
  late final ChatProvider _chatProvider;

  @override
  void initState() {
    super.initState();
    // Get the provider instance once
    _chatProvider = Provider.of<ChatProvider>(context, listen: false);

    // Add a listener to scroll down whenever the message list changes
    _chatProvider.addListener(_onMessagesUpdated);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInitialMessages();
    });
  }

  Future<void> _fetchInitialMessages() async {
    // We only need to fetch historical messages once when the screen opens.
    await _chatProvider.fetchChatMessages(widget.chatId);
    _scrollToBottom();
  }

  // This function will be called whenever notifyListeners() is called in ChatProvider
  void _onMessagesUpdated() {
    _scrollToBottom();
  }

  void _scrollToBottom() {
    // Ensure the view is built before trying to scroll
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  // ✅ CORRECTED: This method is now synchronous.
  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final content = _messageController.text.trim();
    _messageController.clear();

    // Fire-and-forget: Send the message via the provider, which uses Socket.IO.
    // The message will appear when the server broadcasts it back.
    _chatProvider.sendMessage(widget.chatId, content, MessageType.text);
  }

  @override
  void dispose() {
    // ✅ IMPORTANT: Remove the listener to prevent memory leaks
    _chatProvider.removeListener(_onMessagesUpdated);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?.id;
    // Use the passed-in chat name or fallback
    final chatTitle = widget.chat?.chatName ?? 'Chat';

    return Scaffold(
      appBar: AppBar(
        title: Text(chatTitle),
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatProvider>(
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
                // Use ListView.separated for better spacing and performance
                return ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16.0),
                  itemCount: chatProvider.currentChatMessages.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final message = chatProvider.currentChatMessages[index];
                    final isMe = message.sender.id == currentUserId;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? Theme.of(context).primaryColor : Colors.grey[200],
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Text(
                              isMe ? 'You' : message.sender.username,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: isMe ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              message.content,
                              style: TextStyle(color: isMe ? Colors.white : Colors.black87),
                            ),
                            const SizedBox(height: 5.0),
                            Text(
                              timeago.format(message.createdAt),
                              style: TextStyle(
                                color: isMe ? Colors.white60 : Colors.black45,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Input area
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(top: BorderSide(color: Colors.grey[200]!))),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _messageController,
                      labelText: 'Type a message...',
                      onSubmitted: (value) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.send, color: const Color.fromARGB(255, 83, 97, 104)),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}