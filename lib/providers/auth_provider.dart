// myapp/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/utils/secure_storage.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  String? _token;
  bool _isLoading = true;
  String? _error;

  final AuthService _authService = AuthService();

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _token != null && _currentUser != null;

  AuthProvider() {
    tryAutoLogin(); // ✅ Run on startup
  }

  Future<void> tryAutoLogin() async {
    _isLoading = true;
    notifyListeners();

    final token = await SecureStorage.getToken();
    final userId = await SecureStorage.getUserId();
    final refreshToken = await SecureStorage.getRefreshToken(); // Get refresh token

    print('🔐 Access Token from storage: $token');
    print('🔑 Refresh Token from storage: $refreshToken');
    print('🆔 User ID from storage: $userId');

    if (token != null && userId != null) {
      _token = token; // Set current token for use
      try {
        _currentUser = await _authService.getAuthUser(); // AuthService will handle refresh
        print('✅ Fetched current user: ${_currentUser?.username}');
      } catch (e) {
        print('❌ Failed to fetch user (likely invalid token or refresh failed): $e');
        await logout(); // Invalid token or refresh failed — clear everything
      }
    } else {
      print('⚠️ Token, refresh token, or user ID missing. Not logged in.');
      await logout(); // Also handle clean state
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> register(String email, String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.registerUser(email, username, password);
      _token = response.token;
      _currentUser = response.user;

      await SecureStorage.saveToken(_token!);
      await SecureStorage.saveUserId(_currentUser!.id);
      if (response.refreshToken != null) { // Save refresh token if provided
        await SecureStorage.saveRefreshToken(response.refreshToken!);
      }

      print('✅ Registration successful: ${_currentUser?.username}');
      return true;
    } catch (e) {
      _error = 'Register failed: ${e.toString()}';
      print(_error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.loginUser(email, password);
      _token = response.token;
      _currentUser = response.user;

      await SecureStorage.saveToken(_token!);
      await SecureStorage.saveUserId(_currentUser!.id);
      if (response.refreshToken != null) { // Save refresh token if provided
        await SecureStorage.saveRefreshToken(response.refreshToken!);
      }

      print('✅ Login successful: ${_currentUser?.username}');
      return true;
    } catch (e) {
      _error = 'Login failed: ${e.toString()}';
      print(_error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    await SecureStorage.clearAll(); // Clears access and refresh tokens, and user ID
    notifyListeners();
    print('🚪 Logged out and storage cleared');
  }

  void updateCurrentUser(User user) {
    _currentUser = user;
    notifyListeners();
  }
}