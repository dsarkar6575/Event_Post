import 'package:flutter/material.dart';
import 'package:myapp/models/post_model.dart';
import 'package:myapp/screens/auth/login_screen.dart';
import 'package:myapp/screens/auth/register_screen.dart';
import 'package:myapp/screens/home/home_screen.dart';
import 'package:myapp/screens/event/event_screen.dart'; // Assuming EventFeedScreen is in this file
import 'package:myapp/screens/posts/create_post_screen.dart';
import 'package:myapp/screens/posts/post_detail_screen.dart';
import 'package:myapp/screens/posts/post_feed_screen.dart';
import 'package:myapp/screens/posts/comments_screen.dart';
import 'package:myapp/screens/profile/edit_profile_screen.dart';
import 'package:myapp/screens/profile/profile_screen.dart';
import 'package:myapp/screens/posts/edit_post_screen.dart'; // Import the new screen

class AppRouter {
  static const String loginRoute = '/';
  static const String registerRoute = '/register';
  static const String homeRoute = '/home';
  static const String postFeedRoute = '/posts';
  static const String createPostRoute = '/create_post';
  static const String postDetailRoute = '/posts/:id';
  static const String editPostRoute = '/posts/:id/edit'; // New route for editing
  static const String chatListRoute = '/chats';
  static const String chatRoute = '/chat/:chatId';
  static const String profileRoute = '/profile/:userId';
  static const String editProfileRoute = '/edit_profile';
  static const String eventRoute = '/event';
  static const String commentsRoute = '/post/:postId/comments';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final Uri uri = Uri.parse(settings.name!);
    final String path = uri.path;

    // Handle static routes first
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
      case editProfileRoute:
        return MaterialPageRoute(builder: (_) => const EditProfileScreen());
    }

    // Handle dynamic routes
    if (path.startsWith('/posts/') && path.endsWith('/edit') && path.split('/').length == 4) {
      final postId = path.split('/')[2];
      // You need to pass the actual Post object here,
      // which means the navigation will likely happen from a PostCard
      // or PostDetailScreen where the Post object is available.
      // For now, we'll assume settings.arguments will provide the Post object.
      // Alternatively, you would fetch the post here.
      final Post? post = settings.arguments as Post?;
      if (post != null) {
        return MaterialPageRoute(builder: (_) => EditPostScreen(post: post));
      }
      return MaterialPageRoute(
        builder: (_) => const Scaffold(
          body: Center(child: Text('Error: Post data not provided for editing.')),
        ),
      );
    } else if (path.startsWith('/posts/') && path.split('/').length == 3) {
      final postId = path.split('/')[2];
      return MaterialPageRoute(builder: (_) => PostDetailScreen(postId: postId));
    } else if (path.startsWith('/post/') && path.endsWith('/comments')) {
      final postId = path.split('/')[2];
      return MaterialPageRoute(builder: (_) => CommentsScreen(postId: postId));
    } else if (path.startsWith('/profile/')) {
      final userId = path.split('/')[2];
      return MaterialPageRoute(builder: (_) => ProfileScreen(userId: userId));
    }

    // Fallback for unknown routes
    return MaterialPageRoute(
      builder: (_) => const Scaffold(
        body: Center(child: Text('Error: Unknown route')),
      ),
    );
  }
}