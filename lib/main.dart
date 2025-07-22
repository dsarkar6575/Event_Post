import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/providers/auth_provider.dart';
import 'package:myapp/providers/chat_provider.dart';
import 'package:myapp/providers/notification_provider.dart';
import 'package:myapp/providers/post_provider.dart';
import 'package:myapp/providers/user_provider.dart';
import 'package:myapp/screens/auth/login_screen.dart';
import 'package:myapp/screens/home/home_screen.dart';
import 'package:myapp/utils/app_router.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PostProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        title: 'Event App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        debugShowCheckedModeBanner: false,
        onGenerateRoute: AppRouter.generateRoute,
        home: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            // Check if user is logged in
            // This can be done by checking for a stored token
            // For simplicity, we'll navigate to LoginScreen and let it handle token check
            return authProvider.isAuthenticated ? const HomeScreen() : const LoginScreen();
          },
        ),
      ),
    );
  }
}