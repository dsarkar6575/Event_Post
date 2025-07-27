// providers/post_provider.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:myapp/models/post_model.dart';
import 'package:myapp/services/post_service.dart';

class PostProvider extends ChangeNotifier {
  final PostService postService = PostService(); // Consider injecting this for testability
  List<Post> _posts = [];
  List<Post> _interestedPosts = [];
  bool _isLoading = false; // General loading for initial fetches (e.g., fetchAllPosts)
  String? _error; // General error for fetches

  List<Post> _attendedPosts = [];

  // New: Set to keep track of posts currently undergoing an action (e.g., toggle interest/attendance)
  // This helps with granular loading indicators on individual PostCards.
  final Set<String> _loadingPostIds = {};

  List<Post> get attendedPosts => _attendedPosts;
  List<Post> get posts => _posts;
  List<Post> get interestedPosts => _interestedPosts;
  bool get isLoading => _isLoading; // General loading state
  String? get error => _error; // General error state

  // New: Check if a specific post is currently loading due to an action
  bool isPostLoading(String postId) => _loadingPostIds.contains(postId);

  // --- Utility Methods for List Management ---
  // Safely updates a post in a given list or adds it if not found.
  // Returns true if updated/added, false if no change.
  bool _updatePostInList(List<Post> list, Post updatedPost) {
    final index = list.indexWhere((p) => p.id == updatedPost.id);
    if (index != -1) {
      if (list[index] != updatedPost) { // Only update if content changed (requires == in Post model)
        list[index] = updatedPost;
        return true;
      }
      return false; // No change needed
    } else {
      list.add(updatedPost); // Add if not found
      return true;
    }
  }

  // Safely removes a post from a given list.
  // Returns true if removed, false otherwise.
 void _removePostFromList(List<Post> list, String postId) {
  list.removeWhere((p) => p.id == postId);
}
  // --- End Utility Methods ---


  Future<void> fetchAllPosts() async {
    if (_isLoading) return; // Prevent multiple simultaneous fetches
    _isLoading = true;
    _error = null;
    notifyListeners(); // Notify to show general loading indicator

    try {
      _posts = await postService.getAllPosts();
      print('DEBUG: Fetched ${_posts.length} all posts.');
    } catch (e) {
      _error = e.toString();
      print('Fetch All Posts Error: $_error');
    } finally {
      _isLoading = false;
      notifyListeners(); // Notify to update UI with fetched posts or error
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
    _isLoading = true; // General loading for creation
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
      // If new post is an event, and the current user is interested/attended,
      // it might need to be added to _interestedPosts or _attendedPosts too.
      // However, usually, newly created posts don't have existing user interactions.
    } catch (e) {
      _error = e.toString();
      print('Create Post Error: $_error');
      rethrow; // Re-throw to allow UI to catch specific errors for dialogs etc.
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePost(
    String postId, {
    String? title,
    String? description,
    List<String>? mediaUrls, // This parameter is usually handled by backend, not directly passed from UI for update
    bool? isEvent,
    DateTime? eventDateTime,
    String? location,
    File? newMediaFile,
    bool? clearExistingMedia,
  }) async {
    _isLoading = true; // General loading for update
    _error = null;
    notifyListeners();

    try {
      final updatedPost = await postService.updatePost(
        postId,
        title: title,
        description: description,
        isEvent: isEvent,
        eventDateTime: eventDateTime,
        location: location,
        newMediaFile: newMediaFile,
        clearExistingMedia: clearExistingMedia,
      );
      
      // Update all relevant lists
      _updatePostInList(_posts, updatedPost);
      _updatePostInList(_interestedPosts, updatedPost); // If it was in interested, update it
      _updatePostInList(_attendedPosts, updatedPost); // If it was in attended, update it

      _error = null;
    } catch (e) {
      _error = e.toString();
      print('Update Post Error: $_error');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deletePost(String postId) async {
    _isLoading = true; // General loading for delete
    _error = null;
    notifyListeners();

    try {
      await postService.deletePost(postId);
      // Remove from all relevant lists
      _removePostFromList(_posts, postId);
      _removePostFromList(_interestedPosts, postId);
      _removePostFromList(_attendedPosts, postId);
    } catch (e) {
      _error = e.toString();
      print('Delete Post Error: $_error');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> togglePostInterest(String postId, String currentUserId) async {
    if (_loadingPostIds.contains(postId)) return; // Prevent multiple actions on the same post
    
    _loadingPostIds.add(postId); // Start loading for this specific post
    notifyListeners(); // Notify to show individual post loading indicator

    try {
      final updatedPost = await postService.togglePostInterest(postId);

      // Update main posts list
      _updatePostInList(_posts, updatedPost);

      // Update interestedPosts list based on the new state returned from server
      if (updatedPost.interestedUsers.contains(currentUserId)) {
        _updatePostInList(_interestedPosts, updatedPost);
      } else {
        _removePostFromList(_interestedPosts, updatedPost.id);
      }
      print('DEBUG: Post ${updatedPost.id}: User $currentUserId toggled interest. Server response processed.');

    } catch (e) {
      _error = e.toString(); // Set a general error, or pass specific error back to UI
      print('Toggle Post Interest Error: $_error');
      rethrow; // Re-throw so the UI can catch and show a snackbar/dialog
    } finally {
      _loadingPostIds.remove(postId); // End loading for this specific post
      notifyListeners(); // Important: Notify listeners after all state changes
    }
  }

  Future<void> fetchInterestedPosts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _interestedPosts = await postService.getInterestedPosts();
      print('DEBUG: Fetched ${_interestedPosts.length} interested posts.');
    } catch (e) {
      _error = e.toString();
      print('Fetch Interested Posts Error: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAttendedPosts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _attendedPosts = await postService.getAttendedPosts();
      print('DEBUG: Fetched ${_attendedPosts.length} attended posts via fetchAttendedPosts().');
    } catch (e) {
      _error = e.toString();
      print('Fetch Attended Posts Error: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> togglePostAttendance(String postId, String currentUserId) async {
    if (_loadingPostIds.contains(postId)) return; // Prevent multiple actions on the same post

    _loadingPostIds.add(postId); // Start loading for this specific post
    notifyListeners(); // Notify listeners to show individual post loading indicator

    try {
      // 1. Call the service to update attendance on the backend.
      // This should return the most current state of the post from the server.
      final updatedPostFromServer = await postService.togglePostAttendance(postId);

      // 2. Update the main _posts list with the updated post from the server.
      // This is the source of truth.
      _updatePostInList(_posts, updatedPostFromServer);
      print('DEBUG: Main _posts list updated for ${updatedPostFromServer.id}.');

      // 3. Update the _attendedPosts list based on the new status from the server
      final isNowAttended = updatedPostFromServer.attendedUsers.contains(currentUserId);

      if (isNowAttended) {
        _updatePostInList(_attendedPosts, updatedPostFromServer);
        print('DEBUG: Added/Updated post ${updatedPostFromServer.id} in _attendedPosts.');
      } else {
        _removePostFromList(_attendedPosts, updatedPostFromServer.id);
        print('DEBUG: Removed post ${updatedPostFromServer.id} from _attendedPosts.');
      }

      // 4. Crucially, update the _interestedPosts list based on the server's response.
      // If the backend automatically removes interest when attendance is marked,
      // this logic will correctly reflect that.
      final isNowInterested = updatedPostFromServer.interestedUsers.contains(currentUserId);
      if (isNowInterested) {
        _updatePostInList(_interestedPosts, updatedPostFromServer);
        print('DEBUG: Added/Updated post ${updatedPostFromServer.id} in _interestedPosts (still interested).');
      } else {
        // If the user is no longer interested (e.g., because they attended), remove from interestedPosts.
        _removePostFromList(_interestedPosts, updatedPostFromServer.id);
        print('DEBUG: Removed post ${updatedPostFromServer.id} from _interestedPosts (no longer interested).');
      }

    } catch (e) {
      _error = e.toString(); // Set a general error, or pass specific error back to UI
      print('Error toggling post attendance: $e');
      rethrow; // Re-throw so the UI can catch and show a snackbar/dialog
    } finally {
      _loadingPostIds.remove(postId); // End loading for this specific post
      notifyListeners(); // Important: Notify listeners after all state changes
    }
  }
}