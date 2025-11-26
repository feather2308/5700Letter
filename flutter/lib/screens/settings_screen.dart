import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../services/dio_client.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../models/user.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _dio = DioClient().dio;
  User? _user;
  bool _isLoading = true;

  // 알림 설정
  bool _isNotificationEnabled = true;
  TimeOfDay _notificationTime = const TimeOfDay(hour: 21, minute: 0);

  @override
  void initState() {
    super.initState();
    _fetchMyInfo();
    _loadSettings();
  }

  // 내 정보 가져오기
  Future<void> _fetchMyInfo() async {
    try {
      final response = await _dio.get('/member/me');
      setState(() {
        _user = User.fromJson(response.data);
        _isLoading = false;
      });
    } catch (e) {
      print('정보 조회 실패: $e');
      setState(() => _isLoading = false);
    }
  }

  // 알림 설정 불러오기
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isNotificationEnabled = prefs.getBool('isNotificationEnabled') ?? true;
      final hour = prefs.getInt('notificationHour') ?? 21;
      final minute = prefs.getInt('notificationMinute') ?? 0;
      _notificationTime = TimeOfDay(hour: hour, minute: minute);
    });
  }

  // 이름 변경 다이얼로그
  void _showEditProfileDialog() {
    if (_user == null) return;
    final nameController = TextEditingController(text: _user!.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("프로필 수정"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: "새로운 이름"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("취소"),
          ),
          TextButton(
            onPressed: () async {
              await _updateName(nameController.text);
              if (mounted) Navigator.pop(context);
            },
            child: const Text("저장"),
          ),
        ],
      ),
    );
  }

  // 이름 변경 요청
  Future<void> _updateName(String newName) async {
    try {
      await _dio.put('/member/me', data: {'name': newName});
      _fetchMyInfo();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("이름이 변경되었습니다.")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("변경 실패")),
        );
      }
    }
  }

  // 알림 ON/OFF 토글
  Future<void> _toggleNotification(bool value) async {
    setState(() => _isNotificationEnabled = value);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isNotificationEnabled', value);

    if (value) {
      await NotificationService().scheduleDailyNotification(
        _notificationTime.hour,
        _notificationTime.minute,
      );
    } else {
      await NotificationService().cancelDailyNotification();
    }
  }

  // 알림 시간 변경
  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _notificationTime,
    );

    if (picked != null && picked != _notificationTime) {
      setState(() => _notificationTime = picked);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('notificationHour', picked.hour);
      await prefs.setInt('notificationMinute', picked.minute);

      if (_isNotificationEnabled) {
        await NotificationService().scheduleDailyNotification(
          picked.hour,
          picked.minute,
        );
      }
    }
  }

  // 데이터 초기화 확인 다이얼로그
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
              Navigator.pop(context);
              try {
                final apiService = ApiService();
                // 토큰으로 자동 인증되므로 파라미터 불필요
                await apiService.deleteAllRecords();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("모든 데이터가 초기화되었습니다.")),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("초기화 실패")),
                  );
                }
              }
            },
            child: const Text(
              "삭제",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // 로그아웃
  void _logout() {
    Provider.of<AuthProvider>(context, listen: false).logout();
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        children: [
          // 1. 계정 섹션
          _buildSectionHeader("계정"),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.brown,
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: Text(
              _user?.name ?? "알 수 없음",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text("ID: ${_user?.username}"),
            trailing: const Icon(Icons.edit, size: 16, color: Colors.brown),
            onTap: _showEditProfileDialog,
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.grey),
            title: const Text("로그아웃"),
            onTap: _logout,
          ),

          const Divider(),

          // 2. 앱 설정 섹션
          _buildSectionHeader("앱 설정"),
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
          if (_isNotificationEnabled)
            ListTile(
              leading: const SizedBox(width: 40), // 들여쓰기용
              title: const Text(
                "알림 시간 변경",
                style: TextStyle(color: Colors.blue),
              ),
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

          // 3. 데이터 관리 섹션
          _buildSectionHeader("데이터 관리"),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text(
              "데이터 초기화",
              style: TextStyle(color: Colors.red),
            ),
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }
}