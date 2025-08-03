// screens/chat/chat_room_screen.dart
import 'package:flutter/material.dart';
import 'package:myapp/services/chat_service.dart';

class ChatRoomScreen extends StatefulWidget {
  final String postId;
  final String postTitle;

  const ChatRoomScreen({super.key, required this.postId, required this.postTitle});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> messages = []; // [{sender, text, time}]
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchMessages();
  }

  Future<void> fetchMessages() async {
    try {
      final msgs = await ChatService().getMessages(widget.postId);
      setState(() {
        messages = msgs;
        isLoading = false;
      });
    } catch (e) {
      print("Fetch error: $e");
    }
  }

  Future<void> sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    await ChatService().sendMessage(widget.postId, text);
    await fetchMessages(); // refresh messages
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.postTitle)),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      return ListTile(
                        title: Text(msg['sender']),
                        subtitle: Text(msg['text']),
                        trailing: Text(msg['time']),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: 'Type a message...'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: sendMessage,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
