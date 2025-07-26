import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/models/post_model.dart';
import 'package:myapp/utils/app_router.dart';
import 'package:timeago/timeago.dart' as timeago;


class PostCard extends StatefulWidget { // Changed to StatefulWidget
  final Post post;
  final String? currentUserId;
  final VoidCallback? onToggleInterest;
  final VoidCallback? onDelete;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final Future<void> Function(String postId)? onMarkAttended;

  const PostCard({
    super.key,
    required this.post,
    this.currentUserId,
    this.onToggleInterest,
    this.onDelete,
    this.onComment,
    this.onShare,
    this.onMarkAttended,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  // We'll manage a local copy of the post to update its attendance status
  late Post _post;

  @override
  void initState() {
    super.initState();
    _post = widget.post; // Initialize with the post from the widget
  }

  // If the parent widget provides a new post, update our local copy
  @override
  void didUpdateWidget(covariant PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.post.id != oldWidget.post.id ||
        widget.post.interestedUsers.length != oldWidget.post.interestedUsers.length ||
        widget.post.attendedUsers.length != oldWidget.post.attendedUsers.length) {
      _post = widget.post;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use _post instead of widget.post for state-dependent properties
    final bool isInterested = _post.interestedUsers.contains(widget.currentUserId);
    final bool isAuthor = widget.currentUserId == _post.authorId;

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
                if (_post.author?.id != null) {
                  Navigator.of(context).pushNamed(
                    AppRouter.profileRoute.replaceFirst(
                      ':userId',
                      _post.author!.id,
                    ),
                  );
                }
              },
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: _post.author?.profileImageUrl != null
                        ? NetworkImage(_post.author!.profileImageUrl!)
                        : null,
                    child: _post.author?.profileImageUrl == null
                        ? Text(_post.author?.username[0].toUpperCase() ?? '')
                        : null,
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _post.author?.username ?? 'Unknown User',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          timeago.format(_post.createdAt),
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
                            AppRouter.editPostRoute.replaceFirst(':id', _post.id),
                            arguments: _post,
                          );
                        } else if (value == 'delete') {
                          widget.onDelete?.call();
                        }
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
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
                  AppRouter.postDetailRoute.replaceFirst(':id', _post.id),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _post.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    _post.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (_post.mediaUrls.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Image.network(
                        _post.mediaUrls.first,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.image_not_supported),
                      ),
                    ),
                  if (_post.isEvent) ...[
                    const SizedBox(height: 8.0),
                    Row(
                      children: [
                        const Icon(Icons.event_note, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          _post.eventDateTime != null
                              ? 'Event: ${DateFormat('MMM d, HH:mm').format(_post.eventDateTime!)}'
                              : 'Event',
                          style: const TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    if (_post.location != null && _post.location!.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            _post.location!,
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
                Builder(
                  builder: (context) {
                    final bool isExpired = _post.eventDateTime != null &&
                        _post.eventDateTime!.isBefore(DateTime.now());
                    // Use _post for these checks as well
                    final bool isInterested =
                        _post.interestedUsers.contains(widget.currentUserId);
                    final bool isAttended =
                        _post.attendedUsers.contains(widget.currentUserId);

                    if (isExpired && isInterested && !isAttended) {
                      return ElevatedButton(
                        onPressed: () async {
                          if (widget.onMarkAttended != null) {
                            await widget.onMarkAttended!(_post.id);
                            // Update the local state to reflect the change
                            setState(() {
                              if (widget.currentUserId != null && !_post.attendedUsers.contains(widget.currentUserId)) {
                                _post.attendedUsers.add(widget.currentUserId!);
                              }
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Marked as attended!")),
                            );
                          }
                        },
                        child: const Text("Attended"),
                      );
                    } else if (isExpired && isAttended) {
                      return const Text("You attended",
                          style: TextStyle(color: Colors.green));
                    } else if (!isExpired) {
                      return IconButton(
                        icon: Icon(Icons.star,
                            color: isInterested ? Colors.blue : Colors.grey),
                        onPressed: widget.onToggleInterest,
                      );
                    } else {
                      return const Icon(Icons.block,
                          color: Colors.grey); // expired & not attended
                    }
                  },
                ),

                TextButton.icon(
                  onPressed: widget.onComment ??
                      () {
                        Navigator.of(
                          context,
                        ).pushNamed(
                            AppRouter.commentsRoute.replaceFirst(':postId', _post.id));
                      },
                  icon: const Icon(Icons.comment, color: Colors.blueGrey),
                  label: const Text('Comment'),
                ),

                TextButton.icon(
                  onPressed: widget.onShare ??
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