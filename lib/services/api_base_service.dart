import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myapp/core/api_constants.dart';
import 'package:myapp/utils/secure_storage.dart';

class ApiBaseService {
  /// Internal helper to construct HTTP headers.
  /// `includeAuth`: Whether to include the Authorization token.
  /// `isMultipart`: Whether the request is a multipart request (changes Content-Type handling).
  Future<Map<String, String>> _getHeaders({
    bool includeAuth = true,
    bool isMultipart = false, // True if a file upload is involved
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json', // Requesting JSON response
    };

    // Set Content-Type only for non-multipart requests that send JSON in the body
    if (!isMultipart) {
      headers['Content-Type'] = 'application/json';
    }

    // Add Authorization header if authentication is required
    if (includeAuth) {
      final token = await SecureStorage.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  /// Performs a GET request.
  Future<dynamic> get(String endpoint, {bool includeAuth = true}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final response = await http.get(
      uri,
      headers: await _getHeaders(includeAuth: includeAuth),
    );
    return _processResponse(response);
  }

  /// Performs a POST request with a JSON body.
  Future<dynamic> post(
    String endpoint,
    dynamic body, {
    bool includeAuth = true,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final response = await http.post(
      uri,
      headers: await _getHeaders(includeAuth: includeAuth),
      body: json.encode(body), // Encode body to JSON string
    );
    return _processResponse(response);
  }

  /// Performs a POST request with multipart/form-data (for file uploads).
  Future<dynamic> postMultipart(
    String endpoint,
    Map<String, String> fields,
    List<http.MultipartFile> files, {
    bool includeAuth = true,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final request = http.MultipartRequest('POST', uri);

    // Add headers, explicitly setting isMultipart to true
    request.headers.addAll(await _getHeaders(
      includeAuth: includeAuth,
      isMultipart: true,
    ));

    request.fields.addAll(fields); // Add text fields
    request.files.addAll(files);   // Add files

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    print('Raw POST Multipart Response Body: ${response.body}');
    return _processResponse(response);
  }

  /// Performs a PUT request with a JSON body.
  Future<dynamic> put(
    String endpoint,
    dynamic body, {
    bool includeAuth = true,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final response = await http.put(
      uri,
      headers: await _getHeaders(includeAuth: includeAuth),
      body: json.encode(body), // Encode body to JSON string
    );
    return _processResponse(response);
  }

  /// Performs a PUT request with multipart/form-data (for file uploads in updates).
  Future<dynamic> putMultipart(
    String endpoint,
    Map<String, String> fields,
    List<http.MultipartFile> files, {
    bool includeAuth = true,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final request = http.MultipartRequest('PUT', uri);

    // Add headers, explicitly setting isMultipart to true
    request.headers.addAll(await _getHeaders(
      includeAuth: includeAuth,
      isMultipart: true,
    ));

    request.fields.addAll(fields); // Add text fields
    request.files.addAll(files);   // Add files

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    print('Raw PUT Multipart Response Body: ${response.body}');
    return _processResponse(response);
  }

  /// Performs a DELETE request.
  Future<dynamic> delete(String endpoint, {bool includeAuth = true}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final response = await http.delete(
      uri,
      headers: await _getHeaders(includeAuth: includeAuth),
    );
    print('Raw DELETE Response Body: ${response.body}');
    return _processResponse(response);
  }

  /// Processes the HTTP response, handles status codes, and decodes JSON.
  /// Throws an [Exception] for non-2xx status codes.
  dynamic _processResponse(http.Response response) {
    print('API Response Status Code: ${response.statusCode}');
    print('API Response Headers: ${response.headers}');
    print('API Response Body: ${response.body}'); // Keep a single clear log for body

    // Check for successful status codes
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // If the body is empty, return an empty Map or null, depending on preference.
      // Returning an empty Map is often safer if the caller expects a Map.
      if (response.body.isEmpty) {
        return {};
      }

      // Attempt to decode JSON if Content-Type suggests it
      final contentType = response.headers['content-type'] ?? '';
      if (contentType.contains('application/json')) {
        try {
          return json.decode(response.body);
        } catch (e) {
          // If JSON decoding fails, even if Content-Type is JSON, it's an error.
          print('JSON decode error for successful response: $e');
          throw Exception('Failed to parse JSON response: ${response.body}');
        }
      } else {
        // If not JSON, but success, return the raw body or handle as needed
        print('Non-JSON successful response received. Returning raw body.');
        return response.body; // Or throw if non-JSON success is unexpected
      }
    } else {
      // Handle error status codes (e.g., 4xx, 5xx)
      String errorMessage = 'API Error: ${response.statusCode} - ${response.reasonPhrase ?? 'Unknown Error'}';
      
      // Attempt to parse error message from JSON body if available
      try {
        if (response.body.isNotEmpty && response.headers['content-type']?.contains('application/json') == true) {
          final errorBody = json.decode(response.body);
          if (errorBody is Map && errorBody.containsKey('message')) {
            errorMessage = errorBody['message'].toString();
          } else if (errorBody is String) {
            errorMessage = errorBody; // Sometimes simple error strings are returned
          }
        }
      } catch (e) {
        print('Error parsing error response body: $e');
        // Fallback to default message if parsing fails
      }
      throw Exception(errorMessage);
    }
  }
}