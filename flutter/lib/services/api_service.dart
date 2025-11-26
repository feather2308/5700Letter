import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/record.dart';
import 'dio_client.dart'; // [중요] 우리가 만든 DioClient 임포트

class ApiService {
  // [중요] 여기서 우리가 만든 DioClient의 dio 인스턴스를 가져와야 합니다!
  // 이 _dio 안에는 토큰을 자동으로 넣는 'Interceptor'가 들어있습니다.
  final _dio = DioClient().dio;

  static String get baseUrl => dotenv.env['API_URL'] ?? '';

  // 1. 저장
  Future<Map<String, dynamic>> saveRecord(String content, String emotion, String? fcmToken) async {
    try {
      // [중요] http.post가 아니라 _dio.post를 써야 토큰이 날아갑니다!
      final response = await _dio.post(
        "$baseUrl/records",
        data: {
          "content": content,
          "emotion": emotion,
          "fcmToken": fcmToken,
        },
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception("저장 실패: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("에러 발생: $e");
    }
  }

  // 2. 조회
  Future<Record> getRecord(int id) async {
    try {
      final response = await _dio.get("$baseUrl/records/$id");

      if (response.statusCode == 200) {
        return Record.fromJson(response.data);
      } else {
        throw Exception("조회 실패");
      }
    } catch (e) {
      throw Exception("조회 실패: $e");
    }
  }

  // 3. 목록 조회 (여기서 403 에러가 났었음)
  Future<List<Record>> getMemberRecords() async {
    try {
      // [중요] _dio.get을 써야 헤더에 'Authorization: Bearer ...'가 붙어서 갑니다.
      final response = await _dio.get("$baseUrl/records/member/me");

      if (response.statusCode == 200) {
        List<dynamic> body = response.data;
        return body.map((dynamic item) => Record.fromJson(item)).toList();
      } else {
        throw Exception("목록 조회 실패");
      }
    } catch (e) {
      // 로그 확인용 (403이면 토큰 문제)
      print("목록 조회 에러: $e");
      throw Exception("목록 조회 실패: $e");
    }
  }

  // 4. 삭제
  Future<void> deleteAllRecords() async {
    try {
      final response = await _dio.delete("$baseUrl/records/member/me");

      if (response.statusCode != 200) {
        throw Exception("삭제 실패");
      }
    } catch (e) {
      throw Exception("삭제 실패: $e");
    }
  }
}