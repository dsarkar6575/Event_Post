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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PostProvider>(context, listen: false).fetchAllPosts();
    });
  }

  Future<void> _refreshPosts() async {
    await Provider.of<PostProvider>(context, listen: false).fetchAllPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<PostProvider>(
        builder: (context, postProvider, child) {
          if (postProvider.isLoading && postProvider.posts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (postProvider.error != null) {
            return Center(child: Text('Error: ${postProvider.error}'));
          }
          if (postProvider.posts.isEmpty) {
            return const Center(child: Text('No posts yet. Be the first to create one!'));
          }

          final currentUserId = Provider.of<AuthProvider>(context).currentUser?.id;

          return RefreshIndicator(
            onRefresh: _refreshPosts,
            child: ListView.builder(
              itemCount: postProvider.posts.length,
              itemBuilder: (context, index) {
                final post = postProvider.posts[index];
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
        },
      ),
    );
  }
}