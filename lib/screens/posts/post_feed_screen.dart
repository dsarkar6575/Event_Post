import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/providers/auth_provider.dart';
import 'package:myapp/providers/post_provider.dart';
import 'package:myapp/widgets/post_card.dart';

class PostFeedScreen extends StatefulWidget {
  const PostFeedScreen({super.key});

  @override
  State<PostFeedScreen> createState() => _PostFeedScreenState();
}

class _PostFeedScreenState extends State<PostFeedScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch all posts when the screen is initialized.
    // addPostFrameCallback ensures that the context is fully built before accessing it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PostProvider>(context, listen: false).fetchAllPosts();
    });
  }

  // A method to handle manual refreshing of posts, typically triggered by RefreshIndicator.
  Future<void> _refreshPosts() async {
    // Only call fetchAllPosts. The PostProvider's internal logic will update
    // the lists, and the Consumer will rebuild.
    await Provider.of<PostProvider>(context, listen: false).fetchAllPosts();
    // No need to call fetchInterestedPosts or fetchAttendedPosts here
    // unless you have separate tabs/views that rely on those lists
    // and those lists aren't automatically updated by fetchAllPosts if your
    // backend returns the full posts with interest/attended info.
    // If they are on separate tabs, those tabs should call their own fetches.
  }

  @override
  Widget build(BuildContext context) {
    // Get the current user's ID here, as it's unlikely to change frequently
    // and doesn't depend on PostProvider's state.
    final currentUserId = Provider.of<AuthProvider>(context).currentUser?.id;

    return Scaffold(
      body: Consumer<PostProvider>(
        builder: (context, postProvider, child) {
          // Display a loading indicator if posts are being fetched and the list is empty.
          // This covers the initial fetch or a full refresh when no data is present yet.
          if (postProvider.isLoading && postProvider.posts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          // Display an error message if there was an issue fetching posts.
          if (postProvider.error != null && postProvider.posts.isEmpty) {
            // Only show full error if there are no posts to display at all
            return Center(child: Text('Error: ${postProvider.error}'));
          }
          // Display a message if no posts are available after loading.
          if (postProvider.posts.isEmpty && !postProvider.isLoading) {
            return const Center(
              child: Text('No posts yet. Be the first to create one!'),
            );
          }

          // Use RefreshIndicator to allow users to manually refresh the list.
          return RefreshIndicator(
            onRefresh: _refreshPosts,
            child: ListView.builder(
              itemCount: postProvider.posts.length,
              itemBuilder: (context, index) {
                final post = postProvider.posts[index];
                return PostCard(
                  key: ValueKey(
                    post.id,
                  ), // IMPORTANT: Add ValueKey for efficient list updates
                  post: post,
                  currentUserId: currentUserId,
                  // Pass the specific loading status for THIS post
                  isLoading:
                      currentUserId != null &&
                      postProvider.isPostLoading(post.id),

                  // Callback for when the user toggles interest on a post.
                  onToggleInterest: () async {
                    final postProvider = Provider.of<PostProvider>(
                      context,
                      listen: false,
                    );

                    if (currentUserId != null) {
                      final alreadyInterested = post.interestedUsers.contains(
                        currentUserId,
                      );

                      if (alreadyInterested) {
                        // User is un-interested: just remove interest (no popup)
                        try {
                          await postProvider.togglePostInterest(
                            post.id,
                            currentUserId,
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to remove interest: $e'),
                            ),
                          );
                        }
                      } else {
                        // Show join chat group popup
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
                                        () => Navigator.pop(context, false),
                                    child: const Text("No"),
                                  ),
                                  TextButton(
                                    onPressed:
                                        () => Navigator.pop(context, true),
                                    child: const Text("Yes"),
                                  ),
                                ],
                              ),
                        );

                        try {
                          // Always mark as interested first
                          await postProvider.togglePostInterest(
                            post.id,
                            currentUserId,
                          );

                          // Then join chat group if user agreed
                          if (shouldJoinChat == true) {
                            await postProvider.joinChatGroup(post.id);
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please log in to express interest.'),
                        ),
                      );
                    }
                  },

                  // Callback for when the user marks an event as attended.
                  onMarkAttended: (postId) async {
                    if (currentUserId != null) {
                      try {
                        await postProvider.togglePostAttendance(
                          postId,
                          currentUserId,
                        );
                        // No need to call fetchAllPosts() here.
                        // PostProvider's internal logic updates _posts, and this Consumer rebuilds.
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Marked as attended!")),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Failed to mark attended: ${e.toString()}',
                            ),
                          ),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please log in to mark attendance.'),
                        ),
                      );
                    }
                    return; // Added return type as Future<void> Function(String postId)
                  },

                  // Callback for when the user deletes a post.
                  onDelete: () async {
                    if (currentUserId != null &&
                        currentUserId == post.authorId) {
                      // Ensure only author can delete
                      // Show a confirmation dialog before deleting
                      bool confirmDelete =
                          await showDialog(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: const Text('Delete Post'),
                                  content: const Text(
                                    'Are you sure you want to delete this post?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () =>
                                              Navigator.of(context).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    FilledButton(
                                      onPressed:
                                          () => Navigator.of(context).pop(true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                          ) ??
                          false; // Default to false if dialog is dismissed

                      if (confirmDelete) {
                        try {
                          await postProvider.deletePost(post.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Post deleted successfully!'),
                            ),
                          );
                          // No need to call fetchAllPosts() here.
                          // PostProvider's internal logic updates _posts, and this Consumer rebuilds.
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Failed to delete post: ${e.toString()}',
                              ),
                            ),
                          );
                        }
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'You are not authorized to delete this post.',
                          ),
                        ),
                      );
                    }
                  },
                  // You might also want to add onComment and onShare here if they involve provider actions
                );
              },
            ),
          );
        },
      ),
    );
  }
}
