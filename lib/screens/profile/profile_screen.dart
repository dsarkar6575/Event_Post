import 'package:flutter/material.dart';
import 'package:myapp/providers/post_provider.dart';
import 'package:provider/provider.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/providers/auth_provider.dart';
import 'package:myapp/providers/user_provider.dart';
import 'package:myapp/utils/app_router.dart';
import 'package:myapp/widgets/post_card.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUserData();
    });
  }

  Future<void> _fetchUserData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.fetchUserProfile(widget.userId);
    await userProvider.fetchUserPosts(widget.userId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.currentUser?.id;
    final isMyProfile = currentUserId == widget.userId;

    return Scaffold(
      appBar: AppBar(
        title: Text(isMyProfile ? 'My Profile' : 'User Profile'),
        actions: [
          if (isMyProfile)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.of(context).pushNamed(AppRouter.editProfileRoute);
              },
            ),
        ],
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.isLoading && userProvider.viewedUser == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (userProvider.error != null) {
            return Center(child: Text('Error: ${userProvider.error}'));
          }
          if (userProvider.viewedUser == null) {
            return const Center(child: Text('User not found.'));
          }

          final User user = userProvider.viewedUser!;
          final bool isFollowing = user.followers.contains(currentUserId);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: user.profileImageUrl != null
                          ? NetworkImage(user.profileImageUrl!)
                          : null,
                      child: user.profileImageUrl == null
                          ? Text(user.username[0].toUpperCase(), style: const TextStyle(fontSize: 40))
                          : null,
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      user.username,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      user.bio ?? 'No bio yet.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text('${user.followers.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const Text('Followers'),
                          ],
                        ),
                        Column(
                          children: [
                            Text('${user.following.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const Text('Following'),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    if (!isMyProfile)
                      ElevatedButton(
                        onPressed: currentUserId == null
                            ? null
                            : () async {
                                if (isFollowing) {
                                  await userProvider.unfollowUser(user.id, currentUserId);
                                } else {
                                  await userProvider.followUser(user.id, currentUserId);
                                }
                                // Re-fetch user profile to update follower count
                                await userProvider.fetchUserProfile(user.id);
                              },
                        child: Text(isFollowing ? 'Unfollow' : 'Follow'),
                      ),
                  ],
                ),
              ),
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Posts'),
                  Tab(text: 'Interested Posts'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // User Posts Tab
                    userProvider.userPosts.isEmpty
                        ? const Center(child: Text('No posts by this user yet.'))
                        : ListView.builder(
                            itemCount: userProvider.userPosts.length,
                            itemBuilder: (context, index) {
                              final post = userProvider.userPosts[index];
                              return PostCard(
                                post: post,
                                currentUserId: currentUserId,
                                onToggleInterest: () async {
                                  if (currentUserId != null) {
                                    await Provider.of<PostProvider>(context, listen: false).togglePostInterest(post.id, currentUserId);
                                    await userProvider.fetchUserPosts(widget.userId); // Refresh user's posts
                                  }
                                },
                                onDelete: () async {
                                  await Provider.of<PostProvider>(context, listen: false).deletePost(post.id);
                                  await userProvider.fetchUserPosts(widget.userId); // Refresh user's posts
                                },
                              );
                            },
                          ),
                    // Interested Posts Tab (Only visible for current user's profile)
                    Consumer<PostProvider>(
                      builder: (context, postProvider, child) {
                        if (isMyProfile) {
                          if (postProvider.isLoading && postProvider.interestedPosts.isEmpty) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (postProvider.error != null) {
                            return Center(child: Text('Error: ${postProvider.error}'));
                          }
                          if (postProvider.interestedPosts.isEmpty) {
                            return const Center(child: Text('You haven\'t marked any posts as interested yet.'));
                          }
                          return ListView.builder(
                            itemCount: postProvider.interestedPosts.length,
                            itemBuilder: (context, index) {
                              final post = postProvider.interestedPosts[index];
                              return PostCard(
                                post: post,
                                currentUserId: currentUserId,
                                onToggleInterest: () async {
                                  if (currentUserId != null) {
                                    await postProvider.togglePostInterest(post.id, currentUserId);
                                    await postProvider.fetchInterestedPosts(); // Refresh interested posts
                                  }
                                },
                                onDelete: () async {
                                  await postProvider.deletePost(post.id);
                                  await postProvider.fetchInterestedPosts();
                                },
                              );
                            },
                          );
                        } else {
                          return const Center(child: Text('Interested posts are only visible on your own profile.'));
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}