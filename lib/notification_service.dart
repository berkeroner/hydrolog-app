import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
    );
  }

  Future<void> scheduleWaterReminders({
    required int startHour,
    required int endHour,
    required int intervalHours,
  }) async {
    // Önceki tüm hatırlatıcıları temizle
    await flutterLocalNotificationsPlugin.cancelAll();

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'hydrolog_reminders',
      'Su Hatırlatıcıları',
      channelDescription: 'Su içmeyi hatırlatan bildirimler',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(),
    );

    int id = 0;
    final now = tz.TZDateTime.now(tz.local);

    // Başlangıç saatinden bitiş saatine kadar, belirtilen aralıkla döngü
    for (int hour = startHour; hour <= endHour; hour += intervalHours) {
      tz.TZDateTime scheduledDate =
          tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);

      // Eğer seçilen saat bugünü geçmişse, yarına ayarla
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      // Her gün aynı saatte tekrar etmesi için ayarlıyoruz
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id: id++,
        title: 'Su İçme Vakti!',
        body: 'Hedefine ulaşmak için bir bardak su içmeyi unutma 💧',
        scheduledDate: scheduledDate,
        notificationDetails: platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> cancelAllReminders() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
