import 'package:flutter/material.dart';
import 'package:myapp/models/comment_model.dart';
import 'package:myapp/services/comment_service.dart';
import 'package:provider/provider.dart';
import 'package:myapp/providers/auth_provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class CommentsScreen extends StatefulWidget {
  final String postId;

  const CommentsScreen({super.key, required this.postId});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Comment> _comments = [];
  bool _isLoading = true;

  Future<void> _fetchComments() async {
    setState(() => _isLoading = true);
    try {
      final comments = await CommentService().getComments(widget.postId);
      setState(() {
        _comments.clear();
        _comments.addAll(comments);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load comments: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

 Future<void> _submitComment() async {
  final content = _controller.text.trim();
  if (content.isEmpty) return;

  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  final user = authProvider.currentUser;
  final token = authProvider.token;

  if (user == null || token == null) return;

  try {
    final newComment = await CommentService().createComment(widget.postId, content, token);
    setState(() {
      _comments.insert(0, newComment);
      _controller.clear();
    });
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error posting comment: $e')),
    );
  }
}


  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comments')),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                    ? const Center(child: Text('No comments yet.'))
                    : ListView.builder(
                        reverse: true,
                        itemCount: _comments.length,
                        itemBuilder: (ctx, index) {
                          final comment = _comments[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: comment.authorProfileImageUrl != null
                                  ? NetworkImage(comment.authorProfileImageUrl!)
                                  : null,
                              child: comment.authorProfileImageUrl == null
                                  ? Text(comment.authorUsername[0].toUpperCase())
                                  : null,
                            ),
                            title: Text(comment.authorUsername),
                            subtitle: Text(comment.content),
                            trailing: Text(
                              timeago.format(comment.createdAt),
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        },
                      ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Write a comment...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _submitComment,
                  child: const Text('Post'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
