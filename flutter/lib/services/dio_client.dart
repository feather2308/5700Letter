import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'user_secure_storage.dart';

class DioClient {
  late Dio _dio;

  DioClient() {
    _dio = Dio(
      BaseOptions(
        // [수정] 기본값에도 /api를 붙여서 경로를 맞춰줍니다.
        baseUrl: dotenv.env['API_URL'] ?? '',
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 3),
        contentType: Headers.jsonContentType,
      ),
    );

    // [핵심] 요청 가로채기 (Interceptor)
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // 1. 저장된 토큰 가져오기
          final token = await UserSecureStorage.getToken();

          // [디버깅 로그] 토큰이 잘 나오는지 확인!
          print(">>> [Dio] 현재 저장된 토큰: $token");

          // 2. 토큰이 있으면 헤더에 추가
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            print(">>> [Dio] 헤더 추가 완료: Bearer ${token.substring(0, 10)}..."); // 앞 10자리만 확인
          } else {
            print(">>> [Dio] ⚠️ 경고: 토큰이 없습니다! (로그인 안 된 상태)");
          }

          return handler.next(options);
        },
        onError: (DioException e, handler) {
          print(">>> [Dio] API Error: ${e.message}, Status: ${e.response?.statusCode}");
          return handler.next(e);
        },
      ),
    );
  }

  Dio get dio => _dio;
}