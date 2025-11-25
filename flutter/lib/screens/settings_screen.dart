import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: const Text("설정"), // 예: "기록 작성", "히스토리", "설정"
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
      body: ListView(
        children: [
          // 1. 계정 설정 섹션
          _buildSectionHeader("계정"),
          const ListTile(
            leading: Icon(Icons.person, color: Colors.brown),
            title: Text("내 프로필"),
            subtitle: Text("이름"),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
          ),
          const ListTile(
            leading: Icon(Icons.logout, color: Colors.grey),
            title: Text("로그아웃"),
          ),

          const Divider(),

          // 2. 알림 & 테마 섹션
          _buildSectionHeader("앱 설정"),
          SwitchListTile(
            value: true, 
            onChanged: (val) {},
            activeColor: Colors.amber,
            title: const Text("일기 작성 알림"),
            subtitle: const Text("매일 저녁 9시에 알림"),
            secondary: const Icon(Icons.notifications, color: Colors.brown),
          ),
          const ListTile(
            leading: Icon(Icons.palette, color: Colors.brown),
            title: Text("테마 설정"),
            subtitle: Text("기본"),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
          ),

          const Divider(),

          // 3. 데이터 관리 섹션 (기능 구현됨)
          _buildSectionHeader("데이터 관리"),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text("데이터 초기화", style: TextStyle(color: Colors.red)),
            subtitle: const Text("모든 일기와 조언 기록을 삭제합니다."),
            onTap: () => _showDeleteConfirmDialog(context),
          ),

          const Divider(),

          // 4. 정보 섹션
          _buildSectionHeader("정보"),
          const ListTile(
            leading: Icon(Icons.info_outline, color: Colors.grey),
            title: Text("앱 버전"),
            trailing: Text("1.0.0"),
          ),
          const ListTile(
            leading: Icon(Icons.code, color: Colors.grey),
            title: Text("개발자 정보"),
            subtitle: Text("Created with Gemini & Qdrant"),
          ),
        ],
      ),
    );
  }

  // 섹션 제목 위젯
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14, 
          fontWeight: FontWeight.bold, 
          color: Colors.grey
        ),
      ),
    );
  }

  // 데이터 삭제 확인 팝업
  void _showDeleteConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("정말 삭제하시겠습니까?"),
        content: const Text("삭제된 데이터는 복구할 수 없습니다.\n모든 기록이 사라집니다."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("취소"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // 팝업 닫기
              try {
                final apiService = ApiService();
                await apiService.deleteAllRecords(1); // 1번 유저 데이터 삭제
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("모든 데이터가 초기화되었습니다.")),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("오류 발생: $e")),
                  );
                }
              }
            },
            child: const Text("삭제", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}