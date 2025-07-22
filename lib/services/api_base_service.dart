import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myapp/core/api_constants.dart';
import 'package:myapp/utils/secure_storage.dart';

class ApiBaseService {
  //  static const String _baseUrl = 'https://event-backend-5dbb.onrender.com/api'; // Adjust as needed

  Future<Map<String, String>> _getHeaders({bool includeAuth = true, bool isMultipart = false}) async {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (includeAuth) {
      final token = await SecureStorage.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    if (isMultipart) {
      headers.remove('Content-Type'); // Let http package handle Content-Type for multipart
    }
    return headers;
  }

  Future<dynamic> get(String endpoint, {bool includeAuth = true}) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}$endpoint'),
      headers: await _getHeaders(includeAuth: includeAuth),
    );
    return _processResponse(response);
  }

  Future<dynamic> post(String endpoint, dynamic body, {bool includeAuth = true}) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}$endpoint'),
      headers: await _getHeaders(includeAuth: includeAuth),
      body: json.encode(body),
    );
    return _processResponse(response);
  }

  Future<dynamic> postMultipart(String endpoint, Map<String, String> fields, List<http.MultipartFile> files, {bool includeAuth = true}) async {
    final request = http.MultipartRequest('POST', Uri.parse('${ApiConstants.baseUrl}$endpoint'));
    request.headers.addAll(await _getHeaders(includeAuth: includeAuth, isMultipart: true));
    request.fields.addAll(fields);
    request.files.addAll(files);

    final response = await http.Response.fromStream(await request.send());
    // Add logging for the raw response body
    print('Raw POST Multipart Response Body: ${response.body}');
    return _processResponse(response);
  }

  Future<dynamic> put(String endpoint, dynamic body, {bool includeAuth = true}) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}$endpoint'),
      headers: await _getHeaders(includeAuth: includeAuth),
      body: json.encode(body),
    );
    return _processResponse(response);
  }

  Future<dynamic> putMultipart(String endpoint, Map<String, String> fields, List<http.MultipartFile> files, {bool includeAuth = true}) async {
    final request = http.MultipartRequest('PUT', Uri.parse('${ApiConstants.baseUrl}$endpoint'));
    request.headers.addAll(await _getHeaders(includeAuth: includeAuth, isMultipart: true));
    request.fields.addAll(fields);
    request.files.addAll(files);

    final response = await http.Response.fromStream(await request.send());
     // Add logging for the raw response body
    print('Raw PUT Multipart Response Body: ${response.body}');
    return _processResponse(response);
  }

  Future<dynamic> delete(String endpoint, {bool includeAuth = true}) async {
    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}$endpoint'),
      headers: await _getHeaders(includeAuth: includeAuth),
    );
     // Add logging for the raw response body
    print('Raw DELETE Response Body: ${response.body}');
    return _processResponse(response);
  }

  dynamic _processResponse(http.Response response) {
    // Add logging for status code and headers
    print('API Response Status Code: ${response.statusCode}');
    print('API Response Headers: ${response.headers}');
    print('A123PI Response Body: ${response.body}');
    // Add logging for the raw response body for non-multipart requests
    if (!response.headers['content-type']!.contains('multipart')) {
       print('Raw Response Body: ${response.body}');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        return json.decode(response.body);
      }
      return {}; // For 204 No Content
    } else {
      throw Exception('API Error: ${response.statusCode} - ${response.body}');
    }
  }
}