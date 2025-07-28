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

          if (isMyProfile) {
            // My Profile - show tabs
            return DefaultTabController(
              length: 2,
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverAppBar(
                    floating: true,
                    pinned: true,
                    expandedHeight: 370,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          Navigator.of(context).pushNamed(AppRouter.editProfileRoute);
                        },
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: _buildProfileHeader(user, isMyProfile, isFollowing, currentUserId, userProvider),
                    ),
                    bottom: TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(text: 'Posts'),
                        Tab(text: 'Interested Posts'),
                      ],
                    ),
                  ),
                ],
                body: TabBarView(
                  controller: _tabController,
                  children: const [
                    CreatedEventsTab(),
                    InterestedEventsTab(),
                  ],
                ),
              ),
            );
          } else {
            // Other user's profile - no tabs
            return Scaffold(
              body: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverAppBar(
                    floating: true,
                    pinned: true,
                    expandedHeight: 370,
                    flexibleSpace: FlexibleSpaceBar(
                      background: _buildProfileHeader(user, isMyProfile, isFollowing, currentUserId, userProvider),
                    ),
                  ),
                ],
                body: const SizedBox.shrink(), // Empty body
              ),
            );
          }
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
      padding: const EdgeInsets.only(top: kToolbarHeight + 16, left: 16, right: 16, bottom: 16),
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
          const SizedBox(height: 16),
          Text(
            user.username,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
          const SizedBox(height: 16),
          if (!isMyProfile)
            Flexible(
              child: ElevatedButton(
                onPressed: currentUserId == null
                    ? null
                    : () async {
                        if (isFollowing) {
                          await userProvider.unfollowUser(user.id, currentUserId);
                        } else {
                          await userProvider.followUser(user.id, currentUserId);
                        }
                        await userProvider.fetchUserProfile(user.id);
                      },
                child: Text(isFollowing ? 'Unfollow' : 'Follow'),
              ),
            ),
        ],
      ),
    );
  }
}
