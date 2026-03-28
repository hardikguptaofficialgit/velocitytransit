import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../data/models.dart';
import '../providers/auth_provider.dart';
import '../router/app_router.dart';
import 'backend_api_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: AppConfig.firebaseOptions);
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const _channelId = 'trip_updates';
  static const _channelName = 'Trip Updates';
  static const _channelDescription = 'Live trip and transit status alerts';
  static const _muteKey = 'alerts_muted';

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _alertsMuted = false;

  Future<void> initialize({
    required AuthService authService,
    required AppRoleChoice role,
  }) async {
    if (_initialized) {
      await syncToken(authService: authService, role: role);
      return;
    }

    _alertsMuted = await _readMutedState();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _handleLocalNotificationResponse,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDescription,
            importance: Importance.max,
            playSound: true,
          ),
        );

    await _messaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    await syncToken(authService: authService, role: role);

    FirebaseMessaging.onMessage.listen((message) async {
      if (_alertsMuted) return;
      await _showRemoteMessage(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen(_handleRemoteNavigation);
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleRemoteNavigation(initialMessage);
    }

    _messaging.onTokenRefresh.listen((token) async {
      try {
        await _storeCurrentFcmToken(token);
        await BackendApiService(authService: authService).syncFcmToken(
          token: token,
          role: role,
        );
      } catch (_) {}
    });

    _initialized = true;
  }

  Future<void> syncToken({
    required AuthService authService,
    required AppRoleChoice role,
  }) async {
    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;
    await _storeCurrentFcmToken(token);
    await BackendApiService(authService: authService).syncFcmToken(
      token: token,
      role: role,
    );
  }

  Future<void> showOrUpdateTripNotification({
    required String busId,
    required String title,
    required String body,
    required Map<String, dynamic> payload,
  }) async {
    if (_alertsMuted) return;
    await _localNotifications.show(
      busId.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.status,
          ongoing: true,
          autoCancel: false,
          actions: const [
            AndroidNotificationAction('view_route', 'View Route'),
            AndroidNotificationAction('stop_alerts', 'Stop Alerts'),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.active,
        ),
      ),
      payload: jsonEncode(payload),
    );
  }

  Future<void> cancelTripNotification(String busId) async {
    await _localNotifications.cancel(busId.hashCode);
  }

  Future<void> setAlertsMuted(bool muted) async {
    _alertsMuted = muted;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_muteKey, muted);
  }

  Future<bool> _readMutedState() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_muteKey) ?? false;
  }

  Future<void> _showRemoteMessage(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;
    final title = notification?.title ?? data['title']?.toString() ?? 'Transit update';
    final body = notification?.body ?? data['body']?.toString() ?? 'Tap to open.';
    final busId = data['busId']?.toString() ?? title;

    await _localNotifications.show(
      busId.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.high,
          actions: const [
            AndroidNotificationAction('view_route', 'View Route'),
            AndroidNotificationAction('stop_alerts', 'Stop Alerts'),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(data),
    );
  }

  static Future<void> _handleLocalNotificationResponse(
    NotificationResponse response,
  ) async {
    if (response.actionId == 'stop_alerts') {
      await NotificationService.instance.setAlertsMuted(true);
      return;
    }

    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      NotificationService.instance._navigateFromPayload(payload);
    }
  }

  void _handleRemoteNavigation(RemoteMessage message) {
    _navigateFromPayload(jsonEncode(message.data));
  }

  Future<void> _storeCurrentFcmToken(String token) async {
    await FirebaseFirestore.instance
        .collection('_client_state')
        .doc('fcm')
        .set({'token': token}, SetOptions(merge: true));
  }

  void _navigateFromPayload(String payload) {
    try {
      final decoded = jsonDecode(payload) as Map<String, dynamic>;
      final navigator = appNavigatorKey.currentState;
      if (navigator == null) return;

      final busId = decoded['busId']?.toString();
      final routeId = decoded['routeId']?.toString();

      if (busId != null && busId.isNotEmpty) {
        navigator.pushNamed(AppRouter.liveTracking, arguments: busId);
        return;
      }
      if (routeId != null && routeId.isNotEmpty) {
        navigator.pushNamed(AppRouter.routeDetails, arguments: routeId);
      }
    } catch (_) {}
  }
}
