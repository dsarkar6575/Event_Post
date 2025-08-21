import 'package:flutter/material.dart';
import 'package:myapp/models/auth_response_model.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/services/socket_service.dart';
import 'package:myapp/utils/secure_storage.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  String? _token;
  bool _isLoading = false;
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

  /// ✅ Clear previous error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// ✅ Try auto login on app start
  Future<void> tryAutoLogin() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await SecureStorage.getToken();

      if (token != null) {
        _token = token;
        _currentUser = await _authService.getAuthUser();
        debugPrint('✅ Auto-login successful for: ${_currentUser?.username}');
        SocketService().connect(_token!);
      } else {
        debugPrint('⚠️ No token found for auto-login.');
      }
    } catch (e) {
      debugPrint('❌ Auto-login failed, token might be expired: $e');
      await logout();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// ✅ Send OTP for registration
  Future<bool> sendOtp(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.sendOtp(email);
      debugPrint('✅ OTP sent successfully to $email');
      return true;
    } catch (e) {
      _error = 'Failed to send OTP: ${e.toString()}';
      debugPrint(_error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ✅ Verify OTP and complete registration (with userType)
  Future<bool> verifyOtpAndRegister(
      String email, String otp, String username, String password, String userType) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final AuthResponse response = await _authService.verifyOtpAndRegister(
        email,
        otp,
        username,
        password,
        userType, // ✅ Added userType
      );

      await _saveAuthData(response);
      debugPrint('✅ Registration successful for: ${_currentUser?.username}');
      return true;
    } catch (e) {
      _error = 'Registration failed: ${e.toString()}';
      debugPrint(_error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ✅ Login user
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final AuthResponse response = await _authService.loginUser(email, password);
      await _saveAuthData(response);
      debugPrint('✅ Login successful: ${_currentUser?.username}');
      return true;
    } catch (e) {
      _error = 'Login failed: ${e.toString()}';
      debugPrint(_error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ✅ Logout user and clear storage
  Future<void> logout() async {
    SocketService().disconnect();
    _token = null;
    _currentUser = null;
    await SecureStorage.clearAll();
    debugPrint('🚪 Logged out, socket disconnected, and storage cleared');
    notifyListeners();
  }

  /// ✅ Update current user in provider
  void updateCurrentUser(User user) {
    _currentUser = user;
    notifyListeners();
  }

  /// ✅ Helper to save auth data and connect socket
  Future<void> _saveAuthData(AuthResponse response) async {
    _token = response.token;
    _currentUser = response.user;

    await SecureStorage.saveToken(_token!);
    await SecureStorage.saveUserId(_currentUser!.id);
    if (response.refreshToken != null) {
      await SecureStorage.saveRefreshToken(response.refreshToken!);
    }

    SocketService().connect(_token!);
  }
}
