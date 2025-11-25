import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // [추가] 1. 알림이 왔다는 신호를 보내줄 방송국(StreamController)
  final StreamController<void> _refreshStreamController = StreamController.broadcast();

  // 외부에서 이 방송을 들을 수 있게 getter 제공
  Stream<void> get onRefreshNeeded => _refreshStreamController.stream;

  // 1. 초기화 및 리스너 등록
  Future<void> init() async {
    // (1) 로컬 알림 플러그인 설정
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // (2) FCM 권한 요청 (iOS 필수, 안드로이드 13+ 필수)
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // (3) [핵심] 포그라운드(앱 켜져있을 때) 메시지 수신 리스너
    // FCM은 앱이 켜져있으면 알림을 안 띄웁니다. 그래서 우리가 직접 띄워줘야 합니다.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('>>> 포그라운드 메시지 수신: ${message.notification?.title}');

      if (message.notification != null) {
        showNotification(message);

        // [추가] 2. 알림이 오면 "새로고침 하세요!" 신호를 쏨
        _refreshStreamController.add(null);
      }
    });
  }

  // 2. 알림 띄우기 함수
  Future<void> showNotification(RemoteMessage message) async {
    // 안드로이드 알림 채널 설정 (헤드업 알림 중요도 Max)
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'advice_channel_id', // 채널 ID (고유해야 함)
      '5700 Letter 알림',   // 채널 이름 (사용자에게 보임)
      channelDescription: '조언 도착 알림',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      message.hashCode, // 알림 ID
      message.notification?.title, // 제목 (서버에서 보낸 것)
      message.notification?.body,  // 내용 (서버에서 보낸 것)
      platformChannelSpecifics,
    );
  }
}