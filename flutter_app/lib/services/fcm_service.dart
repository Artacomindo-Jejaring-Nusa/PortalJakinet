import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import '../config/constants.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('FCM Background message received: ${message.messageId}');
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  // Callback to trigger automatic UI data refresh on notification
  void Function()? onMessageReceived;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // 1. Initialize Firebase Core
      await Firebase.initializeApp();

      // 2. Set background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 4. Request Notification Permission & Foreground Presentation Options
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      print('FCM Permission Status: ${settings.authorizationStatus}');

      // Initialize Local Notifications for Foreground display
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          print('Local notification clicked with payload: ${response.payload}');
        },
      );

      // Create Android Notification Channels
      // Channel 1: Invoice & Billing
      const AndroidNotificationChannel invoiceChannel = AndroidNotificationChannel(
        'portal_invoice_channel',
        'Tagihan & Invoice',
        description: 'Notifikasi penagihan internet dan terbit invoice',
        importance: Importance.max,
        playSound: true,
      );

      // Channel 2: Chat Customer Support (dengan custom audio chat_notif.mp3)
      const AndroidNotificationChannel chatChannel = AndroidNotificationChannel(
        'portal_chat_channel',
        'Pesan Customer Support',
        description: 'Notifikasi pesan chat dari tim Customer Care',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('chat_notif'),
        enableVibration: true,
      );

      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.createNotificationChannel(invoiceChannel);
      await androidPlugin?.createNotificationChannel(chatChannel);

      // 5. Get FCM Token
      _fcmToken = await _messaging.getToken();
      print('\n==================================================');
      print('?? FCM DEVICE TOKEN FOR TESTING:');
      print('$_fcmToken');
      print('==================================================\n');

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        print('FCM Token Refreshed: $newToken');
      });

      // 6. Listen for Foreground Messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('FCM Foreground Message Received: ${message.notification?.title} - ${message.notification?.body}');
        
        // Trigger auto data refresh callback
        onMessageReceived?.call();

        RemoteNotification? notification = message.notification;
        final data = message.data;
        final isChat = data['type'] == 'chat' || data['room_id'] != null;

        final title = notification?.title ?? data['title'] ?? (isChat ? 'Pesan Customer Support' : 'Tagihan & Invoice');
        final body = notification?.body ?? data['body'] ?? data['message'] ?? 'Ada notifikasi baru';

        final channelId = isChat ? 'portal_chat_channel' : 'portal_invoice_channel';
        final channelName = isChat ? 'Pesan Customer Support' : 'Tagihan & Invoice';

        _localNotifications.show(
          notification.hashCode,
          title,
          body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channelId,
              channelName,
              channelDescription: isChat ? 'Notifikasi pesan chat CS' : 'Notifikasi penagihan internet',
              icon: '@mipmap/launcher_icon',
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
              sound: isChat ? const RawResourceAndroidNotificationSound('chat_notif') : null,
            ),
          ),
          payload: jsonEncode(message.data),
        );
      });

      // 7. Handle click when app opened from background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('FCM Notification Clicked (Background App): ${message.data}');
        onMessageReceived?.call();
      });

      // 8. Handle initial message when app launched from terminated state
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        print('FCM Initial Message (Terminated App): ${initialMessage.data}');
        onMessageReceived?.call();
      }

      _initialized = true;
    } catch (e) {
      print('Error initializing FCMService: $e');
    }
  }

  // Trigger notifikasi suara chat secara lokal (misal saat pesan masuk via WebSocket saat di tab lain)
  Future<void> showChatNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'portal_chat_channel',
            'Pesan Customer Support',
            channelDescription: 'Notifikasi pesan chat CS',
            icon: '@mipmap/launcher_icon',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('chat_notif'),
          ),
        ),
        payload: data != null ? jsonEncode(data) : null,
      );
    } catch (e) {
      print('Error showing chat notification: $e');
    }
  }

  // Register Token to Backend Server
  Future<bool> sendTokenToBackend({
    required String identifier, // Phone or Email or Customer ID
    String? token,
  }) async {
    final tokenToSend = token ?? _fcmToken ?? await _messaging.getToken();
    if (tokenToSend == null || tokenToSend.isEmpty) return false;

    // Multiple potential endpoints (Next.js route & billing API)
    final candidateEndpoints = [
      'https://jpo.jelantik.com/api/customer/fcm-token',
      'http://10.0.2.2:3000/api/customer/fcm-token',
      '${AppConstants.apiBaseUrl}/customer/fcm-token',
    ];

    for (var endpoint in candidateEndpoints) {
      try {
        final url = Uri.parse(endpoint);
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'identifier': identifier,
            'fcm_token': tokenToSend,
            'device_type': 'android',
          }),
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200 || response.statusCode == 201) {
          print('FCM Token successfully registered to endpoint: $endpoint');
          return true;
        }
      } catch (e) {
        // Continue trying next endpoint candidate silently
      }
    }

    print('Note: FCM Token ready locally ($tokenToSend). Backend token registration will sync upon full API deployment.');
    return false;
  }
}
