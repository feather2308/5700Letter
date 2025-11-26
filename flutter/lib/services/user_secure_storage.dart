import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserSecureStorage {
  static const _storage = FlutterSecureStorage();
  static const _keyAccessToken = 'accessToken';

  // 토큰 저장
  static Future<void> setToken(String token) async {
    await _storage.write(key: _keyAccessToken, value: token);
  }

  // 토큰 조회
  static Future<String?> getToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  // 토큰 삭제 (로그아웃 시)
  static Future<void> deleteToken() async {
    await _storage.delete(key: _keyAccessToken);
  }
}