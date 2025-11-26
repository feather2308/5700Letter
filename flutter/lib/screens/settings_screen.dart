import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:letter_5700/services/permission_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/dio_client.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _dio = DioClient().dio;
  User? _user;
  bool _isLoading = true;
  bool isDiaryNotificationEnabled = false;

  // [부활] 시간 설정 변수
  bool _isNotificationEnabled = true;
  TimeOfDay _notificationTime = const TimeOfDay(hour: 21, minute: 0);

  // 이스터 에그 변수
  int _devTapCount = 0;
  bool _isDebugMode = false;

  @override
  void initState() {
    super.initState();
    _fetchMyInfo();
    _loadSettings();
  }

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

  // [수정] 저장된 시간 불러오기
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isNotificationEnabled = prefs.getBool('isNotificationEnabled') ?? true;
      final hour = prefs.getInt('notificationHour') ?? 21;
      final minute = prefs.getInt('notificationMinute') ?? 0;
      _notificationTime = TimeOfDay(hour: hour, minute: minute);
    });
  }

  void _handleDevTap() {
    if (_isDebugMode) return;
    setState(() {
      _devTapCount++;
    });
    if (_devTapCount >= 5) {
      setState(() {
        _isDebugMode = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🔧 개발자 모드가 활성화되었습니다!")),
      );
    }
  }

  // ... (프로필 수정 관련 코드 _showEditProfileDialog, _updateName 동일) ...
  void _showEditProfileDialog() {
    if (_user == null) return;
    final nameController = TextEditingController(text: _user!.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("프로필 수정"),
        content: TextField(controller: nameController, decoration: const InputDecoration(labelText: "새로운 이름")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("취소")),
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

  Future<void> _updateName(String newName) async {
    try {
      await _dio.put('/member/me', data: {'name': newName});
      _fetchMyInfo();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("이름이 변경되었습니다.")));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("변경 실패")));
    }
  }

  // [수정] 알림 토글 (현재 설정된 시간으로 예약)
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

  // [부활] 시간 변경 함수
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

      // 알림이 켜져 있으면 즉시 재예약
      if (_isNotificationEnabled) {
        await NotificationService().scheduleDailyNotification(
          picked.hour,
          picked.minute,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("매일 ${_notificationTime.format(context)}에 알림이 울립니다.")),
          );
        }
      }
    }
  }

  void _showDeleteConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("정말 삭제하시겠습니까?"),
        content: const Text("삭제된 데이터는 복구할 수 없습니다.\n모든 기록이 사라집니다."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("취소")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final apiService = ApiService();
                await apiService.deleteAllRecords();
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("초기화 완료")));
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("초기화 실패")));
              }
            },
            child: const Text("삭제", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _logout() {
    Navigator.pop(context);
    Provider.of<AuthProvider>(context, listen: false).logout();
  }

  // [추가] 예약된 알림 확인 함수
  Future<void> _checkPendingNotifications() async {
    final pendingNotifications = await NotificationService().getPendingNotifications();

    if (!mounted) return;

    if (pendingNotifications.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("현재 예약된 알림이 없습니다.")),
      );
    } else {
      // 예약된 알림 정보 조합
      String info = "총 ${pendingNotifications.length}개의 알림 대기 중:\n";
      for (var notification in pendingNotifications) {
        info += "• ID: ${notification.id} / 제목: ${notification.title}\n";
      }

      // 다이얼로그로 상세 정보 표시
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("알림 예약 현황"),
          content: Text(info),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("확인"),
            ),
          ],
        ),
      );
    }
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
          _buildSectionHeader("계정"),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.brown,
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: Text(_user?.name ?? "알 수 없음", style: const TextStyle(fontWeight: FontWeight.bold)),
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

          _buildSectionHeader("앱 설정"),
          /*
          // [수정] 스위치와 시간 변경 UI
          SwitchListTile(
            title: Text("일기 작성 알림"),
            value: isDiaryNotificationEnabled,
            onChanged: (value) async {
              if (value) {
                // 토글 ON → 정확 알람 권한 확인
                final allowed = await PermissionService.canScheduleExactAlarm();

                if (!allowed) {
                  // 권한 없음 → 설정으로 이동시키기
                  await PermissionService.openSettings();

                  // 설정 화면 다녀오면 다시 권한 체크 필요
                  Future.delayed(Duration(seconds: 1), () async {
                    final allowedAfter = await PermissionService.canScheduleExactAlarm();
                    if (!allowedAfter) {
                      // 아직도 권한 없으면 토글 OFF 유지
                      setState(() => isDiaryNotificationEnabled = false);
                      return;
                    }

                    // 권한 허용됨 → 알림 스케줄 시작
                    setState(() => isDiaryNotificationEnabled = true);
                    final prefs = await SharedPreferences.getInstance();
                    NotificationService().scheduleDailyNotification(
                      prefs.getInt('notificationHour') ?? 21,
                      prefs.getInt('notificationMinute') ?? 0,
                    );
                    _isNotificationEnabled = true;
                  });
                  return;
                }

                // 권한 이미 있음
                setState(() => isDiaryNotificationEnabled = true);
                final prefs = await SharedPreferences.getInstance();

                NotificationService().scheduleDailyNotification(
                  prefs.getInt('notificationHour') ?? 21,
                  prefs.getInt('notificationMinute') ?? 0,
                );
                _isNotificationEnabled = true;
              } else {
                // 알림 OFF
                setState(() => isDiaryNotificationEnabled = false);
                NotificationService().cancelDailyNotification();
                _isNotificationEnabled = false;
              }
            },
          ),

          // [부활] 시간 변경 버튼 (켜져 있을 때만 보임)
          if (_isNotificationEnabled)
            ListTile(
              leading: const SizedBox(width: 40),
              title: const Text("알림 시간 변경", style: TextStyle(color: Colors.blue)),
              trailing: const Icon(Icons.access_time, color: Colors.blue),
              onTap: _pickTime,
            ),

           */

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
          ListTile(
            leading: const Icon(Icons.code, color: Colors.grey),
            title: const Text("개발자 정보"),
            subtitle: const Text("Created with Gemini & Qdrant"),
            onTap: _handleDevTap, // 이스터 에그 트리거
          ),

          // [수정] 디버그 섹션 (히든)
          if (_isDebugMode) ...[
            const Divider(),
            _buildSectionHeader("디버그 (테스트용)"),
            ListTile(
              leading: const Icon(Icons.bug_report, color: Colors.orange),
              title: const Text("알림 테스트 발송"),
              subtitle: const Text("3초 뒤에 테스트 알림을 즉시 보냅니다."),
              onTap: () async {
                await NotificationService().requestPermissions();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("3초 뒤에 알림이 옵니다!")),
                  );
                }
                Future.delayed(const Duration(seconds: 3), () {
                  NotificationService().showNotification(
                    const RemoteMessage(
                      notification: RemoteNotification(
                        title: "🔔 디버그 알림",
                        body: "알림 시스템이 정상 작동 중입니다!",
                      ),
                    ),
                  );
                });
              },
            ),
            // 2. [추가] 예약 정보 확인 버튼
            ListTile(
              leading: const Icon(Icons.playlist_add_check, color: Colors.blue),
              title: const Text("예약된 알림 정보"),
              subtitle: const Text("현재 대기 중인 시스템 알림을 확인합니다."),
              onTap: _checkPendingNotifications, // 위에서 만든 함수 호출
            ),
            ListTile(
              leading: const Icon(Icons.access_time_filled, color: Colors.teal),
              title: const Text("현재 기기 시간 확인"),
              subtitle: const Text("시스템 시간 및 타임존을 확인합니다."),
              onTap: () {
                // 현재 시간 가져오기
                final now = DateTime.now();
                final formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
                final timeZone = now.timeZoneName;
                final offset = now.timeZoneOffset.toString();

                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("현재 시스템 시간"),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("현재 시각:", style: TextStyle(color: Colors.grey)),
                        Text(
                          formattedDate,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown),
                        ),
                        const Divider(height: 30),
                        Text("타임존: $timeZone"),
                        Text("오차(Offset): $offset"),
                        const SizedBox(height: 10),
                        const Text(
                          "* 알림은 이 시간을 기준으로 예약됩니다.",
                          style: TextStyle(fontSize: 12, color: Colors.redAccent),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("확인"),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 50),
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