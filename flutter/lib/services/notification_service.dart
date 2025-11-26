import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications_plus/flutter_local_notifications_plus.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final StreamController<void> _refreshStreamController = StreamController.broadcast();
  Stream<void> get onRefreshNeeded => _refreshStreamController.stream;

  final FlutterLocalNotificationsPlugin notifications =
  FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidInit =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings iosInit =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await notifications.initialize(initSettings);

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        showNotification(message);
        _refreshStreamController.add(null);
      }
    });
  }

  Future<void> showNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'advice_channel_id',
      '5700 Letter 알림',
      channelDescription: '조언 도착 알림',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails platformDetails =
    NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails());

    await notifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      platformDetails,
    );
  }

  // [수정] 다시 시간(hour, minute)을 받도록 변경
  Future<void> scheduleDailyNotification(int hour, int minute) async {
    await cancelDailyNotification();

    final now = tz.TZDateTime.now(tz.local);

    // 전달받은 시간으로 예약 객체 생성
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,   // 사용자 지정 시간
      minute, // 사용자 지정 분
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await notifications.zonedSchedule(
      1,
      '하루를 기록할 시간이에요 🌙',
      '오늘 있었던 일을 5700 Letter에 털어놓으세요.',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder_channel',
          '일기 작성 알림',
          channelDescription: '매일 작성 유도 알림',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),

      // [중요] 에러 방지를 위해 inexact 모드 유지!
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,

      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    print(">>> 알림 예약 완료: 매일 $hour시 $minute분");
  }

  Future<void> cancelDailyNotification() async {
    await notifications.cancel(1);
    print(">>> 알림 예약 취소됨");
  }

  Future<void> requestPermissions() async {
    await notifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // [추가] 현재 예약된 알림 리스트 가져오기
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await notifications.pendingNotificationRequests();
  }
}