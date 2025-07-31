import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/providers/post_provider.dart';
import 'package:myapp/providers/auth_provider.dart';
import 'package:myapp/widgets/post_card.dart';

class InterestedEventsTab extends StatefulWidget {
  const InterestedEventsTab({super.key});

  @override
  State<InterestedEventsTab> createState() => _InterestedEventsTabState();
}

class _InterestedEventsTabState extends State<InterestedEventsTab> {
  @override
  void initState() {
    super.initState();
    Provider.of<PostProvider>(context, listen: false).fetchInterestedPosts();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Provider.of<AuthProvider>(context, listen: false).currentUser?.id;

    return Consumer<PostProvider>(
      builder: (context, postProvider, _) {
        final interestedPosts = postProvider.interestedPosts;

        if (postProvider.isLoading && interestedPosts.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (postProvider.error != null) {
          return Center(child: Text('Error: ${postProvider.error}'));
        }

        if (interestedPosts.isEmpty) {
          return const Center(child: Text("No events marked as interested."));
        }

        return RefreshIndicator(
          onRefresh: () async {
            await postProvider.fetchInterestedPosts();
          },
          child: ListView.builder(
            itemCount: interestedPosts.length,
            itemBuilder: (context, index) {
              final post = interestedPosts[index];
              return PostCard(
                post: post,
                currentUserId: currentUserId,
                isLoading: postProvider.isPostLoading(post.id),
                onToggleInterest: () async {
                  if (currentUserId != null) {
                    await postProvider.togglePostInterest(post.id, currentUserId);
                  }
                },
                onMarkAttended: (postId) async {
                  if (currentUserId != null) {
                    await postProvider.togglePostAttendance(postId, currentUserId);
                  }
                },
                onDelete: () async {
                  await postProvider.deletePost(post.id);
                },
              );
            },
          ),
        );
      },
    );
  }
}
