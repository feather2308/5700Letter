import 'package:flutter/material.dart';

import '../services/user_secure_storage.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _token;

  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;

  // 앱 시작 시 자동 로그인 체크
  Future<void> checkLoginStatus() async {
    final savedToken = await UserSecureStorage.getToken();
    if (savedToken != null) {
      _token = savedToken;
      _isAuthenticated = true;
    } else {
      _isAuthenticated = false;
    }
    notifyListeners(); // 화면 갱신 알림
  }

  // 로그인 성공 시 호출
  Future<void> login(String newToken) async {
    await UserSecureStorage.setToken(newToken); // 저장소에 저장
    _token = newToken;
    _isAuthenticated = true;
    notifyListeners();
  }

  // 로그아웃
  Future<void> logout() async {
    await UserSecureStorage.deleteToken(); // 저장소에서 삭제
    _token = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}