import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/record.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // import 추가

class WriteScreen extends StatefulWidget {
  const WriteScreen({super.key});

  @override
  State<WriteScreen> createState() => _WriteScreenState();
}

class _WriteScreenState extends State<WriteScreen> {
  final TextEditingController _textController = TextEditingController();
  final ApiService _apiService = ApiService();
  
  bool _isLoading = false;

  void _submitRecord() async {
    if (_textController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("오늘 하루를 기록해주세요.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. 내 폰의 우편번호(FCM Token) 가져오기
      String? token = await FirebaseMessaging.instance.getToken();
      print("내 폰 토큰: $token");

      // 2. 글 + 토큰 같이 전송
      await _apiService.saveRecord(_textController.text, "", token!);
      
      if (!mounted) return;

      setState(() => _isLoading = false);

      // 2. [수정] 팝업 띄우지 않고 바로 안내 메시지 후 홈으로 이동
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("기록 완료! AI가 편지를 쓰고 있습니다.\n잠시 후 홈에서 확인해주세요."),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.brown,
        ),
      );

      // 3. 홈으로 복귀
      Navigator.pop(context); 

    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("오류 발생: $e")),
      );
    }
  }

  // [누락되었던 함수 복구] 조언 결과를 팝업으로 띄우는 함수
  void _showAdviceDialog(int recordId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return FutureBuilder<Record>(
          future: _apiService.getRecord(recordId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text("AI가 5,700자 편지를 쓰고 있습니다...\n(잠시만 기다려주세요)", textAlign: TextAlign.center),
                  ],
                ),
              );
            }

            if (snapshot.hasError) {
              return AlertDialog(
                title: const Text("오류"),
                content: Text("조언을 불러오지 못했습니다.\n${snapshot.error}"),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text("확인")),
                ],
              );
            }

            final record = snapshot.data!;
            return AlertDialog(
              title: const Text("5700 Letter 도착"),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Text(
                    record.adviceContent ?? "조언이 생성되지 않았습니다.",
                    style: const TextStyle(height: 1.6),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context), 
                  child: const Text("닫기", style: TextStyle(color: Colors.brown)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: const Text("기록 남기기"), // 예: "기록 작성", "히스토리", "설정"
  centerTitle: true,
  automaticallyImplyLeading: false, // [중요] 좌상단 기본 화살표 제거
  actions: [
    IconButton(
      icon: const Icon(Icons.close, size: 28), // 톱니바퀴 위치에 '닫기' 아이콘 배치
      onPressed: () => Navigator.pop(context), // 누르면 홈으로 내려감
    ),
    const SizedBox(width: 10),
  ],
),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("솔직한 이야기를 들려주세요", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            
            Expanded(
              child: TextField(
                controller: _textController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: "오늘 있었던 일, 고민, 감정 등을 자유롭게 적어주세요.\nAI가 당신의 마음을 읽고 5,700자 편지를 답장합니다.",
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitRecord,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text("기록하기 & 조언 받기", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}