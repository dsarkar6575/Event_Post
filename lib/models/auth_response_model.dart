// myapp/models/auth_response.dart
import 'package:myapp/models/user_model.dart';

class AuthResponse {
  final String token;
  final User user;
  final String? refreshToken; // Added for refresh token

  AuthResponse({required this.token, required this.user, this.refreshToken});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'],
      user: User.fromJson(json['user']),
      refreshToken: json['refreshToken'], // Parse the refresh token
    );
  }
}
