import 'package:flutter/material.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/utils/secure_storage.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _token != null && _currentUser != null;

  final AuthService _authService = AuthService();

  AuthProvider() {
    _loadUserFromStorage();
  }

  Future<void> _loadUserFromStorage() async {
    _isLoading = true;
    notifyListeners();
    try {
      _token = await SecureStorage.getToken();
      final userId = await SecureStorage.getUserId();
      if (_token != null && userId != null) {
        _currentUser = await _authService.getAuthUser(); // Re-fetch user to ensure data is fresh
      }
    } catch (e) {
      _error = 'Failed to load user: $e';
      print(_error);
      _token = null;
      _currentUser = null;
      await SecureStorage.clearAll(); // Clear corrupted data
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
      return true;
    } catch (e) {
      _error = e.toString();
      print('Register Error: $_error');
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
      return true;
    } catch (e) {
      _error = e.toString();
      print('Login Error: $_error');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    await SecureStorage.clearAll();
    notifyListeners();
  }

  void updateCurrentUser(User user) {
    _currentUser = user;
    notifyListeners();
  }
}