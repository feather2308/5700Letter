import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // 새로고침 신호를 위한 스트림 컨트롤러
  final StreamController<void> _refreshStreamController = StreamController.broadcast();
  Stream<void> get onRefreshNeeded => _refreshStreamController.stream;

  final FlutterLocalNotificationsPlugin notifications =
  FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // 1. Timezone 초기화 (스케줄링에 필수)
    tz.initializeTimeZones();

    // 2. 안드로이드 초기화 설정
    const AndroidInitializationSettings androidInit =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // 3. iOS 초기화 설정
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

    // 4. 플러그인 초기화
    await notifications.initialize(initSettings);

    // 5. FCM 권한 요청
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 6. 포그라운드 메시지 리스너
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('>>> 포그라운드 메시지 수신: ${message.notification?.title}');
      if (message.notification != null) {
        showNotification(message);
        _refreshStreamController.add(null); // 새로고침 신호 발송
      }
    });
  }

  // 즉시 알림 표시 (FCM 수신 시 사용)
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

  // 매일 정해진 시간에 알림 예약 (최신 API 적용)
  Future<void> scheduleDailyNotification(int hour, int minute) async {
    // 기존 예약 취소 (중복 방지)
    await cancelDailyNotification();

    // 현재 로컬 시간 기준 설정
    final now = tz.TZDateTime.now(tz.local);

    // 예약 시간 생성
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // 만약 설정한 시간이 현재보다 이전이라면, 내일로 예약
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await notifications.zonedSchedule(
      1, // ID (매일 알림은 1번 고정)
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
      // [핵심] 매일 같은 시간에 반복하도록 설정
      matchDateTimeComponents: DateTimeComponents.time,

      // [중요] 안드로이드 정확한 알람 설정 (Doze 모드 대응)
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    print(">>> 알림 예약 완료: 매일 $hour시 $minute분");
  }

  // 알림 예약 취소
  Future<void> cancelDailyNotification() async {
    await notifications.cancel(1);
    print(">>> 알림 예약 취소됨");
  }
}