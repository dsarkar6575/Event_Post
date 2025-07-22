import 'dart:io';

import 'package:flutter/material.dart';
import 'package:myapp/models/post_model.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/services/user_service.dart';

class UserProvider extends ChangeNotifier {
  final UserService _userService = UserService();
  User? _viewedUser;
  List<Post> _userPosts = [];
  bool _isLoading = false;
  String? _error;

  User? get viewedUser => _viewedUser;
  List<Post> get userPosts => _userPosts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchUserProfile(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _viewedUser = await _userService.getUserProfile(userId);
    } catch (e) {
      _error = e.toString();
      print('Fetch User Profile Error: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUserProfile(String userId, {
    String? username,
    String? bio,
    File? profileImage,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final updatedUser = await _userService.updateUserProfile(
        userId,
        username: username,
        bio: bio,
        profileImage: profileImage,
      );
      _viewedUser = updatedUser; // Update the viewed user
      // If the updated user is the current authenticated user, also update in AuthProvider
      // This is a common pattern, but requires access to AuthProvider
      // Provider.of<AuthProvider>(context, listen: false).updateCurrentUser(updatedUser);
    } catch (e) {
      _error = e.toString();
      print('Update User Profile Error: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUserPosts(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _userPosts = await _userService.getUserPosts(userId);
    } catch (e) {
      _error = e.toString();
      print('Fetch User Posts Error: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> followUser(String userId, String currentUserId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _userService.followUser(userId);
      // Manually update the viewed user's followers
      if (_viewedUser != null && !_viewedUser!.followers.contains(currentUserId)) {
        _viewedUser = _viewedUser!.copyWith(
          followers: [..._viewedUser!.followers, currentUserId],
        );
      }
    } catch (e) {
      _error = e.toString();
      print('Follow User Error: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> unfollowUser(String userId, String currentUserId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _userService.unfollowUser(userId);
      // Manually update the viewed user's followers
      if (_viewedUser != null && _viewedUser!.followers.contains(currentUserId)) {
        _viewedUser = _viewedUser!.copyWith(
          followers: _viewedUser!.followers.where((id) => id != currentUserId).toList(),
        );
      }
    } catch (e) {
      _error = e.toString();
      print('Unfollow User Error: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}