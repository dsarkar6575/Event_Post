import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/providers/post_provider.dart';
import 'package:myapp/providers/auth_provider.dart';
import 'package:myapp/widgets/post_card.dart';

class CreatedEventsTab extends StatelessWidget {
  const CreatedEventsTab({super.key});

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

    final createdPosts = postProvider.posts
        .where((post) => post.authorId == currentUserId)
        .toList();

    if (createdPosts.isEmpty) {
      return const Center(child: Text("You haven't created any events yet."));
    }

    return RefreshIndicator(
      onRefresh: () async => await postProvider.fetchAllPosts(),
      child: ListView.builder(
        itemCount: createdPosts.length,
        itemBuilder: (context, index) {
          final post = createdPosts[index];
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
