import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 날짜 포맷용
import '../services/api_service.dart';
import '../models/record.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Record>> _recordsFuture;

  @override
  void initState() {
    super.initState();
    // 화면이 켜질 때 데이터 요청 (회원 ID 1번 고정)
    _recordsFuture = _apiService.getMemberRecords(1);
  }

  // 새로고침 기능 (화면을 아래로 당겼을 때)
  Future<void> _refreshRecords() async {
    setState(() {
      _recordsFuture = _apiService.getMemberRecords(1);
    });
  }

  // 상세 조언 보기 팝업
  void _showDetailDialog(Record record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(record.emotion.isNotEmpty ? "${record.emotion}의 날" : "기록된 날"),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("[나의 기록]", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                Text(record.content),
                const Divider(height: 30),
                const Text("[5700 Letter]", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                const SizedBox(height: 10),
                Text(
                  record.adviceContent ?? "조언 생성 중...",
                  style: const TextStyle(height: 1.5),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("닫기", style: TextStyle(color: Colors.brown)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("지난 기록들")),
      body: FutureBuilder<List<Record>>(
        future: _recordsFuture,
        builder: (context, snapshot) {
          // 1. 로딩 중
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // 2. 에러 발생
          if (snapshot.hasError) {
            return Center(child: Text("오류가 발생했습니다.\n${snapshot.error}"));
          }
          // 3. 데이터 없음
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("아직 작성된 기록이 없습니다."));
          }

          // 4. 데이터 있음 (리스트 출력)
          final records = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refreshRecords,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: records.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final record = records[index];
                // 날짜 포맷 (예: 2024.11.26) - intl 패키지가 없으면 record.date.toString() 사용
                // 여기서는 간단히 문자열 처리로 날짜만 자름
                String dateStr = record.id.toString(); // 임시 ID 표시 (실제 날짜 필드가 있다면 교체)
                
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    leading: CircleAvatar(
                      backgroundColor: Colors.amber[100],
                      child: const Icon(Icons.book, color: Colors.brown),
                    ),
                    title: Text(
                      record.emotion.isEmpty ? "무제" : record.emotion, // 감정이 제목
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      record.content,
                      maxLines: 1, // 한 줄만 미리보기
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    onTap: () => _showDetailDialog(record),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}