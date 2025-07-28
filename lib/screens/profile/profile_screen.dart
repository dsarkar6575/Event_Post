import 'package:flutter/material.dart';
import 'package:myapp/widgets/created_event_tab.dart';
import 'package:myapp/widgets/interested_event_tab.dart';
import 'package:myapp/widgets/post_card.dart';
import 'package:provider/provider.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/providers/auth_provider.dart';
import 'package:myapp/providers/user_provider.dart';
import 'package:myapp/utils/app_router.dart';
import 'package:share_plus/share_plus.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
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
      appBar: isMyProfile ? null : AppBar(title: const Text('Profile')),
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

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildProfileHeader(
                  user,
                  isMyProfile,
                  isFollowing,
                  currentUserId,
                  userProvider,
                ),
                if (isMyProfile)
                  Column(
                    children: [
                      TabBar(
                        controller: _tabController,
                        tabs: const [
                          Tab(text: 'Posts'),
                          Tab(text: 'Interested'),
                        ],
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.7,
                        child: TabBarView(
                          controller: _tabController,
                          children: const [
                            CreatedEventsTab(),
                            InterestedEventsTab(),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  userProvider.userPosts.isEmpty
                      ? const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text("No posts yet."),
                      )
                      : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: userProvider.userPosts.length,
                        itemBuilder: (context, index) {
                          final post = userProvider.userPosts[index];
                          return PostCard(
                            post: post,
                            currentUserId: currentUserId,
                            onComment: () {
                              Navigator.of(context).pushNamed(
                                AppRouter.commentsRoute.replaceFirst(
                                  ':postId',
                                  post.id,
                                ),
                              );
                            },
                            onShare: () {
                              final shareText =
                                  '${post.title}\n\n${post.description}';
                              Share.share(shareText);
                            },
                          );
                        },
                      ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(
    User user,
    bool isMyProfile,
    bool isFollowing,
    String? currentUserId,
    UserProvider userProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 40), // Space for edit button
              CircleAvatar(
                radius: 60,
                backgroundImage:
                    user.profileImageUrl != null
                        ? NetworkImage(user.profileImageUrl!)
                        : null,
                child:
                    user.profileImageUrl == null
                        ? Text(
                          user.username[0].toUpperCase(),
                          style: const TextStyle(fontSize: 40),
                        )
                        : null,
              ),
              const SizedBox(height: 16),
              Text(
                user.username,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                user.bio ?? 'No bio yet.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        '${user.followers.length}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Text('Followers'),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        '${user.following.length}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Text('Following'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (!isMyProfile)
                ElevatedButton(
                  onPressed:
                      currentUserId == null
                          ? null
                          : () async {
                            if (isFollowing) {
                              await userProvider.unfollowUser(
                                user.id,
                                currentUserId,
                              );
                            } else {
                              await userProvider.followUser(
                                user.id,
                                currentUserId,
                              );
                            }
                            await userProvider.fetchUserProfile(user.id);
                          },
                  child: Text(isFollowing ? 'Unfollow' : 'Follow'),
                ),
            ],
          ),
          if (isMyProfile)
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRouter.editProfileRoute);
                },
              ),
            ),
        ],
      ),
    );
  }
}
