import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> setupNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

// Define a constant notification ID
const int notificationId = 0;

Future<void> showNotification(String title, String body) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'background_service_channel',
    'Background Service',
    channelDescription: 'Notification for background service',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
    ongoing:
        false, // Ongoing notification (prevents the user from swiping it away)
  );

  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  // Show or update the notification with the same ID
  await flutterLocalNotificationsPlugin.show(
    notificationId, // Use a fixed ID to update the notification
    title,
    body,
    platformChannelSpecifics,
  );
}
