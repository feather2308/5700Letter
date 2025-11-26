import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart'; // 에러 처리를 위해 필요
import '../providers/auth_provider.dart';
import '../services/dio_client.dart'; // API 호출용 (직접 호출 시)
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _dio = DioClient().dio; // 로그인 요청은 Provider 내부 로직 또는 여기서 직접 호출

  void _tryLogin() async {
    final username = _usernameController.text;
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) return;

    try {
      // 1. 백엔드 로그인 API 호출
      final response = await _dio.post('/auth/login', data: {
        'username': username,
        'password': password,
      });

      // 2. 응답에서 토큰 추출
      final token = response.data['token'];

      // 3. Provider를 통해 로그인 상태 업데이트 (화면이 자동으로 홈으로 바뀜)
      if (mounted) {
        await Provider.of<AuthProvider>(context, listen: false).login(token);
      }
    } on DioException catch (e) {
      // 에러 처리 (알림창 등)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 실패: 아이디 또는 비밀번호를 확인하세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("로그인", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: "아이디"),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: "비밀번호"),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _tryLogin,
              child: const Text("로그인"),
            ),
            TextButton(
              onPressed: () {
                // 회원가입 화면으로 이동
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignupScreen()),
                );
              },
              child: const Text("계정이 없으신가요? 회원가입"),
            )
          ],
        ),
      ),
    );
  }
}