import 'package:flutter/material.dart';
import 'dart:math'; // 노이즈 생성을 위해 필요
import '../services/api_service.dart';
import '../models/record.dart';
import 'write_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

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

  Future<Record?> _fetchTodayRecord() async {
    try {
      List<Record> records = await _apiService.getMemberRecords(1);
      if (records.isNotEmpty) return records.first;
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _todayRecordFuture = _fetchTodayRecord();
    });
  }

  void _navigateTo(Widget page) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
      ),
    ).then((_) => _refresh());
  }

  // [핵심] 감정에 따른 그라데이션 반환 함수
  LinearGradient _getGradient(String emotion) {
    Color topColor;
    Color bottomColor;

    switch (emotion) {
      // [사용자 지정]
      case "기쁨":
        topColor = const Color(0xFFFFEAA7);
        bottomColor = const Color(0xFFFFD58A);
        break;
      case "슬픔":
        topColor = const Color(0xFFA8C0FF);
        bottomColor = const Color(0xFF8FA9F0);
        break;
      case "불안":
        topColor = const Color(0xFFF8C8DC);
        bottomColor = const Color(0xFFEBAEC7);
        break;
      case "분노":
        topColor = const Color(0xFFFFB4A2);
        bottomColor = const Color(0xFFF29A88);
        break;
      case "평온":
        topColor = const Color(0xFFC8E6C9);
        bottomColor = const Color(0xFFAFCFB1);
        break;
      
      // [AI 추천]
      case "우울":
        topColor = const Color(0xFFE0EAFC);
        bottomColor = const Color(0xFFCFDEF3);
        break;
      case "기대":
        topColor = const Color(0xFFE0F7FA);
        bottomColor = const Color(0xFF80DEEA);
        break;
      case "후회":
        topColor = const Color(0xFFF3E5F5);
        bottomColor = const Color(0xFFCE93D8);
        break;
      case "벅참":
        topColor = const Color(0xFFFFF3E0);
        bottomColor = const Color(0xFFFFB74D);
        break;
      case "피로":
        topColor = const Color(0xFFF5F5F5);
        bottomColor = const Color(0xFFBDBDBD);
        break;

      // 기본값 (기록 없음 등)
      default: 
        topColor = const Color(0xFFFFF9C4); // 연한 노랑 (기본)
        bottomColor = const Color(0xFFFFF176);
    }

    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [topColor, bottomColor],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Record?>(
      future: _todayRecordFuture,
      builder: (context, snapshot) {
        final record = snapshot.data;
        // 감정 키워드 가져오기 (없으면 기본값)
        final emotion = record?.emotion ?? "default";

        return Scaffold(
          // 배경색을 투명하게 해서 Container의 그라데이션이 보이게 함
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true, // 앱바 뒤까지 배경 확장
          appBar: AppBar(
            title: const Text(
              "5700 LETTER",
              style: TextStyle(
                fontFamily: 'Serif',
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent, // 앱바 투명
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings, size: 28),
                onPressed: () => _navigateTo(const SettingsScreen()),
              ),
              const SizedBox(width: 10),
            ],
          ),
          body: Container(
            // [1. 배경 그라데이션 적용]
            decoration: BoxDecoration(
              gradient: _getGradient(emotion),
            ),
            child: Stack(
              children: [
                // [2. 노이즈 효과 (5% 불투명도)]
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.05, // 5% 불투명도
                    child: CustomPaint(
                      painter: NoisePainter(),
                      size: Size.infinite,
                    ),
                  ),
                ),

                // [3. 메인 컨텐츠]
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 80),
                    child: Center(
                      child: record == null
                          ? _buildEmptyView()
                          : _buildRecentView(record),
                    ),
                  ),
                ),

                // [4. 하단 버튼들]
                Positioned(
                  left: 20,
                  bottom: 30,
                  child: _buildBottomButton(
                    icon: Icons.edit,
                    label: "RECORD",
                    onTap: () => _navigateTo(const WriteScreen()),
                  ),
                ),
                Positioned(
                  right: 20,
                  bottom: 30,
                  child: _buildBottomButton(
                    icon: Icons.history,
                    label: "HISTORY",
                    onTap: () => _navigateTo(const HistoryScreen()),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ... (하단 버튼 위젯, EmptyView 위젯은 기존과 동일) ...
  Widget _buildBottomButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: label,
          onPressed: onTap,
          backgroundColor: Colors.brown, // 버튼색은 브라운 유지 (가독성 위해)
          foregroundColor: Colors.white,
          child: Icon(icon),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.brown),
        ),
      ],
    );
  }

  Widget _buildEmptyView() {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.spa_outlined, size: 80, color: Colors.grey),
        SizedBox(height: 20),
        Text("아직 기록이 없습니다.", style: TextStyle(fontSize: 18, color: Colors.brown)),
        SizedBox(height: 5),
        Text("당신의 이야기를 들려주세요.", style: TextStyle(color: Colors.grey)),
      ],
    );
  }

  // 최근 기록 뷰
  Widget _buildRecentView(Record record) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // [수정] 텍스트 변경: 내가 머무는 감정
        const Text(
          "내가 머무는 감정",
          style: TextStyle(fontSize: 16, color: Colors.black54, letterSpacing: 1.2),
        ),
        const SizedBox(height: 20),
        
        Text(
          "\"${record.emotion}\"",
          style: const TextStyle(
            fontSize: 48, 
            fontWeight: FontWeight.bold, 
            color: Colors.black87, // 배경색에 따라 가독성 확보
            fontFamily: 'Serif', 
          ),
        ),
        
        const SizedBox(height: 40),
        
        Container(
          width: 300,
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9), // 약간 투명한 흰색 카드
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                record.date,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 15),
              Text(
                record.content,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(height: 1.6, fontSize: 15),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              // [수정] 조언 상태에 따라 다른 문구 보여주기
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // adviceContent가 null이면 아직 생성 중인 것임
                  Icon(
                    record.adviceContent != null ? Icons.mail : Icons.hourglass_top, 
                    size: 16, 
                    color: Colors.amber
                  ),
                  const SizedBox(width: 8),
                  Text(
                    record.adviceContent != null 
                        ? "5,700자 조언 보관됨" 
                        : "AI가 편지를 쓰는 중...",
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      color: record.adviceContent != null ? Colors.amber : Colors.grey
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// [추가] 노이즈 효과를 그리는 페인터
class NoisePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black;
    final random = Random();
    
    // 점을 무작위로 찍어서 노이즈 질감 표현
    // (성능을 위해 픽셀 간격을 띄워서 찍음)
    for (double i = 0; i < size.width; i += 3) {
      for (double j = 0; j < size.height; j += 3) {
        if (random.nextBool()) {
           // 아주 작은 점들을 찍음
           canvas.drawRect(Rect.fromLTWH(i, j, 1, 1), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}