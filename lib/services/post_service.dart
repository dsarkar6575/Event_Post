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

  // Helper function to safely get MIME type
  MediaType _getMediaType(String filePath) {
    final mimeType = lookupMimeType(filePath);
    if (mimeType == null) {
      // Fallback for unknown file types, e.g., plain text or application/octet-stream
      return MediaType('application', 'octet-stream');
    }
    final mimeTypeData = mimeType.split('/');
    if (mimeTypeData.length != 2) {
      throw FormatException('Invalid MIME type format: $mimeType');
    }
    return MediaType(mimeTypeData[0], mimeTypeData[1]);
  }

  Future<Post> createPost({
    required String title,
    required String description,
    File? mediaFile,
    bool isEvent = false,
    DateTime? eventDateTime,
    String? location,
  }) async {
    try {
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
        files.add(await http.MultipartFile.fromPath(
          'mediaUrls', // This should match the backend's expected field name for file uploads
          mediaFile.path,
          contentType: _getMediaType(mediaFile.path),
          filename: p.basename(mediaFile.path),
        ));
      }

      final response = await _apiService.postMultipart(
        ApiConstants.createPostEndpoint,
        fields,
        files,
      );

      print('CreatePost Response: $response');

      if (response == null) {
        throw Exception('API response is null for createPost.');
      }

      // Assuming API returns {'error': 'message'} or {'message': 'error'} for failures
      if (response.containsKey('error') || response.containsKey('message')) {
        final errorMessage = response['error'] ?? response['message'] ?? 'Unknown error during post creation.';
        throw Exception('API Error: $errorMessage');
      }

      // Consistently expect 'post' key for single post responses
      if (response['post'] == null) {
        throw Exception('API response for createPost does not contain post data under "post" key.');
      }

      return Post.fromJson(response['post']);
    } catch (e, stackTrace) {
      print('Error in createPost: $e');
      print('StackTrace: $stackTrace');
      rethrow; // Re-throw to propagate to PostProvider
    }
  }

  Future<List<Post>> getAllPosts() async {
    try {
      final response = await _apiService.get(ApiConstants.getAllPostsEndpoint);

      print('Response received in getAllPosts: $response');

      if (response is List) {
        print('Response is a List. Mapping to Posts...');
        final List<Post> posts = response.map((postJson) {
          try {
            return Post.fromJson(postJson);
          } catch (e) {
            print('Error parsing individual post JSON: $e');
            print('Post JSON causing error: $postJson');
            // Do not rethrow here, allow other posts to be parsed.
            // Consider logging this error and returning null or a default post,
            // or filter out invalid posts after mapping. For now, rethrow to highlight the issue.
            rethrow; // Re-throwing here will stop the entire list from being processed.
                     // If you want to skip malformed posts, catch and return null, then filter list.
          }
        }).toList();
        print('Successfully mapped to Posts. Count: ${posts.length}');
        return posts;
      } else if (response is Map<String, dynamic> && response.containsKey('error')) {
        throw Exception('API Error: ${response['error']}');
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

      if (response == null) {
        throw Exception('Null response from server for getPostById.');
      }

      if (response is Map<String, dynamic>) {
        // Consistent parsing: expect 'post' key for single post responses
        if (response.containsKey('post')) {
          return Post.fromJson(response['post']);
        } else if (response.containsKey('error')) {
          throw Exception('API Error: ${response['error']}');
        }
        // Fallback for direct post object if no 'post' key, but prefer consistency
        return Post.fromJson(response); 
      } else {
        throw Exception('Invalid response format or post not found for getPostById.');
      }
    } catch (e) {
      print('Error in getPostById: $e');
      rethrow;
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
    bool? clearExistingMedia, // This field should ideally be processed by backend logic.
  }) async {
    try {
      final fields = <String, String>{};

      if (title != null) fields['title'] = title;
      if (description != null) fields['description'] = description;
      if (isEvent != null) fields['isEvent'] = isEvent.toString();
      if (eventDateTime != null) fields['eventDateTime'] = eventDateTime.toIso8601String();
      if (location != null) fields['location'] = location;
      // Pass clearExistingMedia as a string 'true'/'false' if backend expects it as a field
      if (clearExistingMedia != null) fields['clearExistingMedia'] = clearExistingMedia.toString();

      List<http.MultipartFile> files = [];

      if (newMediaFile != null) {
        files.add(await http.MultipartFile.fromPath(
          'mediaUrls', // Backend field name for new media
          newMediaFile.path,
          contentType: _getMediaType(newMediaFile.path),
          filename: p.basename(newMediaFile.path),
        ));
      }

      final response = await _apiService.putMultipart(
        ApiConstants.updatePostEndpoint(postId),
        fields,
        files,
      );

      if (response == null) {
        throw Exception('Null response from server for updatePost.');
      }

      if (response.containsKey('post')) {
        return Post.fromJson(response['post']);
      } else if (response.containsKey('error')) {
        throw Exception('API Error: ${response['error']}');
      } else if (response.containsKey('message')) { // Handle generic message for errors too
        throw Exception('API Error: ${response['message']}');
      }
      // If the update response doesn't contain the updated post or an error,
      // it might indicate an issue, or the API expects a subsequent fetch.
      // Revert to fetching by ID as a robust fallback.
      print('Update response missing "post" key. Attempting to fetch updated post by ID for consistency.');
      return await getPostById(postId);
    } catch (e) {
      print('Error updating post: $e');
      rethrow;
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      // Assuming _apiService.delete handles response parsing and error throwing
      final response = await _apiService.delete(ApiConstants.deletePostEndpoint(postId));

      if (response != null && response.containsKey('error')) {
        throw Exception('API Error: ${response['error']}');
      }
      // You might want to check for a success message here if your API returns one,
      // e.g., if (response?['message'] != 'Post deleted successfully') throw ...
    } catch (e) {
      print('Error deleting post: $e');
      rethrow;
    }
  }

  Future<Post> togglePostInterest(String postId) async {
    try {
      final response = await _apiService.put(
        ApiConstants.togglePostInterestEndpoint(postId),
        {}, // Empty body, assuming the endpoint infers user from authentication token
      );

      if (response == null) {
        throw Exception('Null response from server for togglePostInterest.');
      }

      // Consistently expect 'post' key
      if (response.containsKey('post')) {
        return Post.fromJson(response['post']);
      } else if (response.containsKey('error')) {
        throw Exception('API Error: ${response['error']}');
      } else {
        throw Exception('Failed to toggle interest: Invalid response format or missing post data.');
      }
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
      } else if (response is Map<String, dynamic> && response.containsKey('error')) {
        throw Exception('API Error: ${response['error']}');
      } else {
        throw Exception('Failed to load interested posts: Invalid response format.');
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

      if (response == null) {
        throw Exception('Null response from server for togglePostAttendance.');
      }

      // Consistently expect 'post' key
      if (response.containsKey('post')) {
        return Post.fromJson(response['post']);
      } else if (response.containsKey('error')) {
        throw Exception('API Error: ${response['error']}');
      } else {
        throw Exception('Failed to toggle attendance: Invalid response format or missing post data.');
      }
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
      } else if (response is Map<String, dynamic> && response.containsKey('error')) {
        throw Exception('API Error: ${response['error']}');
      } else {
        throw Exception('Failed to load attended posts: Invalid response format.');
      }
    } catch (e) {
      print('Error fetching attended posts: $e');
      rethrow;
    }
  }
}