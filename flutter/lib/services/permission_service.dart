import 'dart:io';
import 'package:flutter/services.dart';

class PermissionService {
  static const _channel = MethodChannel("exact_alarm_channel");

  // 권한 여부 체크
  static Future<bool> canScheduleExactAlarm() async {
    if (!Platform.isAndroid) return true;
    return await _channel.invokeMethod("canScheduleExactAlarm");
  }

  // 권한 설정 화면 열기
  static Future<void> openSettings() async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod("openExactAlarmSettings");
  }
}
