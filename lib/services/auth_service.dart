import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myapp/core/api_constants.dart';
import 'package:myapp/models/auth_response_model.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/utils/secure_storage.dart';

class AuthService {
  final http.Client _httpClient = http.Client();

  /// ✅ Handles authenticated requests with automatic token refresh
  Future<http.Response> _authenticatedRequest(
      Future<http.Response> Function(String token) requestBuilder) async {
    String? accessToken = await SecureStorage.getToken();
    String? refreshToken = await SecureStorage.getRefreshToken();

    if (accessToken == null) {
      throw Exception('No access token available. User not logged in.');
    }

    http.Response response = await requestBuilder(accessToken);

    if (response.statusCode == 401 && refreshToken != null) {
      print('⚠️ Access token expired, attempting refresh...');
      try {
        final newTokens = await _refreshAccessToken(refreshToken);
        final newAccessToken = newTokens['accessToken'];
        final newRefreshToken = newTokens['refreshToken'];

        await SecureStorage.saveToken(newAccessToken);
        if (newRefreshToken != null) {
          await SecureStorage.saveRefreshToken(newRefreshToken);
        }

        // ✅ Retry original request with the new token
        response = await requestBuilder(newAccessToken);
      } catch (e) {
        print('❌ Failed to refresh token: $e');
        rethrow;
      }
    }

    return response;
  }

  /// ✅ Refresh token logic
  Future<Map<String, dynamic>> _refreshAccessToken(String refreshToken) async {
    final url =
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.refreshTokenEndpoint}');
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
      throw Exception(
          'Failed to refresh token: ${response.statusCode} - ${response.body}');
    }
  }

  /// ✅ Step 1: Send OTP for registration
  Future<void> sendOtp(String email) async {
    final url =
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.registerEndpoint}');
    final response = await _httpClient.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email}),
    );

    if (response.statusCode != 200) {
      final errorData = json.decode(response.body);
      throw Exception(
          'Failed to send OTP: ${errorData['msg'] ?? response.statusCode}');
    }
  }

  /// ✅ Step 2: Verify OTP & Complete Registration (Added userType)
  Future<AuthResponse> verifyOtpAndRegister(
      String email, String otp, String username, String password, String userType) async {
    final url =
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.verifyOtpEndpoint}');
    final response = await _httpClient.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'otp': otp,
        'username': username,
        'password': password,
        'userType': userType, // ✅ Added userType for backend
      }),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return AuthResponse.fromJson(data);
    } else {
      final errorData = json.decode(response.body);
      throw Exception(
          'Verification failed: ${errorData['msg'] ?? response.statusCode}');
    }
  }

  /// ✅ Login user
  Future<AuthResponse> loginUser(String email, String password) async {
    final url =
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.loginEndpoint}');
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
      return AuthResponse.fromJson(data);
    } else {
      final errorData = json.decode(response.body);
      throw Exception(
          'Login failed: ${errorData['message'] ?? response.statusCode}');
    }
  }

  /// ✅ Get authenticated user profile
  Future<User> getAuthUser() async {
    final response = await _authenticatedRequest((token) async {
      final url = Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.getAuthUserEndpoint}');
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
      throw Exception(
          'Failed to get authenticated user: ${errorData['message'] ?? response.statusCode}');
    }
  }

  /// ✅ Create a new post
  Future<void> createPost(Map<String, dynamic> postData) async {
    final response = await _authenticatedRequest((token) async {
      final url = Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.createPostEndpoint}');
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
      throw Exception(
          'Failed to create post: ${errorData['message'] ?? response.statusCode}');
    }
  }
}
