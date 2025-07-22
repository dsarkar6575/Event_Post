import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:myapp/core/api_constants.dart';
import 'package:myapp/models/post_model.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/services/api_base_service.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

class UserService {
  final ApiBaseService _apiService = ApiBaseService();

  Future<User> getUserProfile(String userId) async {
    final response = await _apiService.get(ApiConstants.getUserProfileEndpoint(userId));
    return User.fromJson(response['user']);
  }

  Future<User> updateUserProfile(String userId, {
    String? username,
    String? bio,
    File? profileImage,
  }) async {
    final fields = <String, String>{};
    if (username != null) fields['username'] = username;
    if (bio != null) fields['bio'] = bio;

    List<http.MultipartFile> files = [];
    if (profileImage != null) {
      final mimeTypeData = lookupMimeType(profileImage.path)?.split('/');
      files.add(await http.MultipartFile.fromPath(
        'profileImage', // This should match the field name on your backend for profile image
        profileImage.path,
        contentType: mimeTypeData != null ? MediaType(mimeTypeData[0], mimeTypeData[1]) : null,
        filename: p.basename(profileImage.path),
      ));
    }

    final response = await _apiService.putMultipart(
      ApiConstants.updateUserProfileEndpoint(userId),
      fields,
      files,
    );
    return User.fromJson(response['user']);
  }

  Future<List<Post>> getUserPosts(String userId) async {
    final response = await _apiService.get(ApiConstants.getUserPostsEndpoint(userId));
    return (response['posts'] as List).map((post) => Post.fromJson(post)).toList();
  }

  Future<void> followUser(String userId) async {
    await _apiService.post(ApiConstants.followUserEndpoint(userId), {});
  }

  Future<void> unfollowUser(String userId) async {
    await _apiService.post(ApiConstants.unfollowUserEndpoint(userId), {});
  }
}