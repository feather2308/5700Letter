import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isNotificationEnabled = true; // 기본값 ON
  TimeOfDay _notificationTime = const TimeOfDay(hour: 21, minute: 0); // 기본값 21:00

  @override
  void initState() {
    super.initState();
    _loadSettings(); // 저장된 설정 불러오기
  }

  // 설정 불러오기
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isNotificationEnabled = prefs.getBool('isNotificationEnabled') ?? true;
      final hour = prefs.getInt('notificationHour') ?? 21;
      final minute = prefs.getInt('notificationMinute') ?? 0;
      _notificationTime = TimeOfDay(hour: hour, minute: minute);
    });
  }

  // 알림 ON/OFF 토글
  Future<void> _toggleNotification(bool value) async {
    setState(() => _isNotificationEnabled = value);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isNotificationEnabled', value);

    if (value) {
      // 켜지면 현재 설정된 시간으로 예약
      await NotificationService().scheduleDailyNotification(
          _notificationTime.hour,
          _notificationTime.minute
      );
    } else {
      // 꺼지면 예약 취소
      await NotificationService().cancelDailyNotification();
    }
  }

  // 시간 변경
  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _notificationTime,
    );

    if (picked != null && picked != _notificationTime) {
      setState(() => _notificationTime = picked);

      // 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('notificationHour', picked.hour);
      await prefs.setInt('notificationMinute', picked.minute);

      // 스위치가 켜져 있다면 예약 시간 업데이트
      if (_isNotificationEnabled) {
        await NotificationService().scheduleDailyNotification(picked.hour, picked.minute);
      }
    }
  }

  // ... (기존 삭제 관련 코드 생략, 아래 build에 통합됨) ...

  void _showDeleteConfirmDialog(BuildContext context) {
    // ... (기존 코드 그대로 사용) ...
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
              Navigator.pop(context);
              try {
                final apiService = ApiService();
                await apiService.deleteAllRecords(1);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("모든 데이터가 초기화되었습니다.")),
                  );
                }
              } catch (e) {
                // ...
              }
            },
            child: const Text("삭제", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("설정"),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: ListView(
        children: [
          _buildSectionHeader("계정"),
          const ListTile(
            leading: Icon(Icons.person, color: Colors.brown),
            title: Text("내 프로필"),
            subtitle: Text("강성왕 (203602)"),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
          ),
          const ListTile(
            leading: Icon(Icons.logout, color: Colors.grey),
            title: Text("로그아웃"),
          ),

          const Divider(),

          _buildSectionHeader("앱 설정"),
          // [수정] 스위치와 시간 설정 연결
          SwitchListTile(
            value: _isNotificationEnabled,
            onChanged: _toggleNotification,
            activeColor: Colors.amber,
            title: const Text("일기 작성 알림"),
            subtitle: Text(_isNotificationEnabled
                ? "매일 ${_notificationTime.format(context)}에 알림"
                : "알림 꺼짐"),
            secondary: const Icon(Icons.notifications, color: Colors.brown),
          ),
          // [추가] 시간이 켜져 있을 때만 시간 변경 버튼 보이기
          if (_isNotificationEnabled)
            ListTile(
              leading: const SizedBox(), // 들여쓰기용
              title: const Text("알림 시간 변경", style: TextStyle(color: Colors.blue)),
              trailing: const Icon(Icons.access_time, color: Colors.blue),
              onTap: _pickTime,
            ),

          const ListTile(
            leading: Icon(Icons.palette, color: Colors.brown),
            title: Text("테마 설정"),
            subtitle: Text("기본 (Pastel Yellow)"),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
          ),

          const Divider(),

          _buildSectionHeader("데이터 관리"),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text("데이터 초기화", style: TextStyle(color: Colors.red)),
            subtitle: const Text("모든 일기와 조언 기록을 삭제합니다."),
            onTap: () => _showDeleteConfirmDialog(context),
          ),

          const Divider(),

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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }
}