import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'jwt_token';
  static const _userIdKey = 'user_id';

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  static Future<void> saveUserId(String userId) async {
    await _storage.write(key: _userIdKey, value: userId);
  }

  static Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  static Future<void> deleteUserId() async {
    await _storage.delete(key: _userIdKey);
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}