import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications_plus/flutter_local_notifications_plus.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final StreamController<void> _refreshStreamController =
  StreamController.broadcast();
  Stream<void> get onRefreshNeeded => _refreshStreamController.stream;

  final FlutterLocalNotificationsPlugin notifications =
  FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    // ---- Android ----
    const AndroidInitializationSettings androidInit =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // ---- iOS ----
    final DarwinInitializationSettings iosInit =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // ---- 공통 설정 ----
    final InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    // ---- 알림 초기화 ----
    await notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (resp) {
        print(">>> 알림 클릭됨: ${resp.payload}");
      },
    );

    // Android 13+ 권한 요청
    await _requestAndroidNotificationPermission();

    // FCM 권한
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // FCM - 포그라운드 수신
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print(">>> [FCM] 포그라운드 수신: ${message.notification?.title}");
      if (message.notification != null) {
        showFcmNotification(message);
        _refreshStreamController.add(null);
      }
    });
  }

  // Android 13+ 권한 요청
  Future<void> _requestAndroidNotificationPermission() async {
    final android = notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await android?.requestNotificationsPermission();
  }

  // 포그라운드 FCM 알림 표시
  Future<void> showFcmNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'advice_channel_id',
      '5700 Letter 알림',
      channelDescription: '조언 도착 알림',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await notifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      details,
      payload: 'fcm',
    );
  }

  // 매일 알림 예약
  Future<void> scheduleDailyNotification(int hour, int minute) async {
    await cancelDailyNotification();

    final now = tz.TZDateTime.now(tz.local);
    var schedule = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (schedule.isBefore(now)) {
      schedule = schedule.add(const Duration(days: 1));
    }

    await notifications.zonedSchedule(
      1,
      '하루를 기록할 시간이에요 🌙',
      '오늘 있었던 일을 5700 Letter에 털어놓으세요.',
      schedule,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder_channel',
          '일기 알림',
          channelDescription: '매일 일정 시간 알림',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: "daily",
    );

    print(">>> 매일 알림 예약됨: $hour:$minute");
  }

  Future<void> cancelDailyNotification() async {
    await notifications.cancel(1);
    print(">>> 매일 알림 취소됨");
  }
}
