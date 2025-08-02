import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myapp/core/api_constants.dart';
import 'package:myapp/models/post_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ChatService {
  final _storage = const FlutterSecureStorage();
  final _baseUrl = ApiConstants.baseUrl;

  Future<String?> _getToken() async {
    return await _storage.read(key: 'authToken');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<List<Post>> getJoinedChats() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/chat/joined'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => Post.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load chats');
    }
  }

  Future<List<Map<String, dynamic>>> getMessages(String postId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/chat/$postId/messages'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to load messages');
    }
  }

  Future<void> sendMessage(String postId, String message) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/chat/$postId/messages'),
      headers: await _getHeaders(),
      body: json.encode({'text': message}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send message');
    }
  }
}
