import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myapp/core/api_constants.dart';
import 'package:myapp/models/auth_response_model.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/utils/secure_storage.dart';


class AuthService {
  final http.Client _httpClient = http.Client();

  // Helper method for authenticated requests
  Future<http.Response> _authenticatedRequest(
      Future<http.Response> Function(String token) requestBuilder) async {
    String? accessToken = await SecureStorage.getToken();
    String? refreshToken = await SecureStorage.getRefreshToken();

    if (accessToken == null) {
      throw Exception('No access token available. User not logged in.');
    }

    http.Response response = await requestBuilder(accessToken);

    if (response.statusCode == 401 && refreshToken != null) {
      print('Access token expired or invalid, attempting to refresh...');
      try {
        final newTokens = await _refreshAccessToken(refreshToken);
        final newAccessToken = newTokens['accessToken'];
        final newRefreshToken = newTokens['refreshToken'];

        await SecureStorage.saveToken(newAccessToken);
        if (newRefreshToken != null) {
          await SecureStorage.saveRefreshToken(newRefreshToken);
        }
        
        // Retry the original request with the new access token
        response = await requestBuilder(newAccessToken);
      } catch (e) {
        print('Failed to refresh token: $e');
        rethrow;
      }
    }

    return response;
  }

  Future<Map<String, dynamic>> _refreshAccessToken(String refreshToken) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.refreshTokenEndpoint}');
    final response = await _httpClient.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'refreshToken': refreshToken}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'accessToken': data['accessToken'],
        'refreshToken': data['refreshToken'],
      };
    } else {
      throw Exception('Failed to refresh token: ${response.statusCode} - ${response.body}');
    }
  }

  // New method: Step 1 of registration, sends the OTP
  Future<void> sendOtp(String email) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.registerEndpoint}');
    final response = await _httpClient.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email}),
    );

    if (response.statusCode != 200) {
      final errorData = json.decode(response.body);
      throw Exception('Failed to send OTP: ${errorData['msg'] ?? response.statusCode}');
    }
  }

  // New method: Step 2 of registration, verifies OTP and creates the user
  Future<AuthResponse> verifyOtpAndRegister(String email, String otp, String username, String password) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.verifyOtpEndpoint}');
    final response = await _httpClient.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'otp': otp,
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return AuthResponse.fromJson(data);
    } else {
      final errorData = json.decode(response.body);
      throw Exception('Verification failed: ${errorData['msg'] ?? response.statusCode}');
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
      final token = data['token'];
      final user = User.fromJson(data['user']);
      final refreshToken = data['refreshToken'];

      return AuthResponse(token: token, user: user, refreshToken: refreshToken);
    } else {
      final errorData = json.decode(response.body);
      throw Exception('Login failed: ${errorData['message'] ?? response.statusCode}');
    }
  }

  Future<User> getAuthUser() async {
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

    if (response.statusCode != 201) {
      final errorData = json.decode(response.body);
      throw Exception('Failed to create post: ${errorData['message'] ?? response.statusCode}');
    }
  }
}
