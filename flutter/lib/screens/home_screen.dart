import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import '../models/record.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'write_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final ApiService _apiService = ApiService();

  late Future<Record?> _todayRecordFuture;

  StreamSubscription? _refreshSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _todayRecordFuture = _fetchTodayRecord();

    _refreshSubscription = NotificationService().onRefreshNeeded.listen((_) {
      print(">>> 홈 화면: 알림 도착! 데이터 갱신");
      _refresh();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
    }
  }

  Future<Record?> _fetchTodayRecord() async {
    try {
      List<Record> records = await _apiService.getMemberRecords();
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

  String _formatDate(String dateString) {
    try {
      DateTime date = DateTime.parse(dateString);
      return DateFormat('yy.MM.dd HH:mm').format(date);
    } catch (e) {
      return "-";
    }
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
    ).then((_) {
      print(">>> 홈 화면 복귀: 데이터 새로고침 실행");
      _refresh();
    });
  }

  LinearGradient _getGradient(String emotion) {
    Color topColor, bottomColor;

    if (emotion.isEmpty) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFF9C4), Color(0xFFFFF176)],
      );
    }

    switch (emotion) {
      case "기쁨": topColor = const Color(0xFFFFEAA7); bottomColor = const Color(0xFFFFD58A); break;
      case "슬픔": topColor = const Color(0xFFA8C0FF); bottomColor = const Color(0xFF8FA9F0); break;
      case "불안": topColor = const Color(0xFFF8C8DC); bottomColor = const Color(0xFFEBAEC7); break;
      case "분노": topColor = const Color(0xFFFFB4A2); bottomColor = const Color(0xFFF29A88); break;
      case "평온": topColor = const Color(0xFFC8E6C9); bottomColor = const Color(0xFFAFCFB1); break;
      case "우울": topColor = const Color(0xFFE0EAFC); bottomColor = const Color(0xFFCFDEF3); break;
      case "기대": topColor = const Color(0xFFE0F7FA); bottomColor = const Color(0xFF80DEEA); break;
      case "후회": topColor = const Color(0xFFF3E5F5); bottomColor = const Color(0xFFCE93D8); break;
      case "벅참": topColor = const Color(0xFFFFF3E0); bottomColor = const Color(0xFFFFB74D); break;
      case "피로": topColor = const Color(0xFFF5F5F5); bottomColor = const Color(0xFFBDBDBD); break;
      default:   topColor = const Color(0xFFFFF9C4); bottomColor = const Color(0xFFFFF176);
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
        final emotion = record?.emotion ?? "";

        return Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
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
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings, size: 28),
                onPressed: () => _navigateTo(const SettingsScreen()),
              ),
              const SizedBox(width: 10),
            ],
          ),
          // [핵심 수정] Container는 배경을 위해 Scafold의 Body로 남겨두고,
          // 그 안에 SafeArea를 넣어 콘텐츠를 안전하게 만듭니다.
          body: Container(
            decoration: BoxDecoration(
              gradient: _getGradient(emotion),
            ),
            child: SafeArea( // <--- 여기가 SafeArea 추가 지점
              child: Stack(
                children: [
                  // 1. 노이즈 레이어
                  Positioned.fill(
                    child: NoiseOverlay(intensity: 0.05),
                  ),

                  // 2. 메인 컨텐츠
                  Positioned.fill(
                    child: Padding(
                      // SafeArea가 이미 하단 패딩을 주었으므로, 여기서 추가 패딩은 제거하거나 조정
                      padding: const EdgeInsets.only(bottom: 80),
                      child: Center(
                        child: record == null
                            ? _buildEmptyView()
                            : _buildRecentView(record),
                      ),
                    ),
                  ),

                  // 3. 하단 버튼들 (SafeArea 안에서 bottom: 30은 시스템 UI 위 30픽셀을 의미)
                  Positioned(
                    left: 20,
                    bottom: 30, // [수정] 수동 패딩 제거
                    child: _buildBottomButton(
                      icon: Icons.edit,
                      label: "RECORD",
                      onTap: () => _navigateTo(const WriteScreen()),
                    ),
                  ),
                  Positioned(
                    right: 20,
                    bottom: 30, // [수정] 수동 패딩 제거
                    child: _buildBottomButton(
                      icon: Icons.history,
                      label: "HISTORY",
                      onTap: () => _navigateTo(const HistoryScreen()),
                    ),
                  ),
                ],
              ),
            ), // <--- SafeArea 닫힘
          ),
        );
      },
    );
  }

  Widget _buildBottomButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: label,
          onPressed: onTap,
          backgroundColor: Colors.brown,
          foregroundColor: Colors.white,
          child: Icon(icon),
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
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

  Widget _buildRecentView(Record record) {
    bool isAnalyzing = record.emotion.isEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "내가 머무는 감정",
          style: TextStyle(fontSize: 16, color: Colors.black54, letterSpacing: 1.2),
        ),
        const SizedBox(height: 20),

        isAnalyzing
            ? const Text(
          "마음을 읽는 중...",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
            fontStyle: FontStyle.italic,
          ),
        )
            : Text(
          "\"${record.emotion}\"",
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontFamily: 'Serif',
          ),
        ),

        const SizedBox(height: 40),

        Container(
          width: 300,
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
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
              // [수정] 날짜 표시 (포맷 함수 적용)
              Text(
                _formatDate(record.date),
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

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isAnalyzing ? Icons.hourglass_top : Icons.mail,
                    size: 16,
                    color: Colors.amber,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isAnalyzing ? "AI가 편지를 쓰고 있습니다..." : "5,700자 조언 보관됨",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
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

class NoiseShaderPainter extends CustomPainter {
  final ui.FragmentShader shader;
  final double time;
  final double intensity;

  NoiseShaderPainter({
    required this.shader,
    required this.time,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, time);
    shader.setFloat(3, intensity);

    final paint = Paint()..shader = shader;

    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(NoiseShaderPainter oldDelegate) =>
      oldDelegate.time != time ||
          oldDelegate.intensity != intensity;
}


class NoiseOverlay extends StatefulWidget {
  final double intensity;

  const NoiseOverlay({super.key, this.intensity = 0.05});

  @override
  State<NoiseOverlay> createState() => _NoiseOverlayState();
}

class _NoiseOverlayState extends State<NoiseOverlay> {
  ui.FragmentShader? _shader;

  @override
  void initState() {
    super.initState();
    _loadShader();
  }

  Future<void> _loadShader() async {
    final program = await ui.FragmentProgram.fromAsset(
      'assets/shaders/noise.frag',
    );

    setState(() {
      _shader = program.fragmentShader();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_shader == null) return const SizedBox.shrink();

    return CustomPaint(
      painter: _StaticNoisePainter(
        shader: _shader!,
        intensity: widget.intensity,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _StaticNoisePainter extends CustomPainter {
  final ui.FragmentShader shader;
  final double intensity;

  _StaticNoisePainter({
    required this.shader,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    shader.setFloat(0, size.width);   // u_resolution.x
    shader.setFloat(1, size.height);  // u_resolution.y
    shader.setFloat(2, 1.0);          // u_time -> 고정
    shader.setFloat(3, intensity);    // u_intensity

    final paint = Paint()..shader = shader;

    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}