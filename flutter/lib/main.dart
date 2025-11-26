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
  // [필수] 비동기 작업(Firebase, dotenv) 전에 반드시 호출해야 함
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp();

  // 백그라운드 핸들러 등록
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 알림 서비스 초기화
  await NotificationService().init();

  runApp(
    MultiProvider(
      providers: [
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
      // [수정] 로직을 분리한 AuthWrapper 위젯 사용
      home: const AuthWrapper(),
    );
  }
}

// [추가] 로그인 상태 체크를 담당하는 별도 위젯
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late Future<void> _loginCheckFuture;

  @override
  void initState() {
    super.initState();
    // [핵심] initState에서 딱 한 번만 실행해서 변수에 담아둠 (무한반복 방지)
    _loginCheckFuture = Provider.of<AuthProvider>(context, listen: false).checkLoginStatus();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loginCheckFuture, // 변수에 담아둔 Future 사용
      builder: (context, snapshot) {
        // 1. 로딩 중일 때
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        // 2. 로딩 끝났을 때 (Consumer로 상태만 구독)
        return Consumer<AuthProvider>(
          builder: (context, auth, child) {
            return auth.isAuthenticated ? const HomeScreen() : const LoginScreen();
          },
        );
      },
    );
  }
}