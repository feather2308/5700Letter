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

  String _formatDate(String dateString) {
    try {
      DateTime date = DateTime.parse(dateString);
      return DateFormat('yyyy-MM-dd HH:mm').format(date);
    } catch (e) {
      return "-";
    }
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
                // 팝업 안에도 날짜 상세 표시
                Text(
                  _formatDate(record.date),
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 10),
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
      appBar: AppBar(
        title: const Text("지난 기록들"),
        centerTitle: true,
        automaticallyImplyLeading: false, // 기본 뒤로가기 제거
        actions: [
          IconButton(
            icon: const Icon(Icons.close, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: FutureBuilder<List<Record>>(
        future: _recordsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("오류가 발생했습니다.\n${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("아직 작성된 기록이 없습니다."));
          }

          final records = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refreshRecords,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: records.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final record = records[index];

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    leading: CircleAvatar(
                      backgroundColor: Colors.amber[100],
                      child: const Icon(Icons.book, color: Colors.brown),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          record.emotion.isEmpty ? "무제" : record.emotion,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          _formatDate(record.date),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        record.content,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ),
                    // [복구] 화살표 아이콘 다시 추가
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),

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