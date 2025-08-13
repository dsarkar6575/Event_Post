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
    // Fetch initial chat list when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatProvider>(context, listen: false).fetchUserChats();
    });
  }

  // Handle pull-to-refresh
  Future<void> _refreshChats() async {
    await Provider.of<ChatProvider>(context, listen: false).fetchUserChats();
  }

  @override
  Widget build(BuildContext context) {
    // We only need the user ID here, so no need to listen for auth changes
    final currentUserId = Provider.of<AuthProvider>(context, listen: false).currentUser?.id;

    return Scaffold(
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

                // ✅ IMPROVED LOGIC: Differentiate between Group and Private chats
                String displayName;
                Widget displayAvatar;
                
                if (chat.isGroupChat) {
                  displayName = chat.chatName ?? 'Group Chat';
                  displayAvatar = CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColorLight,
                    child: const Icon(Icons.group, color: Colors.white),
                  );
                } else {
                  final otherParticipant = chat.participants.firstWhere(
                        (p) => p.id != currentUserId,
                    orElse: () => chat.participants.first, // Fallback
                  );
                  displayName = otherParticipant.username;
                  displayAvatar = CircleAvatar(
                    backgroundImage: otherParticipant.profileImageUrl != null
                        ? NetworkImage(otherParticipant.profileImageUrl!)
                        : null,
                    child: otherParticipant.profileImageUrl == null
                        ? Text(otherParticipant.username[0].toUpperCase())
                        : null,
                  );
                }

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: ListTile(
                    leading: displayAvatar,
                    title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      chat.lastMessage != null
                          ? '${chat.lastMessage!.sender.username}: ${chat.lastMessage!.content}'
                          : 'No messages yet.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: chat.lastMessage != null
                        ? Text(
                            timeago.format(chat.lastMessage!.createdAt, locale: 'en_short'),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          )
                        : null,
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        AppRouter.chatRoute.replaceFirst(':chatId', chat.id),
                        arguments: chat, // Pass the chat object for convenience
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