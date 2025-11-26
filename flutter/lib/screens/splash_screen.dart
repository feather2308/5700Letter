import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFFFF9C4), // 앱 테마색
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mail_outline, size: 80, color: Colors.brown),
            SizedBox(height: 20),
            Text("5700 LETTER", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            CircularProgressIndicator(color: Colors.brown), // 로딩바
          ],
        ),
      ),
    );
  }
}