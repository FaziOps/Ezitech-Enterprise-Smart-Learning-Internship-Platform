import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Top-level function required by firebase_messaging for background
/// message handling — must NOT be a class method (the plugin invokes it
/// in a separate isolate).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Intentionally minimal: heavy work here delays background delivery.
  // Local notification display for foreground messages happens in
  // FcmService._onForegroundMessage instead.
}

/// Wraps Firebase Messaging + flutter_local_notifications.
///
/// IMPORTANT: this whole service is a no-op if Firebase hasn't been
/// initialized (no google-services.json / GoogleService-Info.plist —
/// see README API table #9). Every public method checks [_available]
/// first and fails soft, so the rest of the app never has to know
/// whether push notifications are actually configured. Once the Firebase
/// project files are added and `Firebase.initializeApp()` succeeds in
/// main.dart, this activates automatically with no code changes here.
class FcmService {
  FcmService() : _localNotifications = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _localNotifications;
  final _messageController = StreamController<RemoteMessage>.broadcast();

  Stream<RemoteMessage> get onMessage => _messageController.stream;

  bool get _available => Firebase.apps.isNotEmpty;

  Future<void> initialize() async {
    if (!_available) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_messageController.add);
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    _messageController.add(message);
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'ezitech_default',
          'Ezitech Notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<String?> getToken() async {
    if (!_available) return null;
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (_) {
      return null;
    }
  }

  void dispose() => _messageController.close();
}
