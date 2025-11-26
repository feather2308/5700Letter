import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/record.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

// [핵심] WidgetsBindingObserver 추가 (앱 상태 감지용)
class _HistoryScreenState extends State<HistoryScreen> with WidgetsBindingObserver {
  final ApiService _apiService = ApiService();
  late Future<List<Record>> _recordsFuture;
  StreamSubscription? _refreshSubscription;

  @override
  void initState() {
    super.initState();
    // 1. 앱 상태 감지기 등록
    WidgetsBinding.instance.addObserver(this);

    // 2. 초기 데이터 로드
    _recordsFuture = _apiService.getMemberRecords();

    // 3. (앱 켜져있을 때) 알림 오면 실시간 새로고침
    _refreshSubscription = NotificationService().onRefreshNeeded.listen((_) {
      print(">>> 알림 도착(Foreground)! 히스토리 자동 갱신");
      _refreshRecords();
    });
  }

  @override
  void dispose() {
    // 감지기 해제
    WidgetsBinding.instance.removeObserver(this);
    _refreshSubscription?.cancel();
    super.dispose();
  }

  // [핵심] 앱 상태가 바뀔 때 실행되는 함수
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 사용자가 알림을 누르거나, 앱 아이콘을 눌러서 '다시 돌아왔을 때(resumed)'
    if (state == AppLifecycleState.resumed) {
      print(">>> 앱으로 복귀(Resumed)! 히스토리 최신화");
      _refreshRecords();
    }
  }

  Future<void> _refreshRecords() async {
    setState(() {
      _recordsFuture = _apiService.getMemberRecords();
    });
  }

  String _formatDate(String dateString) {
    try {
      DateTime date = DateTime.parse(dateString);
      return DateFormat('yy.MM.dd HH:mm').format(date);
    } catch (e) {
      return "-";
    }
  }

  // ... (showDetailDialog 및 UI 코드는 기존과 동일하므로 생략하지 않고 전체 제공)
  void _showDetailDialog(Record record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(record.emotion.isNotEmpty ? "${record.emotion}의 날" : "분석 중"),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                  record.adviceContent ?? "AI가 열심히 편지를 쓰고 있습니다...",
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
        automaticallyImplyLeading: false,
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

                // 조언 생성 여부 확인 (null이면 생성 중)
                bool isPending = record.adviceContent == null;

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    leading: CircleAvatar(
                      backgroundColor: isPending ? Colors.grey[200] : Colors.amber[100],
                      child: Icon(
                          isPending ? Icons.hourglass_top : Icons.book,
                          color: isPending ? Colors.grey : Colors.brown
                      ),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          // 감정도 아직 없으면(빈문자열) '분석 중' 표시
                          record.emotion.isEmpty ? "분석 중..." : record.emotion,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isPending ? Colors.grey : Colors.black
                          ),
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
                        isPending ? "AI가 감정을 분석하고 편지를 씁니다..." : record.content,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isPending ? Colors.amber : Colors.black54,
                          fontStyle: isPending ? FontStyle.italic : FontStyle.normal,
                        ),
                      ),
                    ),
                    trailing: isPending
                        ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber)
                    )
                        : const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),

                    onTap: isPending ? null : () => _showDetailDialog(record),
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