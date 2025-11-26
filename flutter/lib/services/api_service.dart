import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/record.dart';
import 'dio_client.dart';

class ApiService {
  final _dio = DioClient().dio;

  // .env에서 가져옴 (예: http://10.0.2.2:8080/api)
  static String get baseUrl => dotenv.env['API_URL'] ?? '';

  // 1. 일기 저장 (POST /records)
  // 토큰이 있으므로 memberId 불필요
  Future<Map<String, dynamic>> saveRecord(String content, String emotion, String? fcmToken) async {
    try {
      final response = await _dio.post(
        "$baseUrl/records", // 경로: /api/records
        data: {
          "content": content,
          "emotion": emotion, // (서버에서 무시하거나 초기값으로 쓰임)
          "fcmToken": fcmToken,
        },
      );

      if (response.statusCode == 200) {
        return response.data; // {"message": "...", "recordId": ...}
      } else {
        throw Exception("저장 실패: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("에러 발생: $e");
    }
  }

  // 2. 상세 조회 (GET /records/{id})
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

  // 3. 내 기록 목록 조회 (GET /records/member/me)
  // memberId 파라미터 제거 -> 토큰으로 식별
  Future<List<Record>> getMemberRecords() async {
    try {
      final response = await _dio.get("$baseUrl/records/member/me");

      if (response.statusCode == 200) {
        List<dynamic> body = response.data;
        return body.map((dynamic item) => Record.fromJson(item)).toList();
      } else {
        throw Exception("목록 조회 실패");
      }
    } catch (e) {
      throw Exception("목록 조회 실패: $e");
    }
  }

  // 4. 기록 전체 삭제 (DELETE /records/member/me)
  // memberId 파라미터 제거 -> 토큰으로 식별
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