import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/record.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  late Future<Record?> _todayRecordFuture;

  @override
  void initState() {
    super.initState();
    _todayRecordFuture = _fetchTodayRecord();
  }

  // 오늘 날짜의 기록 찾기
  // lib/screens/home_screen.dart

  Future<Record?> _fetchTodayRecord() async {
    try {
      List<Record> records = await _apiService.getMemberRecords(1);
      
      // [수정] 날짜 비교 로직 제거! 
      // 그냥 목록이 있으면 무조건 가장 최신 것(첫 번째)을 가져옵니다.
      if (records.isNotEmpty) {
        return records.first; 
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // 새로고침
  Future<void> _refresh() async {
    setState(() {
      _todayRecordFuture = _fetchTodayRecord();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9C4), // 연한 노랑 배경 (계획서 테마)
      appBar: AppBar(
        title: const Text("OPEN"),
        centerTitle: true,
      ),
      body: FutureBuilder<Record?>(
        future: _todayRecordFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final todayRecord = snapshot.data;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(), // 내용 짧아도 스크롤 가능하게 (새로고침용)
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.8, // 화면 꽉 차게
                child: Center(
                  child: todayRecord == null
                      ? _buildEmptyView() // 1. 기록 없을 때
                      : _buildTodayView(todayRecord), // 2. 기록 있을 때
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // 화면 1: 기록이 없을 때 (작성 유도)
  Widget _buildEmptyView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.edit_note, size: 80, color: Colors.brown.withOpacity(0.5)),
        const SizedBox(height: 20),
        const Text(
          "아직 오늘의 기록이 없어요.",
          style: TextStyle(fontSize: 20, color: Colors.brown),
        ),
        const SizedBox(height: 10),
        const Text(
          "당신의 하루를 들려주세요.\n5,700자 조언이 기다리고 있습니다.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: () {
             // 탭 이동은 MainScreen에서 제어해야 하지만, 
             // 간단히 텍스트로 안내하거나 여기서 SnackBar 띄움
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text("'RECORD' 탭에서 글을 써보세요!")),
             );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.brown,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
          ),
          child: const Text("기록하러 가기"),
        ),
      ],
    );
  }

  // 화면 2: 오늘 기록이 있을 때 (키워드 보여주기)
  Widget _buildTodayView(Record record) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "오늘의 키워드",
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
        const SizedBox(height: 20),
        
        // 감정 키워드 (계획서의 큰 글씨)
        Text(
          "\"${record.emotion}\"",
          style: const TextStyle(
            fontSize: 48, 
            fontWeight: FontWeight.bold, 
            color: Colors.brown,
            fontFamily: 'Serif', // 명조체 느낌 (있으면 적용됨)
          ),
        ),
        
        const SizedBox(height: 40),
        
        // 카드 형태의 요약
        Container(
          width: 300,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.brown.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                record.date,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 10),
              Text(
                record.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(height: 1.5),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              const Text(
                "AI의 조언이 도착했습니다",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
              ),
            ],
          ),
        ),
      ],
    );
  }
}