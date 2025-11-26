// lib/services/api_service.dart

import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/record.dart';
import 'dio_client.dart';

class ApiService {
  final _dio = DioClient().dio;

  // [수정] .env에서 가져오기 (없으면 빈 문자열)
  static String get baseUrl => dotenv.env['API_URL'] ?? '';

  // 1. 일기 저장 & 조언 요청 (POST)
  // 토큰으로 memberId 자동 식별
  Future<Map<String, dynamic>> saveRecord(String content, String emotion, String fcmToken) async {
    try {
      final response = await _dio.post(
        baseUrl,
        data: {
          "content": content,
          "emotion": emotion,
          "fcmToken": fcmToken,
        },
      );

      if (response.statusCode == 200) {
        // 백엔드에서 { "message": "...", "recordId": 1 } 형태로 준다고 가정
        return response.data;
      } else {
        throw Exception("저장 실패: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("에러 발생: $e");
    }
  }

  // 2. 조회 조회 (GET)
  // 토큰으로 권한 확인
  Future<Record> getRecord(int id) async {
    try {
      final response = await _dio.get("$baseUrl/$id");

      if (response.statusCode == 200) {
        return Record.fromJson(response.data);
      } else {
        throw Exception("조회 실패");
      }
    } catch (e) {
      throw Exception("조회 실패: $e");
    }
  }

  // 3. 내 기록 목록 조회 (GET /api/records/member/me)
  // 토큰으로 memberId 자동 식별
  Future<List<Record>> getMemberRecords() async {
    try {
      final response = await _dio.get("$baseUrl/member/me");

      if (response.statusCode == 200) {
        List<dynamic> body = response.data;
        // JSON 리스트를 Record 객체 리스트로 변환
        return body.map((dynamic item) => Record.fromJson(item)).toList();
      } else {
        throw Exception("목록 조회 실패");
      }
    } catch (e) {
      throw Exception("목록 조회 실패: $e");
    }
  }

  // 4. 기록 전체 삭제 (DELETE)
  // 토큰으로 memberId 자동 식별
  Future<void> deleteAllRecords() async {
    try {
      final response = await _dio.delete("$baseUrl/member/me");

      if (response.statusCode != 200) {
        throw Exception("삭제 실패");
      }
    } catch (e) {
      throw Exception("삭제 실패: $e");
    }
  }
}