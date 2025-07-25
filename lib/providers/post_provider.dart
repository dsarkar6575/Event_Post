// providers/post_provider.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:myapp/models/post_model.dart';
import 'package:myapp/services/post_service.dart';

class PostProvider extends ChangeNotifier {
  final PostService postService = PostService();
  List<Post> _posts = [];
  List<Post> _interestedPosts = [];
  bool _isLoading = false;
  String? _error;

  List<Post> get posts => _posts;
  List<Post> get interestedPosts => _interestedPosts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAllPosts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _posts = await postService.getAllPosts();
    } catch (e) {
      _error = e.toString();
      print('Fetch All Posts Error: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createPost({
    required String title,
    required String description,
    File? mediaFile,
    bool isEvent = false,
    DateTime? eventDateTime,
    String? location,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final newPost = await postService.createPost(
        title: title,
        description: description,
        mediaFile: mediaFile,
        isEvent: isEvent,
        eventDateTime: eventDateTime,
        location: location,
      );
      _posts.insert(0, newPost); // Add new post to the beginning of the list
    } catch (e) {
      _error = e.toString();
      print('Create Post Error: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePost(
    String postId, {
    String? title,
    String? description,
    List<String>? mediaUrls, // This is not used directly for update, newMediaFile is used.
    bool? isEvent,
    DateTime? eventDateTime,
    String? location,
    File? newMediaFile,
    bool? clearExistingMedia, // Add this parameter
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final updatedPost = await postService.updatePost(
        postId,
        title: title,
        description: description,
        // mediaUrls: mediaUrls, // This parameter is not needed here
        isEvent: isEvent,
        eventDateTime: eventDateTime,
        location: location,
        newMediaFile: newMediaFile,
        clearExistingMedia: clearExistingMedia, // Pass the flag
      );
      final index = _posts.indexWhere((post) => post.id == postId);
      if (index != -1) {
        _posts[index] = updatedPost;
      }
      // Success case: Clear any previous error and show success message
      _error = null; // Important: Clear error on success
    } catch (e) {
      _error = e.toString();
      print('Update Post Error: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deletePost(String postId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await postService.deletePost(postId);
      _posts.removeWhere((post) => post.id == postId);
    } catch (e) {
      _error = e.toString();
      print('Delete Post Error: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> togglePostInterest(String postId, String currentUserId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final updatedPost = await postService.togglePostInterest(postId);
      final index = _posts.indexWhere((post) => post.id == postId);
      if (index != -1) {
        _posts[index] = updatedPost;
        // Also update interestedPosts list if necessary
        if (updatedPost.interestedUsers.contains(currentUserId)) {
          if (!_interestedPosts.any((post) => post.id == updatedPost.id)) {
            _interestedPosts.add(updatedPost);
          }
        } else {
          _interestedPosts.removeWhere((post) => post.id == updatedPost.id);
        }
      }
    } catch (e) {
      _error = e.toString();
      print('Toggle Post Interest Error: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchInterestedPosts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _interestedPosts = await postService.getInterestedPosts();
    } catch (e) {
      _error = e.toString();
      print('Fetch Interested Posts Error: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}