import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PushNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _notificationsPlugin.initialize(initSettings);
    } catch (_) {}
  }

  static Future<void> showNotification({required String title, required String body}) async {
    const androidDetails = AndroidNotificationDetails(
      'hepsiradyo_general_channel',
      'HepsiRadyo Duyurular',
      channelDescription: 'Özel yayın ve radyo duyuruları',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

    try {
      await _notificationsPlugin.show(0, title, body, details);
    } catch (_) {}
  }
}
