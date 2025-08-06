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
      _post = await Provider.of<PostProvider>(
        context,
        listen: false,
      ).postService.getPostById(widget.postId);
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
                  const SnackBar(
                    content: Text(
                      'Edit Post functionality not yet implemented.',
                    ),
                  ),
                );
              },
            ),
          if (isAuthor)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                await Provider.of<PostProvider>(
                  context,
                  listen: false,
                ).deletePost(_post!.id);
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
                  Navigator.of(context).pushNamed(
                    AppRouter.profileRoute.replaceFirst(
                      ':userId',
                      _post!.author!.id,
                    ),
                  );
                }
              },
              child: Text(
                'By ${_post!.author?.username ?? 'Unknown'}',
                style: const TextStyle(fontSize: 16, color: Colors.blue),
              ),
            ),
            const SizedBox(height: 16.0),
            if (_post!.mediaUrls.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:
                    _post!.mediaUrls.map((url) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            url,
                            fit:
                                BoxFit
                                    .contain, // Preserve original aspect ratio
                            width: double.infinity,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                            errorBuilder:
                                (context, error, stackTrace) =>
                                    const Icon(Icons.image_not_supported),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            const SizedBox(height: 16.0),
            Text(_post!.description, style: const TextStyle(fontSize: 16)),
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
                        ? DateFormat(
                          'EEE, MMM d, yyyy HH:mm',
                        ).format(_post!.eventDateTime!)
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
                final isInterested = _post!.interestedUsers.contains(
                  currentUserId,
                );
                final isAttended = _post!.attendedUsers.contains(currentUserId);

                final isEvent = _post!.isEvent;
                final eventDateTime = _post!.eventDateTime;
                final isEventExpired =
                    isEvent &&
                    eventDateTime != null &&
                    eventDateTime.isBefore(DateTime.now());

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Show Interest button only if event is NOT expired
                    if (isEvent && !isEventExpired)
                      ElevatedButton.icon(
                        onPressed:
                            currentUserId == null
                                ? null
                                : () async {
                                  await postProvider.togglePostInterest(
                                    _post!.id,
                                    currentUserId,
                                  );
                                  setState(() {
                                    if (isInterested) {
                                      _post!.interestedUsers.remove(
                                        currentUserId,
                                      );
                                    } else {
                                      _post!.interestedUsers.add(
                                        currentUserId!,
                                      );
                                    }
                                  });
                                },
                        icon: Icon(
                          isInterested ? Icons.star : Icons.star_border,
                        ),
                        label: Text(
                          isInterested
                              ? 'Interested (${_post!.interestedUsers.length})'
                              : 'Mark as Interested (${_post!.interestedUsers.length})',
                        ),
                      ),

                    // Show Attend button only if event IS expired
                    if (isEvent && isEventExpired)
                      ElevatedButton.icon(
                        onPressed:
                            currentUserId == null
                                ? null
                                : () async {
                                  await postProvider.togglePostAttendance(
                                    _post!.id,
                                    currentUserId,
                                  );
                                  setState(() {
                                    if (isAttended) {
                                      _post!.attendedUsers.remove(
                                        currentUserId,
                                      );
                                    } else {
                                      _post!.attendedUsers.add(currentUserId!);
                                    }
                                  });
                                },
                        icon: Icon(
                          isAttended
                              ? Icons.check_circle
                              : Icons.check_circle_outline,
                        ),
                        label: Text(
                          isAttended
                              ? 'Attended (${_post!.attendedUsers.length})'
                              : 'Mark as Attended (${_post!.attendedUsers.length})',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isAttended ? Colors.green : null,
                          foregroundColor: isAttended ? Colors.white : null,
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16.0),
            Text(
              'Posted: ${DateFormat('MMM d, yyyy').format(_post!.createdAt)}',
            ),
            Text(
              'Last Updated: ${DateFormat('MMM d, yyyy').format(_post!.updatedAt)}',
            ),
          ],
        ),
      ),
    );
  }
}
