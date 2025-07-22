import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/models/post_model.dart';
import 'package:myapp/utils/app_router.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostCard extends StatelessWidget {
  final Post post;
  final String? currentUserId;
  final VoidCallback? onToggleInterest;
  final VoidCallback? onDelete;
  final VoidCallback? onComment;
  final VoidCallback? onShare;

  const PostCard({
    super.key,
    required this.post,
    this.currentUserId,
    this.onToggleInterest,
    this.onDelete,
    this.onComment,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final bool isInterested = post.interestedUsers.contains(currentUserId);
    final bool isAuthor = currentUserId == post.authorId;

    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AUTHOR INFO SECTION
            GestureDetector(
              onTap: () {
                if (post.author?.id != null) {
                  Navigator.of(context).pushNamed(
                    AppRouter.profileRoute.replaceFirst(
                      ':userId',
                      post.author!.id,
                    ),
                  );
                }
              },
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage:
                        post.author?.profileImageUrl != null
                            ? NetworkImage(post.author!.profileImageUrl!)
                            : null,
                    child:
                        post.author?.profileImageUrl == null
                            ? Text(post.author?.username[0].toUpperCase() ?? '')
                            : null,
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.author?.username ?? 'Unknown User',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          timeago.format(post.createdAt),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isAuthor)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Edit Post not yet implemented.'),
                            ),
                          );
                        } else if (value == 'delete') {
                          onDelete?.call();
                        }
                      },
                      itemBuilder:
                          (BuildContext context) => <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'edit',
                              child: Text('Edit Post'),
                            ),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Text('Delete Post'),
                            ),
                          ],
                    ),
                ],
              ),
            ),

            const Divider(height: 16.0),

            // POST CONTENT
            GestureDetector(
              onTap: () {
                Navigator.of(context).pushNamed(
                  AppRouter.postDetailRoute.replaceFirst(':id', post.id),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    post.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (post.mediaUrls.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Image.network(
                        post.mediaUrls.first,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) =>
                                const Icon(Icons.image_not_supported),
                      ),
                    ),
                  if (post.isEvent) ...[
                    const SizedBox(height: 8.0),
                    Row(
                      children: [
                        const Icon(Icons.event_note, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          post.eventDateTime != null
                              ? 'Event: ${DateFormat('MMM d, HH:mm').format(post.eventDateTime!)}'
                              : 'Event',
                          style: const TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    if (post.location != null && post.location!.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            post.location!,
                            style: const TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                  ],
                ],
              ),
            ),

            const Divider(height: 16.0),

            // ACTION BUTTONS: INTERESTED, COMMENT, SHARE
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: onToggleInterest,
                  icon: Icon(
                    isInterested ? Icons.star : Icons.star_border,
                    color: isInterested ? Colors.amber : Colors.grey,
                  ),
                  label: Text('${post.interestedCount} Interested'),
                ),
                TextButton.icon(
                  onPressed:
                      onComment ??
                      () {
                        Navigator.of(
                          context,
                        ).pushNamed('/post/${post.id}/comments');
                      },
                  icon: const Icon(Icons.comment, color: Colors.blueGrey),
                  label: const Text('Comment'),
                ),

                TextButton.icon(
                  onPressed:
                      onShare ??
                      () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Post link copied to clipboard!'),
                          ),
                        );
                      },
                  icon: const Icon(Icons.share, color: Colors.blueGrey),
                  label: const Text('Share'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
