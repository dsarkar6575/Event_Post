import 'package:flutter/material.dart';
import 'package:myapp/models/post_model.dart';
import 'package:myapp/screens/auth/login_screen.dart';
import 'package:myapp/screens/auth/register_screen.dart';
import 'package:myapp/screens/home/home_screen.dart';
import 'package:myapp/screens/event/event_screen.dart';
import 'package:myapp/screens/posts/create_post_screen.dart';
import 'package:myapp/screens/posts/post_detail_screen.dart';
import 'package:myapp/screens/posts/post_feed_screen.dart';
import 'package:myapp/screens/posts/comments_screen.dart';
import 'package:myapp/screens/profile/edit_profile_screen.dart';
import 'package:myapp/screens/profile/profile_screen.dart';
import 'package:myapp/screens/posts/edit_post_screen.dart';
import 'package:myapp/screens/chat/chat_list_screen.dart'; // Import chat screens
import 'package:myapp/screens/chat/chat_screen.dart';
import 'package:myapp/models/chat_model.dart';


class AppRouter {
  // --- Route Constants ---
  static const String loginRoute = '/';
  static const String registerRoute = '/register';
  static const String homeRoute = '/home';
  static const String postFeedRoute = '/posts';
  static const String createPostRoute = '/create-post';
  static const String postDetailRoute = '/posts/:id';
  static const String editPostRoute = '/posts/:id/edit';
  static const String commentsRoute = '/posts/:postId/comments';
  static const String profileRoute = '/profile/:userId';
  static const String editProfileRoute = '/profile/edit';
  static const String eventRoute = '/events';

  static const String chatListRoute = '/chats';
  static const String chatRoute = '/chats/:chatId';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name!);
    final pathSegments = uri.pathSegments;

    // Handle root route '/'
    if (pathSegments.isEmpty) {
      return MaterialPageRoute(builder: (_) => const LoginScreen());
    }

    // Handle routes based on the first segment for better organization
    final head = pathSegments[0];

    switch (head) {
      case 'register':
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case 'home':
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case 'posts':
        if (pathSegments.length == 1) { // '/posts'
          return MaterialPageRoute(builder: (_) => const PostFeedScreen());
        }
        if (pathSegments.length == 2) { // '/posts/:id'
          final postId = pathSegments[1];
          return MaterialPageRoute(builder: (_) => PostDetailScreen(postId: postId));
        }
        if (pathSegments.length == 3) { // '/posts/:id/edit' or '/posts/:id/comments'
          final postId = pathSegments[1];
          if (pathSegments[2] == 'edit') {
            final post = settings.arguments as Post?;
            if (post != null) {
              return MaterialPageRoute(builder: (_) => EditPostScreen(post: post));
            }
          }
          if (pathSegments[2] == 'comments') {
            return MaterialPageRoute(builder: (_) => CommentsScreen(postId: postId));
          }
        }
        break;
      case 'create-post':
        return MaterialPageRoute(builder: (_) => const CreatePostScreen());
      case 'events':
        return MaterialPageRoute(builder: (_) => const EventFeedScreen());
      case 'profile':
        if (pathSegments.length == 2) { // '/profile/:userId'
          final userId = pathSegments[1];
          return MaterialPageRoute(builder: (_) => ProfileScreen(userId: userId));
        }
        if (pathSegments.length == 2 && pathSegments[1] == 'edit') { // '/profile/edit'
          return MaterialPageRoute(builder: (_) => const EditProfileScreen());
        }
        break;

      // ✅ ADDED: Handler for both static and dynamic chat routes
      case 'chats':
        if (pathSegments.length == 1) { // '/chats'
          return MaterialPageRoute(builder: (_) => const ChatListScreen());
        }
        if (pathSegments.length == 2) { // '/chats/:chatId'
          final chatId = pathSegments[1];
          final chat = settings.arguments as Chat?; // Pass the chat object if available
          return MaterialPageRoute(builder: (_) => ChatScreen(chatId: chatId, chat: chat));
        }
        break;
    }

    // Fallback for any unknown routes
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        body: Center(child: Text('Error: No route defined for ${settings.name}')),
      ),
    );
  }
}