import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'user_secure_storage.dart';

class DioClient {
  late Dio _dio;

  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: dotenv.env['API_URL'] ?? 'http://10.0.2.2:8080', // .env 사용 권장
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
          // 에러 로깅 등을 여기서 처리 가능
          print("API Error: ${e.message}");
          return handler.next(e);
        },
      ),
    );
  }

  Dio get dio => _dio;
}