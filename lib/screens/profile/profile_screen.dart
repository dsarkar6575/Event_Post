import 'package:flutter/material.dart';
import 'package:myapp/widgets/created_event_tab.dart';
import 'package:myapp/widgets/interested_event_tab.dart';
import 'package:provider/provider.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/providers/auth_provider.dart';
import 'package:myapp/providers/user_provider.dart';
import 'package:myapp/utils/app_router.dart';

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
                    CreatedEventsTab(),
                    InterestedEventsTab()
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