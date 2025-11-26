// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/notification_service.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('>>> 백그라운드 메시지 도착: ${message.notification?.title}');
}

void main() async {
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(); // [추가] 파이어베이스 시동

  // [중요] 2. 백그라운드 핸들러 등록
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 3. 알림 서비스 초기화 (포그라운드 수신 대기 시작)
  await NotificationService().init();

  runApp(
    MultiProvider(
      providers: [
        // 앱 전체에서 AuthProvider를 사용할 수 있게 등록
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '5700 Letter',
      theme: ThemeData(primarySwatch: Colors.amber),
      // [핵심] Provider의 상태에 따라 첫 화면 결정
      home: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          // 1. 앱이 막 켜져서 토큰 확인 중일 때 -> 스플래시 화면
          // (AuthProvider에 isChecking 변수를 추가하면 더 정교하지만, 여기선 간단히 처리)
          return FutureBuilder(
            future: auth.checkLoginStatus(), // 자동 로그인 체크 함수 호출
            builder: (context, snapshot) {
              // 로딩 중이면 스플래시 화면 표시
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SplashScreen();
              }

              // 체크 끝남 -> 로그인 되어있으면 홈, 아니면 로그인 화면
              return auth.isAuthenticated ? const HomeScreen() : const LoginScreen();
            },
          );
        },
      ),
    );
  }
}