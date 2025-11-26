import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/dio_client.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _dio = DioClient().dio;

  void _trySignup() async {
    try {
      await _dio.post('/auth/signup', data: {
        'username': _usernameController.text,
        'password': _passwordController.text,
        'name': _nameController.text,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원가입 성공! 로그인해주세요.')),
        );
        Navigator.pop(context); // 로그인 화면으로 복귀
      }
    } on DioException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('회원가입 실패: 이미 존재하는 아이디거나 오류가 발생했습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("회원가입")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: "아이디"),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: "비밀번호"),
              obscureText: true,
            ),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "이름 (닉네임)"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _trySignup,
              child: const Text("가입하기"),
            ),
          ],
        ),
      ),
    );
  }
}