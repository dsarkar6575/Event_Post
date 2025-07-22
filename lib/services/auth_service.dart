import 'package:myapp/core/api_constants.dart';
import 'package:myapp/models/auth_response_model.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/services/api_base_service.dart';

class AuthService {
  final ApiBaseService _apiService = ApiBaseService();

  Future<AuthResponse> registerUser(String email, String username, String password) async {
    final response = await _apiService.post(
      ApiConstants.registerEndpoint,
      {'email': email, 'username': username, 'password': password},
      includeAuth: false,
    );
    return AuthResponse.fromJson(response);
  }

  Future<AuthResponse> loginUser(String email, String password) async {
    final response = await _apiService.post(
      ApiConstants.loginEndpoint,
      {'email': email, 'password': password},
      includeAuth: false,
    );
    return AuthResponse.fromJson(response);
  }

  Future<User> getAuthUser() async {
    final response = await _apiService.get(ApiConstants.getAuthUserEndpoint);
    return User.fromJson(response['user']);
  }
}