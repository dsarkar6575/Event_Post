import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:myapp/core/api_constants.dart';
import 'package:myapp/models/post_model.dart';
import 'package:myapp/services/api_base_service.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;


class PostService {
  final ApiBaseService _apiService = ApiBaseService();

  Future<Post> createPost({
    required String title,
    required String description,
    File? mediaFile,
    bool isEvent = false,
    DateTime? eventDateTime,
    String? location,
  }) async {
    final fields = <String, String>{
      'title': title,
      'description': description,
      'isEvent': isEvent.toString(),
    };

    if (isEvent && eventDateTime != null) {
      fields['eventDateTime'] = eventDateTime.toIso8601String();
    }

    if (location != null && location.isNotEmpty) {
      fields['location'] = location;
    }

    List<http.MultipartFile> files = [];

    if (mediaFile != null) {
      try {
        final mimeTypeData = lookupMimeType(mediaFile.path)?.split('/');
        if (mimeTypeData == null || mimeTypeData.length != 2) {
          throw Exception('Unsupported file type');
        }

        files.add(await http.MultipartFile.fromPath(
          'mediaUrls',
          mediaFile.path,
          contentType: MediaType(mimeTypeData[0], mimeTypeData[1]),
          filename: p.basename(mediaFile.path),
        ));
      } catch (e) {
        print('Error preparing media file: $e');
        throw Exception('Failed to prepare media file for upload');
      }
    }

    try {
      final response = await _apiService.postMultipart(
        ApiConstants.createPostEndpoint,
        fields,
        files,
      );

      print('CreatePost Response: $response');

      if (response == null) {
        throw Exception('API response is null');
      }

      if (response.containsKey('error') || response.containsKey('message')) {
        final errorMessage = response['error'] ?? response['message'];
        throw Exception('API Error: $errorMessage');
      }

      if (response['post'] == null) {
        throw Exception('API response does not contain post data');
      }

      return Post.fromJson(response['post']);
    } catch (e, stackTrace) {
      print('Error in createPost: $e');
      print('StackTrace: $stackTrace');
      rethrow;
    }
  }

  Future<List<Post>> getAllPosts() async {
    try {
      final response = await _apiService.get(ApiConstants.getAllPostsEndpoint);

      print('Response received in getAllPosts: $response');

      if (response is List) {
        print('Response is a List. Mapping to Posts...');
        final List<Post> posts = response.map((postJson) {
          print('Processing post JSON: $postJson');
          try {
            return Post.fromJson(postJson);
          } catch (e) {
            print('Error parsing post JSON: $e');
            print('Post JSON causing error: $postJson');
            rethrow;
          }
        }).toList();
        print('Successfully mapped to Posts. Count: ${posts.length}');
        return posts;
      } else {
        print('Unexpected response format in getAllPosts: $response');
        throw Exception('Failed to load posts due to unexpected response format.');
      }
    } catch (e) {
      print('Error fetching or processing posts: $e');
      rethrow;
    }
  }

  Future<Post> getPostById(String postId) async {
    try {
      final response = await _apiService.get(ApiConstants.getPostByIdEndpoint(postId));
      print('API Response for getPostById($postId): $response');

      if (response != null && response is Map<String, dynamic>) {
        // Ensure the response directly represents the Post, not nested in a 'post' key
        // If your API returns {'post': {...}} then use Post.fromJson(response['post'])
        // If your API returns {...} directly, use Post.fromJson(response)
        // Based on your togglePostAttendance and togglePostInterest, it seems it's nested
        if (response.containsKey('post')) {
          return Post.fromJson(response['post']);
        }
        return Post.fromJson(response); // Fallback if not nested
      } else {
        throw Exception('Invalid response format or post not found');
      }
    } catch (e) {
      print('Error in getPostById: $e');
      rethrow; // Re-throw to be handled by caller
    }
  }

  Future<Post> updatePost(
    String postId, {
    String? title,
    String? description,
    bool? isEvent,
    DateTime? eventDateTime,
    String? location,
    File? newMediaFile,
    bool? clearExistingMedia,
  }) async {
    final fields = <String, String>{};

    if (title != null) fields['title'] = title;
    if (description != null) fields['description'] = description;
    if (isEvent != null) fields['isEvent'] = isEvent.toString();
    if (eventDateTime != null) fields['eventDateTime'] = eventDateTime.toIso8601String();
    if (location != null) fields['location'] = location;
    if (clearExistingMedia != null && clearExistingMedia) fields['clearExistingMedia'] = 'true';

    List<http.MultipartFile> files = [];

    if (newMediaFile != null) {
      try {
        final mimeTypeData = lookupMimeType(newMediaFile.path)?.split('/');
        files.add(await http.MultipartFile.fromPath(
          'mediaUrls',
          newMediaFile.path,
          contentType: MediaType(mimeTypeData?[0] ?? 'image', mimeTypeData?[1] ?? 'jpeg'),
        ));
      } catch (e) {
        print('Error preparing media file: $e');
        throw Exception('Failed to prepare media file for upload');
      }
    }

    try {
      final response = await _apiService.putMultipart(
        ApiConstants.updatePostEndpoint(postId),
        fields,
        files,
      );

      if (response == null) throw Exception('Null response from server');

      // The update endpoint should ideally return the updated post directly
      if (response.containsKey('post')) {
        return Post.fromJson(response['post']);
      } else if (response.containsKey('error')) {
        throw Exception(response['error']);
      } else {
        // If the update response doesn't contain the post, explicitly fetch it
        print('Update response missing "post" key. Fetching updated post by ID.');
        return await getPostById(postId);
      }
    } catch (e) {
      print('Error updating post: $e');
      rethrow;
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await _apiService.delete(ApiConstants.deletePostEndpoint(postId));
    } catch (e) {
      print('Error deleting post: $e');
      rethrow;
    }
  }

  Future<Post> togglePostInterest(String postId) async {
    try {
      final response = await _apiService.put(
        ApiConstants.togglePostInterestEndpoint(postId),
        {}, // Empty body as per API description
      );
      if (response == null || !response.containsKey('post')) { // Check for 'post' key
        throw Exception('Failed to toggle interest: Invalid response or missing post data');
      }
      return Post.fromJson(response['post']); // Parse the nested 'post'
    } catch (e) {
      print('Error toggling post interest: $e');
      rethrow;
    }
  }

  Future<List<Post>> getInterestedPosts() async {
    try {
      final response = await _apiService.get(ApiConstants.getInterestedPostsEndpoint);
      if (response is List) {
        return response.map((postJson) => Post.fromJson(postJson)).toList();
      } else {
        throw Exception('Failed to load interested posts: Invalid response format');
      }
    } catch (e) {
      print('Error fetching interested posts: $e');
      rethrow;
    }
  }

  Future<Post> togglePostAttendance(String postId) async {
    try {
      final response = await _apiService.put(
        ApiConstants.togglePostAttendanceEndpoint(postId),
        {}, // No body needed
      );
      // Ensure the response contains the updated 'post' object
      if (response == null || !response.containsKey('post')) {
        throw Exception('Failed to toggle attendance: Invalid response or missing post data');
      }
      return Post.fromJson(response['post']); // Parse the nested 'post'
    } catch (e) {
      print('Error toggling post attendance: $e');
      rethrow;
    }
  }

  Future<List<Post>> getAttendedPosts() async {
    try {
      final response = await _apiService.get(ApiConstants.getAttendedPostsEndpoint);
      if (response is List) {
        return response.map((postJson) => Post.fromJson(postJson)).toList();
      } else {
        throw Exception('Failed to load attended posts: Invalid response format');
      }
    } catch (e) {
      print('Error fetching attended posts: $e');
      rethrow;
    }
  }
}