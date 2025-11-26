import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

      // 알림 클릭 시 콜백
      onDidReceiveLocalNotification: onDidReceiveLocalNotification,
    );

    // ---- 공통 ----
    final InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        print(">>> [알림 클릭] ${details.payload}");
      },
    );

    // Android 13+ 알림 권한 요청
    await requestNotificationPermission();

    // Firebase 메시지 권한
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // FCM 포그라운드 수신
    FirebaseMessaging.onMessage.listen((message) {
      print('>>> FCM 포그라운드 수신: ${message.notification?.title}');
      if (message.notification != null) {
        showNotification(message);
        _refreshStreamController.add(null);
      }
    });
  }

  // Android 13 권한 요청
  Future<void> requestNotificationPermission() async {
    final androidPlugin = notifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();
  }

  // iOS - 포그라운드 알림 표시
  void onDidReceiveLocalNotification(
      int id, String? title, String? body, String? payload) {
    print(">>> [iOS 포그라운드 알림] $title");
  }

  // FCM 메시지 표시
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

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await notifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      platformDetails,
      payload: 'fcm',
    );
  }

  // 매일 알림
  Future<void> scheduleDailyNotification(int hour, int minute) async {
    await cancelDailyNotification();

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
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
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'daily',
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );

    print(">>> 매일 알림 예약됨: $hour:$minute");
  }

  Future<void> cancelDailyNotification() async {
    await notifications.cancel(1);
    print(">>> 매일 알림 취소됨");
  }
}
