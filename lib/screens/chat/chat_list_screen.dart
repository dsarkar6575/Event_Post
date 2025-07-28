import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/providers/auth_provider.dart';
import 'package:myapp/providers/chat_provider.dart';
import 'package:myapp/utils/app_router.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatProvider>(context, listen: false).fetchUserChats();
    });
  }

  Future<void> _refreshChats() async {
    await Provider.of<ChatProvider>(context, listen: false).fetchUserChats();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add),
            onPressed: () {
              // TODO: Implement create group chat UI
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Create Group Chat not yet implemented.')),
              );
            },
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          if (chatProvider.isLoading && chatProvider.userChats.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (chatProvider.error != null) {
            return Center(child: Text('Error: ${chatProvider.error}'));
          }
          if (chatProvider.userChats.isEmpty) {
            return const Center(child: Text('No chats yet. Start a new conversation!'));
          }

          return RefreshIndicator(
            onRefresh: _refreshChats,
            child: ListView.builder(
              itemCount: chatProvider.userChats.length,
              itemBuilder: (context, index) {
                final chat = chatProvider.userChats[index];
                final otherParticipant = chat.participants.firstWhere(
                  (p) => p.id != currentUserId,
                  orElse: () => chat.participants.first, // Fallback for single participant in group or if current user is only one
                );

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: otherParticipant.profileImageUrl != null
                          ? NetworkImage(otherParticipant.profileImageUrl!)
                          : null,
                      child: otherParticipant.profileImageUrl == null
                          ? Text(otherParticipant.username[0].toUpperCase())
                          : null,
                    ),
                    title: Text(chat.isGroupChat ? chat.chatName! : otherParticipant.username),
                    subtitle: Text(
                      chat.lastMessage != null
                          ? '${chat.lastMessage!.sender.username}: ${chat.lastMessage!.content}'
                          : 'No messages yet.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: chat.lastMessage != null
                        ? Text(timeago.format(chat.lastMessage!.createdAt))
                        : null,
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        AppRouter.chatRoute.replaceFirst(':chatId', chat.id),
                        arguments: chat, // Pass the chat object for easier access
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}