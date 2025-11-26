import '../models/record.dart';
import 'dio_client.dart';

class ApiService {
  // DioClient에 이미 baseUrl(http://10.0.2.2:8080/api)이 설정되어 있습니다.
  final _dio = DioClient().dio;

  // 1. 저장 (POST /api/records)
  Future<Map<String, dynamic>> saveRecord(String content, String emotion, String? fcmToken) async {
    try {
      // [수정] 앞에 baseUrl 변수 제거! 그냥 경로만 적으세요.
      final response = await _dio.post(
        "/records",
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

  // 2. 상세 조회 (GET /api/records/{id})
  Future<Record> getRecord(int id) async {
    try {
      final response = await _dio.get("/records/$id"); // [수정] 상대 경로

      if (response.statusCode == 200) {
        return Record.fromJson(response.data);
      } else {
        throw Exception("조회 실패");
      }
    } catch (e) {
      throw Exception("조회 실패: $e");
    }
  }

  // 3. 목록 조회 (GET /api/records/member/me)
  Future<List<Record>> getMemberRecords() async {
    try {
      final response = await _dio.get("/records/member/me"); // [수정] 상대 경로

      if (response.statusCode == 200) {
        List<dynamic> body = response.data;
        return body.map((dynamic item) => Record.fromJson(item)).toList();
      } else {
        throw Exception("목록 조회 실패");
      }
    } catch (e) {
      print("목록 조회 에러: $e");
      throw Exception("목록 조회 실패: $e");
    }
  }

  // 4. 삭제 (DELETE /api/records/member/me)
  Future<void> deleteAllRecords() async {
    try {
      final response = await _dio.delete("/records/member/me"); // [수정] 상대 경로

      if (response.statusCode != 200) {
        throw Exception("삭제 실패");
      }
    } catch (e) {
      throw Exception("삭제 실패: $e");
    }
  }
}