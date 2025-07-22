import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/models/post_model.dart';
import 'package:myapp/providers/post_provider.dart';
import 'package:intl/intl.dart';
import 'package:myapp/providers/auth_provider.dart';
import 'package:myapp/utils/app_router.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  Post? _post;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPostDetails();
  }

  Future<void> _fetchPostDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      _post = await Provider.of<PostProvider>(context, listen: false).postService.getPostById(widget.postId);
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Post Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Error: $_error')),
      );
    }

    if (_post == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Post Not Found')),
        body: const Center(child: Text('Post not found.')),
      );
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?.id;
    final isAuthor = currentUserId == _post!.authorId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Details'),
        actions: [
          if (isAuthor)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // TODO: Navigate to Edit Post Screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit Post functionality not yet implemented.')),
                );
              },
            ),
          if (isAuthor)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                await Provider.of<PostProvider>(context, listen: false).deletePost(_post!.id);
                if (mounted) {
                  Navigator.pop(context); // Go back after deleting
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _post!.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            InkWell(
              onTap: () {
                if (_post!.author?.id != null) {
                  Navigator.of(context).pushNamed(AppRouter.profileRoute.replaceFirst(':userId', _post!.author!.id));
                }
              },
              child: Text(
                'By ${_post!.author?.username ?? 'Unknown'}',
                style: const TextStyle(fontSize: 16, color: Colors.blue),
              ),
            ),
            const SizedBox(height: 16.0),
            if (_post!.mediaUrls.isNotEmpty)
              Image.network(
                _post!.mediaUrls.first, // Display first image for simplicity
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported),
              ),
            const SizedBox(height: 16.0),
            Text(
              _post!.description,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16.0),
            if (_post!.isEvent) ...[
              const Divider(),
              const Text(
                'Event Details:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  const Icon(Icons.event),
                  const SizedBox(width: 8),
                  Text(
                    _post!.eventDateTime != null
                        ? DateFormat('EEE, MMM d, yyyy HH:mm').format(_post!.eventDateTime!)
                        : 'Date not set',
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  const Icon(Icons.location_on),
                  const SizedBox(width: 8),
                  Text(_post!.location ?? 'Location not specified'),
                ],
              ),
              const SizedBox(height: 16.0),
            ],
            Consumer<PostProvider>(
              builder: (context, postProvider, child) {
                final isInterested = _post!.interestedUsers.contains(currentUserId);
                return ElevatedButton.icon(
                  onPressed: currentUserId == null
                      ? null
                      : () async {
                          await postProvider.togglePostInterest(_post!.id, currentUserId);
                          // Re-fetch post details to update UI accurately
                          await _fetchPostDetails();
                        },
                  icon: Icon(isInterested ? Icons.star : Icons.star_border),
                  label: Text(
                    isInterested ? 'Interested (${_post!.interestedCount})' : 'Mark as Interested (${_post!.interestedCount})',
                  ),
                );
              },
            ),
            const SizedBox(height: 16.0),
            Text('Posted: ${DateFormat('MMM d, yyyy').format(_post!.createdAt)}'),
            Text('Last Updated: ${DateFormat('MMM d, yyyy').format(_post!.updatedAt)}'),
          ],
        ),
      ),
    );
  }
}