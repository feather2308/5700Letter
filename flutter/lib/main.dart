import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'screens/home_screen.dart';
import 'screens/write_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  // 1. .env 파일 로드
  await dotenv.load(fileName: ".env");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '5700 Letter',
      debugShowCheckedModeBanner: false, // 디버그 띠 제거
      theme: ThemeData(
        // 계획서의 따뜻한/노란색 느낌 (Pastel Yellow & Brown)
        primaryColor: const Color(0xFFF7E600),
        scaffoldBackgroundColor: const Color(0xFFFFF9C4), // 연한 노랑 배경
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
          iconTheme: IconThemeData(color: Colors.black),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // [수정] _screens 리스트 변수를 지우고, 여기서 바로 switch문으로 화면 선택
    // 이렇게 해야 탭을 누를 때마다 화면이 새로 그려지면서 데이터를 다시 불러옵니다.
    Widget getBody() {
      switch (_selectedIndex) {
        case 0: return const WriteScreen();
        case 1: return const HistoryScreen();
        case 2: return const HomeScreen();
        case 3: return const SettingsScreen(); // [연결] SizedBox -> SettingsScreen
        default: return const SizedBox();
      }
    }
    return Scaffold(
      body: SafeArea(
        child: getBody(), // 여기서 함수 호출
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // 4개 이상일 때 필수
        backgroundColor: Colors.white,
        selectedItemColor: Colors.brown,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.edit), label: 'RECORD'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'HISTORY'),
          BottomNavigationBarItem(icon: Icon(Icons.mail_outline), label: 'OPEN'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'SETTINGS'),
        ],
      ),
    );
  }
}