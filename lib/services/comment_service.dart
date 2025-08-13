import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myapp/core/api_constants.dart';
import 'package:myapp/models/comment_model.dart';

class CommentService {
  
  Future<List<Comment>> getComments(String postId, String token) async {
  if (token.isEmpty) {
    throw Exception('Missing authentication token');
  }

  final url = Uri.parse('${ApiConstants.baseUrl}/posts/$postId/comments');

  try {
    final res = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      final List data = json.decode(res.body);
      return data.map((json) => Comment.fromJson(json)).toList();
    } else {
      String message = 'Failed to fetch comments';
      try {
        final error = json.decode(res.body);
        if (error['message'] != null) {
          message = error['message'];
        }
      } catch (_) {}
      throw Exception('$message (Status: ${res.statusCode})');
    }
  } catch (e) {
    print('Error in getComments: $e');
    rethrow;
  }
}




  Future<Comment> createComment(
    String postId,
    String content,
    String token,
  ) async {
    if (postId.isEmpty || content.isEmpty || token.isEmpty) {
      throw Exception('Invalid postId, content, or token');
    }

    final url = Uri.parse('${ApiConstants.baseUrl}/posts/$postId/comments');

    final res = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'content': content}),
    );


    if (res.statusCode != 201) {
      final error = json.decode(res.body);
      throw Exception(error['error'] ?? 'Failed to post comment');
    }

    return Comment.fromJson(json.decode(res.body));
  }
}
