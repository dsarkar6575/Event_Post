import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/providers/post_provider.dart';
import 'package:myapp/providers/auth_provider.dart';
import 'package:myapp/widgets/post_card.dart';

class AttendedEventsTab extends StatelessWidget {
  const AttendedEventsTab({super.key});

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

    final now = DateTime.now();

    final attendedPosts = postProvider.posts.where((post) {
  final isInterested = post.interestedUsers.contains(currentUserId);
  final isPastEvent = post.eventDateTime != null && post.eventDateTime!.isBefore(now);
  final isAttended = post.attendedUsers.contains(currentUserId);
  return post.isEvent && isInterested && isPastEvent && isAttended;
}).toList();


    if (attendedPosts.isEmpty) {
      return const Center(child: Text("No attended events yet."));
    }

    return RefreshIndicator(
      onRefresh: () async => await postProvider.fetchAllPosts(),
      child: ListView.builder(
        itemCount: attendedPosts.length,
        itemBuilder: (context, index) {
          final post = attendedPosts[index];
          return PostCard(
            post: post,
            currentUserId: currentUserId,
            onToggleInterest: () async {
              if (currentUserId != null) {
                await postProvider.togglePostInterest(post.id, currentUserId);
              }
            },
            onDelete: () async {
              await postProvider.deletePost(post.id);
            },
          );
        },
      ),
    );
  }
}
