// screens/chat/chat_feed_screen.dart
import 'package:flutter/material.dart';
import 'package:myapp/models/post_model.dart';
import 'package:myapp/screens/chat/chat_room_screen.dart';
import 'package:myapp/services/chat_service.dart';

class ChatFeedScreen extends StatefulWidget {
  const ChatFeedScreen({super.key});

  @override
  State<ChatFeedScreen> createState() => _ChatFeedScreenState();
}

class _ChatFeedScreenState extends State<ChatFeedScreen> {
  List<Post> joinedChats = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchJoinedChats();
  }

  Future<void> fetchJoinedChats() async {
    try {
      final chats = await ChatService().getJoinedChats(); // Create this in next step
      setState(() {
        joinedChats = chats;
        isLoading = false;
      });
    } catch (e) {
      print("Failed to fetch chats: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chats")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: joinedChats.length,
              itemBuilder: (context, index) {
                final post = joinedChats[index];
                return ListTile(
                  leading: const Icon(Icons.chat_bubble),
                  title: Text(post.title),
                  subtitle: Text(post.description),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatRoomScreen(postId: post.id, postTitle: post.title),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
