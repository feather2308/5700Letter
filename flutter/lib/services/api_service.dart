// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/record.dart';

class ApiService {
  // [수정] .env에서 가져오기 (없으면 빈 문자열)
  static String get baseUrl => dotenv.env['API_URL'] ?? '';

  // 1. 일기 저장 & 조언 요청 (POST)
  Future<Map<String, dynamic>> saveRecord(String content, String emotion) async {
    final url = Uri.parse(baseUrl);
    
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "memberId": 1, // 테스트용 ID 고정
          "content": content,
          "emotion": emotion,
        }),
      );

      if (response.statusCode == 200) {
        // 백엔드에서 { "message": "...", "recordId": 1 } 형태로 준다고 가정
        return jsonDecode(utf8.decode(response.bodyBytes)); 
      } else {
        throw Exception("저장 실패: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("에러 발생: $e");
    }
  }

  // 2. 조언 조회 (GET)
  Future<Record> getRecord(int id) async {
    final url = Uri.parse("$baseUrl/$id");
    
    final response = await http.get(url);

    if (response.statusCode == 200) {
      // 한글 깨짐 방지를 위해 utf8.decode 사용
      return Record.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception("조회 실패");
    }
  }

  // [추가] 3. 내 기록 목록 조회 (GET /api/records/member/{id})
  Future<List<Record>> getMemberRecords(int memberId) async {
    final url = Uri.parse("$baseUrl/member/$memberId");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      // JSON 리스트를 Record 객체 리스트로 변환
      return body.map((dynamic item) => Record.fromJson(item)).toList();
    } else {
      throw Exception("목록 조회 실패");
    }
  }
  
  // [추가] 4. 기록 전체 삭제 (DELETE)
  Future<void> deleteAllRecords(int memberId) async {
    final url = Uri.parse("$baseUrl/member/$memberId");
    final response = await http.delete(url);

    if (response.statusCode != 200) {
      throw Exception("삭제 실패");
    }
  }
} // 클래스 끝