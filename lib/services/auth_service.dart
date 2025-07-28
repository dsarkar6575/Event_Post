// myapp/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myapp/core/api_constants.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/utils/secure_storage.dart';

// Define an AuthResponse class to handle login/register responses
class AuthResponse {
  final String token;
  final User user;
  final String? refreshToken; // Added for refresh token

  AuthResponse({required this.token, required this.user, this.refreshToken});
}

class AuthService {
  // Use a common HTTP client instance, or use direct http calls
  // For production apps, consider 'dio' for interceptors
  final http.Client _httpClient = http.Client();

  // Helper method for authenticated requests
  // This is where you centralize token handling
  Future<http.Response> _authenticatedRequest(
      Future<http.Response> Function(String token) requestBuilder) async {
    String? accessToken = await SecureStorage.getToken();
    String? refreshToken = await SecureStorage.getRefreshToken();

    if (accessToken == null) {
      throw Exception('No access token available. User not logged in.');
    }

    http.Response response = await requestBuilder(accessToken);

    if (response.statusCode == 401 && refreshToken != null) {
      // Access token might be expired, try refreshing
      print('Access token expired or invalid, attempting to refresh...');
      try {
        final newTokens = await _refreshAccessToken(refreshToken);
        final newAccessToken = newTokens['accessToken'];
        final newRefreshToken = newTokens['refreshToken'];

        // Save new tokens
        await SecureStorage.saveToken(newAccessToken);
        if (newRefreshToken != null) {
          await SecureStorage.saveRefreshToken(newRefreshToken);
        }

        // Retry the original request with the new access token
        response = await requestBuilder(newAccessToken);
      } catch (e) {
        print('Failed to refresh token: $e');
        // If refresh fails, re-throw to trigger logout in AuthProvider
        rethrow;
      }
    }

    return response;
  }

  // Method to get a new access token using a refresh token
  Future<Map<String, dynamic>> _refreshAccessToken(String refreshToken) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/auth/refresh-token'); // Adjust this endpoint
    final response = await _httpClient.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'refreshToken': refreshToken}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Assuming your refresh endpoint returns 'accessToken' and possibly a new 'refreshToken'
      return {
        'accessToken': data['accessToken'],
        'refreshToken': data['refreshToken'], // May be null if backend doesn't re-issue refresh token
      };
    } else {
      throw Exception('Failed to refresh token: ${response.statusCode} - ${response.body}');
    }
  }

  Future<AuthResponse> registerUser(String email, String username, String password) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.registerEndpoint}');
    final response = await _httpClient.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 201) { // Assuming 201 for successful creation
      final data = json.decode(response.body);
      final token = data['token']; // Access token
      final user = User.fromJson(data['user']);
      final refreshToken = data['refreshToken']; // If your backend provides it

      return AuthResponse(token: token, user: user, refreshToken: refreshToken);
    } else {
      final errorData = json.decode(response.body);
      throw Exception('Registration failed: ${errorData['message'] ?? response.statusCode}');
    }
  }

  Future<AuthResponse> loginUser(String email, String password) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.loginEndpoint}');
    final response = await _httpClient.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final token = data['token']; // Access token
      final user = User.fromJson(data['user']);
      final refreshToken = data['refreshToken']; // If your backend provides it

      return AuthResponse(token: token, user: user, refreshToken: refreshToken);
    } else {
      final errorData = json.decode(response.body);
      throw Exception('Login failed: ${errorData['message'] ?? response.statusCode}');
    }
  }

  Future<User> getAuthUser() async {
    // Use the authenticatedRequest helper for this call
    final response = await _authenticatedRequest((token) async {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getAuthUserEndpoint}');
      return await _httpClient.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return User.fromJson(data);
    } else {
      final errorData = json.decode(response.body);
      throw Exception('Failed to get authenticated user: ${errorData['message'] ?? response.statusCode}');
    }
  }

  // Example of another authenticated call using the helper
  Future<void> createPost(Map<String, dynamic> postData) async {
    final response = await _authenticatedRequest((token) async {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.createPostEndpoint}');
      return await _httpClient.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(postData),
      );
    });

    if (response.statusCode != 201) { // Assuming 201 for creation
      final errorData = json.decode(response.body);
      throw Exception('Failed to create post: ${errorData['message'] ?? response.statusCode}');
    }
  }

  // ... other methods in AuthService would also use _authenticatedRequest
}