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

          // 2. 토큰이 있으면 헤더에 추가
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          return handler.next(options); // 요청 계속 진행
        },
        onError: (DioException e, handler) {
          // 에러 로깅
          print("API Error: ${e.message}");
          return handler.next(e);
        },
      ),
    );
  }

  Dio get dio => _dio;
}