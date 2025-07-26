import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/providers/post_provider.dart';
import 'package:myapp/providers/auth_provider.dart';
import 'package:myapp/widgets/post_card.dart';

class InterestedEventsTab extends StatelessWidget {
  const InterestedEventsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final postProvider = Provider.of<PostProvider>(context);
    final currentUserId = Provider.of<AuthProvider>(context).currentUser?.id;

    if (postProvider.isLoading && postProvider.posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (postProvider.error != null) {
      return Center(child: Text('Error: ${postProvider.error}'));
    }

    final interestedPosts = postProvider.posts.where((post) {
      final isInterested = post.interestedUsers.contains(currentUserId);
      return post.isEvent && isInterested;
    }).toList();

    if (interestedPosts.isEmpty) {
      return const Center(child: Text("No events marked as interested."));
    }

    return RefreshIndicator(
      onRefresh: () async => await postProvider.fetchAllPosts(),
      child: ListView.builder(
        itemCount: interestedPosts.length,
        itemBuilder: (context, index) {
          final post = interestedPosts[index];
          return PostCard(
            post: post,
            currentUserId: currentUserId,
            onToggleInterest: () async {
              if (currentUserId != null) {
                await postProvider.togglePostInterest(post.id, currentUserId);
                await postProvider.fetchAllPosts(); // ensure UI reflects update
              }
            },
            onMarkAttended: (postId) async {
              if (currentUserId != null) {
                await postProvider.togglePostAttendance(postId, currentUserId);
                await postProvider.fetchAllPosts(); // refresh UI
              }
            },
            onDelete: () async {
              await postProvider.deletePost(post.id);
              await postProvider.fetchAllPosts(); // update after deletion
            },
          );
        },
      ),
    );
  }
}
