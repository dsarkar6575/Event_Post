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
        'mediaUrls', // ✅ MATCHES backend field for upload.array('mediaUrls')
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

    // --- Improved Error Handling ---
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
    // --- End Improved Error Handling ---


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

    print('Response received in getAllPosts: $response'); // Log the raw response

    // Check if the response is a List as expected
    if (response is List) {
      print('Response is a List. Mapping to Posts...');
      final List<Post> posts = response.map((postJson) {
        print('Processing post JSON: $postJson'); // Log each post JSON object
        try {
          return Post.fromJson(postJson);
        } catch (e) {
          print('Error parsing post JSON: $e'); // Log errors during parsing
          print('Post JSON causing error: $postJson');
          rethrow; // Re-throw parsing errors
        }
      }).toList();
      print('Successfully mapped to Posts. Count: ${posts.length}');
      return posts;
    } else {
      // Handle unexpected response format
      print('Unexpected response format in getAllPosts: $response');
      throw Exception('Failed to load posts due to unexpected response format.');
    }
  } catch (e) {
    // Re-throw the caught exception to be handled by the PostProvider
    print('Error fetching or processing posts: $e');
    rethrow;
  }
}



Future<Post> getPostById(String postId) async {
  try {
    final response = await _apiService.get(ApiConstants.getPostByIdEndpoint(postId));
    print('API Response for getPostById($postId): $response');

    if (response != null && response is Map<String, dynamic>) {
      return Post.fromJson(response);
    } else {
      throw Exception('Invalid response format');
    }
  } catch (e) {
    print('Error in getPostById: $e');
    throw Exception('Post not found or invalid response');
  }
}




  Future<Post> updatePost(String postId, {
    String? title,
    String? description,
    List<String>? mediaUrls,
    bool? isEvent,
    DateTime? eventDateTime,
    String? location,
    File? newMediaFile,
  }) async {
    final fields = <String, String>{};
    if (title != null) fields['title'] = title;
    if (description != null) fields['description'] = description;
    if (mediaUrls != null) fields['mediaUrls'] = mediaUrls.join(','); // Assuming backend can parse comma-separated
    if (isEvent != null) fields['isEvent'] = isEvent.toString();
    if (isEvent == true && eventDateTime != null) {
      fields['eventDateTime'] = eventDateTime.toIso8601String();
    }
    if (location != null) fields['location'] = location;

    List<http.MultipartFile> files = [];
    if (newMediaFile != null) {
      final mimeTypeData = lookupMimeType(newMediaFile.path)?.split('/');
      files.add(await http.MultipartFile.fromPath(
        'media', // This should match the field name on your backend for media uploads
        newMediaFile.path,
        contentType: mimeTypeData != null ? MediaType(mimeTypeData[0], mimeTypeData[1]) : null,
        filename: p.basename(newMediaFile.path),
      ));
    }

    final response = await _apiService.putMultipart(
      ApiConstants.updatePostEndpoint(postId),
      fields,
      files,
    );
    return Post.fromJson(response['post']);
  }

  Future<void> deletePost(String postId) async {
    await _apiService.delete(ApiConstants.deletePostEndpoint(postId));
  }

  Future<Post> togglePostInterest(String postId) async {
    final response = await _apiService.put(
      ApiConstants.togglePostInterestEndpoint(postId),
      {}, // Empty body as per API description
    );
    return Post.fromJson(response['post']);
  }

  Future<List<Post>> getInterestedPosts() async {
    final response = await _apiService.get(ApiConstants.getInterestedPostsEndpoint);
    return (response as List).map((post) => Post.fromJson(post)).toList();
  }
}