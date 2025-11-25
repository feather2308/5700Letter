// lib/main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/notification_service.dart';
import 'screens/home_screen.dart';

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

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '5700 Letter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFFF7E600),
        scaffoldBackgroundColor: const Color(0xFFFFF9C4), // 연한 노랑 배경
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
          iconTheme: IconThemeData(color: Colors.black),
        ),
      ),
      // [변경] MainScreen 대신 HomeScreen을 바로 시작
      home: const HomeScreen(),
    );
  }
}