import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    // Fallback/Set local location ke Asia/Jakarta (WIB)
    try {
      final jakarta = tz.getLocation('Asia/Jakarta');
      tz.setLocalLocation(jakarta);
    } catch (e) {
      print("Timezone error: $e");
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
    );

    // Sinkronisasi status jadwal saat aplikasi dibuka
    final prefs = await SharedPreferences.getInstance();
    final bool enabled = prefs.getBool('absen_reminder_enabled') ?? false;
    if (enabled) {
      await scheduleReminders();
    }
  }

  static Future<void> requestPermissions() async {
    // Android 13+
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }

    // iOS
    final iosImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (iosImplementation != null) {
      await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  static Future<void> scheduleReminders() async {
    // Batalkan jadwal lama agar tidak ganda
    await cancelReminders();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'absen_reminder_channel',
      'Pengingat Absen',
      channelDescription: 'Menampilkan pengingat absen masuk 30 menit sebelum jam kerja',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    // Jadwalkan pengingat absen pukul 07:30 (30 menit sebelum jam 08:00) untuk hari kerja (Senin s/d Jumat)
    for (int day = 1; day <= 5; day++) {
      try {
        final scheduledTime = _nextInstanceOfDayOfWeek(day, 7, 30);
        await _notificationsPlugin.zonedSchedule(
          id: day,
          title: 'Pengingat Absen Masuk',
          body: 'Sudah pukul 07:30! Jangan lupa untuk melakukan absen masuk 30 menit lagi.',
          scheduledDate: scheduledTime,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      } catch (e) {
        print("Gagal menjadwalkan notifikasi untuk hari $day: $e");
      }
    }
  }

  static Future<void> cancelReminders() async {
    // Batalkan seluruh notifikasi berjadwal dengan ID 1 sampai 5
    for (int day = 1; day <= 5; day++) {
      await _notificationsPlugin.cancel(id: day);
    }
  }

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('absen_reminder_enabled') ?? false;
  }

  static Future<void> setEnabled(bool enable) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('absen_reminder_enabled', enable);
    if (enable) {
      await requestPermissions();
      await scheduleReminders();
    } else {
      await cancelReminders();
    }
  }

  static tz.TZDateTime _nextInstanceOfDayOfWeek(int dayOfWeek, int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now) || scheduledDate.weekday != dayOfWeek) {
      do {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      } while (scheduledDate.weekday != dayOfWeek);
    }
    return scheduledDate;
  }
}
