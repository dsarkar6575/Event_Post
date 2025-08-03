import 'package:flutter/material.dart';
import 'package:myapp/providers/chat_provider.dart';
import 'package:myapp/providers/theme_provider.dart';
import 'package:myapp/screens/chat/chat_list_screen.dart';
import 'package:provider/provider.dart';
import 'package:myapp/providers/auth_provider.dart';
import 'package:myapp/providers/event_provider.dart';
import 'package:myapp/screens/event/event_screen.dart';
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
     ChatListScreen(),
    const CreatePostScreen(),
    const EventFeedScreen(),
    // Placeholder for own profile, will navigate
    Builder(
      builder: (context) {
        final authProvider = Provider.of<AuthProvider>(context);
        return ProfileScreen(userId: authProvider.currentUser!.id);
      },
    ),
  ];

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Home';
      case 1:
        return 'Chats';
      case 2:
        return 'Create Post';
      case 3:
        return 'My Events';
      case 4:
        return 'My Profile';
      default:
        return 'Event App';
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final eventProvider = Provider.of<EventProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context); 

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
        title: Text(_getAppBarTitle()),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            onSelected: (value) async {
              if (value == 'logout') {
                await Provider.of<AuthProvider>(
                  context,
                  listen: false,
                ).logout();
                Navigator.of(
                  context,
                ).pushReplacementNamed(AppRouter.loginRoute);
              } else if (value == 'toggle_theme') {
                final themeProvider = Provider.of<ThemeProvider>(
                  context,
                  listen: false,
                );

                // Get current effective brightness
                final currentBrightness = Theme.of(context).brightness;
                final isDark = currentBrightness == Brightness.dark;

                // Toggle to opposite of current brightness
                themeProvider.toggleTheme(!isDark);
              }
            },
            itemBuilder: (context) {
              final currentBrightness = Theme.of(context).brightness;
              final isDark = currentBrightness == Brightness.dark;

              return [
                const PopupMenuItem(value: 'logout', child: Text('Logout')),
                PopupMenuItem(
                  value: 'toggle_theme',
                  child: Text(isDark ? '🌞 Light Mode' : '🌙 Dark Mode'),
                ),
              ];
            },
          ),
        ],
      ),

      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
          const BottomNavigationBarItem(
            icon: Icon(Icons.add_box),
            label: 'Post',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.event),
                if (eventProvider.unreadCount > 0)
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
                        '${eventProvider.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Events',
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
