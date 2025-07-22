import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/providers/auth_provider.dart';
import 'package:myapp/providers/notification_provider.dart';
import 'package:myapp/screens/chat/chat_list_screen.dart';
import 'package:myapp/screens/notifications/notification_screen.dart';
import 'package:myapp/screens/posts/create_post_screen.dart';
import 'package:myapp/screens/posts/post_feed_screen.dart';
import 'package:myapp/screens/profile/profile_screen.dart';
import 'package:myapp/utils/app_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const PostFeedScreen(),
    const ChatListScreen(),
    const CreatePostScreen(),
    const NotificationScreen(),
    // Placeholder for own profile, will navigate
    Builder(
      builder: (context) {
        final authProvider = Provider.of<AuthProvider>(context);
        return ProfileScreen(userId: authProvider.currentUser!.id);
      },
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);

    // If for some reason user is null, navigate back to login
    if (!authProvider.isAuthenticated) {
      // Use WidgetsBinding.instance.addPostFrameCallback to ensure context is valid
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed(AppRouter.loginRoute);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
              Navigator.of(context).pushReplacementNamed(AppRouter.loginRoute);
            },
          ),
        ],
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chats',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.add_box),
            label: 'Post',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.notifications),
                if (notificationProvider.unreadCount > 0)
                  Positioned(
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        '${notificationProvider.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
              ],
            ),
            label: 'Notifications',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // To show all labels
      ),
    );
  }
}