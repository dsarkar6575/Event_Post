// myapp/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:myapp/models/auth_response_model.dart';
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
        _currentUser = await _authService.getAuthUser();
        print('✅ Auto-login successful for: ${_currentUser?.username}');
        SocketService().connect(_token!);
      } catch (e) {
        print('❌ Auto-login failed, token might be expired: $e');
        await logout();
      }
    } else {
      print('⚠️ No token found for auto-login.');
    }

    _isLoading = false;
    notifyListeners();
  }

  // New method for Step 1: Sending the OTP
  Future<bool> sendOtp(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.sendOtp(email);
      print('✅ OTP sent successfully to $email');
      return true;
    } catch (e) {
      _error = 'Failed to send OTP: ${e.toString()}';
      print(_error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // New method for Step 2: Verifying the OTP and completing registration
  Future<bool> verifyOtpAndRegister(String email, String otp, String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final AuthResponse response = await _authService.verifyOtpAndRegister(email, otp, username, password);
      
      _token = response.token;
      _currentUser = response.user;

      await SecureStorage.saveToken(_token!);
      await SecureStorage.saveUserId(_currentUser!.id);
      if (response.refreshToken != null) {
        await SecureStorage.saveRefreshToken(response.refreshToken!);
      }

      SocketService().connect(_token!);

      print('✅ Registration successful for: ${_currentUser?.username}');
      return true;
    } catch (e) {
      _error = 'Registration failed: ${e.toString()}';
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
      final AuthResponse response = await _authService.loginUser(email, password);
      _token = response.token;
      _currentUser = response.user;

      await SecureStorage.saveToken(_token!);
      await SecureStorage.saveUserId(_currentUser!.id);
      if (response.refreshToken != null) {
        await SecureStorage.saveRefreshToken(response.refreshToken!);
      }

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