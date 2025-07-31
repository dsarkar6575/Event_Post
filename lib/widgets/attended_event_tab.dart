// AttendedEventsTab.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Import for kDebugMode
import 'package:provider/provider.dart';
import 'package:myapp/providers/post_provider.dart';
import 'package:myapp/providers/auth_provider.dart';
import 'package:myapp/widgets/post_card.dart';

class AttendedEventsTab extends StatefulWidget {
  const AttendedEventsTab({super.key});

  @override
  State<AttendedEventsTab> createState() => _AttendedEventsTabState();
}

class _AttendedEventsTabState extends State<AttendedEventsTab> {
  @override
  void initState() {
    super.initState();
    // Fetch attended posts when the widget is initialized
    // Use listen: false because we only need to trigger the fetch, not listen for changes here
    Provider.of<PostProvider>(context, listen: false).fetchAttendedPosts();
  }

  @override
  Widget build(BuildContext context) {
    // Access AuthProvider once outside the Consumer for the currentUserId.
    final currentUserId = Provider.of<AuthProvider>(context, listen: false).currentUser?.id;

    // Use Consumer<PostProvider> to rebuild only this part of the widget tree
    // when PostProvider notifies listeners.
    return Consumer<PostProvider>(
      builder: (context, postProvider, _) {

        // Use the directly fetched attendedPosts list from the provider.
        // The provider already ensures this list is up-to-date.
        final attendedPosts = postProvider.attendedPosts;

        // Show a loading indicator if posts are being fetched and the attendedPosts list is empty.
        if (postProvider.isLoading && attendedPosts.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        // Display an error message if there was an issue fetching posts.
        if (postProvider.error != null) {
          return Center(child: Text('Error: ${postProvider.error}'));
        }

        if (kDebugMode) {
          print('Final count of attendedPosts from state: ${attendedPosts.length}');
        }

        // Display a message if no attended events are found.
        if (attendedPosts.isEmpty) {
          return const Center(child: Text("No attended events yet."));
        }

        // Use RefreshIndicator to allow users to manually refresh the list.
        return RefreshIndicator(
          onRefresh: () async {
            // When refreshing, fetch attended posts specifically
            if (kDebugMode) {
              print('AttendedEventsTab: Refreshing attended posts...');
            }
            await postProvider.fetchAttendedPosts();
          },
          child: ListView.builder(
            itemCount: attendedPosts.length,
            itemBuilder: (context, index) {
              final post = attendedPosts[index];
              return PostCard(
                post: post,
                currentUserId: currentUserId,
                // Pass the per-post loading state to PostCard
                isLoading: postProvider.isPostLoading(post.id),
                // Callback for when the user toggles interest on a post.
                onToggleInterest: () async {
                  if (currentUserId != null) {
                    await postProvider.togglePostInterest(post.id, currentUserId);
                    // Removed: await Provider.of<PostProvider>(context, listen: false).fetchAttendedPosts();
                    // The provider handles internal list updates and notifications.
                  }
                },
                // Enable onMarkAttended if you want to allow un-marking attendance
                onMarkAttended: (postId) async {
                  if (currentUserId != null) {
                    await postProvider.togglePostAttendance(postId, currentUserId);
                    // Removed: await Provider.of<PostProvider>(context, listen: false).fetchAttendedPosts();
                    // The provider handles internal list updates and notifications.
                  }
                },
                // Callback for when the user deletes a post.
                onDelete: () async {
                  await postProvider.deletePost(post.id);
                  // A full refresh might still be desired here to ensure consistency
                  // across all tabs after a deletion.
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