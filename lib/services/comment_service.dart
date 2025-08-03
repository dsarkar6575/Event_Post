import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myapp/core/api_constants.dart';
import 'package:myapp/models/comment_model.dart';

class CommentService {
  Future<List<Comment>> getComments(String postId) async {
  final url = Uri.parse('${ApiConstants.baseUrl}/posts/$postId/comments');


  final res = await http.get(url);

  if (res.statusCode != 200) {
    throw Exception('Failed to fetch comments');
  }

  final List data = json.decode(res.body);
  return data.map((json) => Comment.fromJson(json)).toList();
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
