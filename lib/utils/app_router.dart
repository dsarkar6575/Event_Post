import 'package:flutter/material.dart';
import 'package:myapp/screens/auth/login_screen.dart';
import 'package:myapp/screens/auth/register_screen.dart';
import 'package:myapp/screens/chat/chat_list_screen.dart';
import 'package:myapp/screens/chat/chat_screen.dart';
import 'package:myapp/screens/home/home_screen.dart';
import 'package:myapp/screens/event/event_screen.dart';
import 'package:myapp/screens/posts/create_post_screen.dart';
import 'package:myapp/screens/posts/post_detail_screen.dart';
import 'package:myapp/screens/posts/post_feed_screen.dart';
import 'package:myapp/screens/posts/comments_screen.dart'; // Make sure you import this
import 'package:myapp/screens/profile/edit_profile_screen.dart';
import 'package:myapp/screens/profile/profile_screen.dart';

class AppRouter {
  static const String loginRoute = '/';
  static const String registerRoute = '/register';
  static const String homeRoute = '/home';
  static const String postFeedRoute = '/posts';
  static const String createPostRoute = '/create_post';
  static const String postDetailRoute = '/posts/:id';
  static const String chatListRoute = '/chats';
  static const String chatRoute = '/chat/:chatId';
  static const String profileRoute = '/profile/:userId';
  static const String editProfileRoute = '/edit_profile';
  static const String eventRoute = '/event';
  static const String commentsRoute = '/post/:postId/comments';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final Uri uri = Uri.parse(settings.name!);
    final String path = uri.path;

    switch (path) {
      case loginRoute:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case registerRoute:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case homeRoute:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case postFeedRoute:
        return MaterialPageRoute(builder: (_) => const PostFeedScreen());
      case createPostRoute:
        return MaterialPageRoute(builder: (_) => const CreatePostScreen());
      case eventRoute:
        return MaterialPageRoute(builder: (_) => const EventFeedScreen());
      case chatListRoute:
        return MaterialPageRoute(builder: (_) => const ChatListScreen());
      case editProfileRoute:
        return MaterialPageRoute(builder: (_) => const EditProfileScreen());

      // Dynamic Routes
      default:
        if (path.startsWith('/posts/') && path.split('/').length == 3) {
          final postId = path.split('/')[2];
          return MaterialPageRoute(builder: (_) => PostDetailScreen(postId: postId));
        } else if (path.startsWith('/post/') && path.endsWith('/comments')) {
          final postId = path.split('/')[2];
          return MaterialPageRoute(builder: (_) => CommentsScreen(postId: postId));
        } else if (path.startsWith('/chat/')) {
          final chatId = path.split('/')[2];
          return MaterialPageRoute(builder: (_) => ChatScreen(chatId: chatId));
        } else if (path.startsWith('/profile/')) {
          final userId = path.split('/')[2];
          return MaterialPageRoute(builder: (_) => ProfileScreen(userId: userId));
        }

        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Error: Unknown route')),
          ),
        );
    }
  }
}
