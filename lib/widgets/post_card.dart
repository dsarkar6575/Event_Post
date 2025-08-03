import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/models/post_model.dart';
import 'package:myapp/providers/chat_provider.dart';
import 'package:myapp/providers/post_provider.dart';
import 'package:myapp/utils/app_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostCard extends StatefulWidget {
  final Post post; // Post is now directly used from widget.post
  final String? currentUserId;
  final VoidCallback? onToggleInterest;
  final VoidCallback? onDelete;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final Future<void> Function(String postId)? onMarkAttended;
  final bool isLoading;

  const PostCard({
    super.key,
    required this.post,
    this.currentUserId,
    this.onToggleInterest,
    this.onDelete,
    this.onComment,
    this.onShare,
    this.onMarkAttended,
    this.isLoading = false,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  @override
  Widget build(BuildContext context) {
    final bool isActionLoading = widget.isLoading;
    final Post post = widget.post;

    final bool isInterested = post.interestedUsers.contains(
      widget.currentUserId,
    );
    final bool isAuthor = widget.currentUserId == post.authorId;
    final bool isAttended = post.attendedUsers.contains(widget.currentUserId);
    final bool isExpired =
        post.isEvent &&
        post.eventDateTime != null &&
        post.eventDateTime!.isBefore(DateTime.now());

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
                          Navigator.of(context).pushNamed(
                            AppRouter.editPostRoute.replaceFirst(
                              ':id',
                              post.id,
                            ),
                            arguments: post,
                          );
                        } else if (value == 'delete') {
                          widget.onDelete
                              ?.call(); // Call the onDelete callback from the parent
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
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          post.mediaUrls.first,
                          fit: BoxFit.contain, // Preserve aspect ratio
                          width: double.infinity, // Constrain only width
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

            // ACTION BUTTONS: INTERESTED, COMMENT, SHARE, ATTEND
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Attend/Interested Button Logic
                if (post.isEvent && isExpired)
                  TextButton.icon(
                    onPressed:
                        isActionLoading || widget.onMarkAttended == null
                            ? null
                            : () async {
                              await widget.onMarkAttended!(post.id);
                            },
                    icon:
                        isActionLoading
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : Icon(
                              isAttended
                                  ? Icons.check_circle
                                  : Icons.check_circle_outline,
                              color: isAttended ? Colors.green : Colors.grey,
                            ),
                    label: Text(
                      '${post.attendedUsers.length} Attended',
                      style: TextStyle(
                        color: isAttended ? Colors.green : Colors.grey,
                      ),
                    ),
                  )
                else if (post.isEvent && !isExpired)
                  // "Interest" button for events that are not yet expired
                  TextButton.icon(
                    onPressed:
                        isActionLoading
                            ? null
                            : () async {
                              if (!isInterested) {
                                // User is showing interest — ask if they want to join the chat
                                final shouldJoinChat = await showDialog<bool>(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: const Text("Join Chat Group?"),
                                        content: const Text(
                                          "Do you want to join the chat group for this event?",
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                            child: const Text("No"),
                                          ),
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                            child: const Text("Yes"),
                                          ),
                                        ],
                                      ),
                                );

                                // Always add interest
                                await Provider.of<PostProvider>(
                                  context,
                                  listen: false,
                                ).togglePostInterest(
                                  post.id,
                                  widget.currentUserId!,
                                );

                                // Optionally join chat group
                                if (shouldJoinChat == true && context.mounted) {
                                  // 1. Call the CORRECT provider (ChatProvider) and get the chat object back
                                  final joinedChat =
                                      await Provider.of<ChatProvider>(
                                        context,
                                        listen: false,
                                      ).joinEventGroupChat(post.id);

                                  // 2. Use the returned chat object to NAVIGATE to the chat screen
                                  if (joinedChat != null && context.mounted) {
                                    Navigator.of(context).pushNamed(
                                      AppRouter.chatRoute.replaceFirst(
                                        ':chatId',
                                        joinedChat.id,
                                      ),
                                      arguments: joinedChat,
                                    );
                                  }
                                }
                              } else {
                                // User is removing interest — no popup
                                await Provider.of<PostProvider>(
                                  context,
                                  listen: false,
                                ).togglePostInterest(
                                  post.id,
                                  widget.currentUserId!,
                                );
                              }
                            },
                    icon:
                        isActionLoading
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : Icon(
                              isInterested ? Icons.star : Icons.star_border,
                              color: isInterested ? Colors.blue : Colors.grey,
                            ),
                    label: Text('${post.interestedUsers.length} Interest'),
                  )
                else if (!post.isEvent)
                  // Placeholder for non-event posts
                  const SizedBox.shrink(), // Or a "Likes" button etc.
                // Comment Button
                TextButton.icon(
                  onPressed:
                      widget.onComment ??
                      () {
                        Navigator.of(context).pushNamed(
                          AppRouter.commentsRoute.replaceFirst(
                            ':postId',
                            post.id,
                          ),
                        );
                      },
                  icon: const Icon(Icons.comment, color: Colors.blueGrey),
                  label: Text(
                    ' Comments',
                  ), // Use actual comment count if available
                ),

                // Share Button
                TextButton.icon(
                  onPressed:
                      widget.onShare ??
                      () {
                        final String shareText =
                            '${post.title}\n\n${post.description}';
                        // ignore: deprecated_member_use
                        Share.share(shareText);
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
