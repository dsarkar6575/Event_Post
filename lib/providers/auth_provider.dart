// myapp/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/services/socket_service.dart';
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
    tryAutoLogin();
  }

  Future<void> tryAutoLogin() async {
    _isLoading = true;
    notifyListeners();

    final token = await SecureStorage.getToken();

    if (token != null) {
      _token = token;
      try {
        // Attempt to fetch user data with the stored token
        _currentUser = await _authService.getAuthUser();
        print('✅ Auto-login successful for: ${_currentUser?.username}');
        
        // ✅ FIX: Connect to the socket on successful auto-login
        SocketService().connect(_token!);

      } catch (e) {
        print('❌ Auto-login failed, token might be expired: $e');
        await logout(); // Clear invalid token and user data
      }
    } else {
      print('⚠️ No token found for auto-login.');
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
      if (response.refreshToken != null) {
        await SecureStorage.saveRefreshToken(response.refreshToken!);
      }

      // ✅ FIX: Connect to the socket on successful registration
      SocketService().connect(_token!);

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
      if (response.refreshToken != null) {
        await SecureStorage.saveRefreshToken(response.refreshToken!);
      }

      // ✅ FIX: Moved the connect call to *after* getting the token.
      SocketService().connect(_token!);

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
    // ✅ FIX: Disconnect from the socket when logging out.
    SocketService().disconnect();

    _token = null;
    _currentUser = null;
    await SecureStorage.clearAll();
    
    print('🚪 Logged out, socket disconnected, and storage cleared');
    notifyListeners();
  }

  void updateCurrentUser(User user) {
    _currentUser = user;
    notifyListeners();
  }
}