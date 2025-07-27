// InterestedEventsTab.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Import for kDebugMode
import 'package:provider/provider.dart';
import 'package:myapp/providers/post_provider.dart';
import 'package:myapp/providers/auth_provider.dart';
import 'package:myapp/widgets/post_card.dart';

// This tab displays events that the current user has marked as 'interested'.
class InterestedEventsTab extends StatelessWidget {
  const InterestedEventsTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Access AuthProvider once outside the Consumer for the currentUserId.
    // We use listen: false because AuthProvider changes don't directly
    // affect how we filter or display posts in this tab based on the user ID,
    // only which user ID we're checking against.
    final currentUserId = Provider.of<AuthProvider>(context, listen: false).currentUser?.id;

    // Use Consumer<PostProvider> to rebuild only this part of the widget tree
    // when PostProvider notifies listeners.
    return Consumer<PostProvider>(
      builder: (context, postProvider, _) {
        // Now, interestedPosts can directly come from the provider's dedicated list.
        // This list is already kept in sync by the provider's toggle methods.
        final interestedPosts = postProvider.interestedPosts.where((post) => post.isEvent).toList();

        // Show a loading indicator if posts are being fetched and the list is empty.
        if (postProvider.isLoading && interestedPosts.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        // Display an error message if there was an issue fetching posts.
        if (postProvider.error != null) {
          return Center(child: Text('Error: ${postProvider.error}'));
        }

        // Display a message if no interested events are found.
        if (interestedPosts.isEmpty) {
          return const Center(child: Text("No events marked as interested."));
        }

        // Use RefreshIndicator to allow users to manually refresh the list.
        return RefreshIndicator(
          onRefresh: () async {
            // When refreshing, fetch all posts to ensure the latest data is displayed.
            // This is the appropriate place for a full data refresh.
            await postProvider.fetchAllPosts();
          },
          child: ListView.builder(
            itemCount: interestedPosts.length,
            itemBuilder: (context, index) {
              final post = interestedPosts[index];
              return PostCard(
                post: post,
                currentUserId: currentUserId,
                // Pass the per-post loading state to PostCard
                isLoading: postProvider.isPostLoading(post.id),
                // Callback for when the user toggles interest on a post.
                onToggleInterest: () async {
                  if (currentUserId != null) {
                    await postProvider.togglePostInterest(post.id, currentUserId);
                    // Removed: await postProvider.fetchAllPosts();
                    // The provider itself now handles updating its internal lists
                    // and notifying listeners, so the UI will update automatically.
                  }
                },
                // Callback for when the user marks an event as attended.
                onMarkAttended: (postId) async {
                  if (currentUserId != null) {
                    await postProvider.togglePostAttendance(postId, currentUserId);
                    // Removed: await postProvider.fetchAllPosts();
                    // The provider itself handles updating its internal lists.
                  }
                },
                // Callback for when the user deletes a post.
                onDelete: () async {
                  await postProvider.deletePost(post.id);
                  // A full refresh might still be desired here to ensure consistency
                  // across all tabs after a deletion, as deletion affects the primary
                  // _posts list directly, which might influence other filters.
                  await postProvider.fetchAllPosts();
                },
              );
            },
          ),
        );
      },
    );
  }
}