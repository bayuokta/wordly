import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Pengingat harian memakai `flutter_local_notifications` (lokal, tanpa server).
class NotificationService {
  NotificationService._(this._plugin);

  static const int dailyId = 1001;
  static const String channelId = 'daily_reminder';

  final FlutterLocalNotificationsPlugin _plugin;
  bool _timezoneReady = false;

  static Future<NotificationService> create() async {
    final plugin = FlutterLocalNotificationsPlugin();
    tzdata.initializeTimeZones();

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await plugin.initialize(settings: settings);

    final service = NotificationService._(plugin);
    await service._setupTimezone();
    return service;
  }

  Future<void> _setupTimezone() async {
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
      _timezoneReady = true;
    } on Object {
      // Fallback: zona waktu perangkat tidak terbaca → pakai default paket.
      _timezoneReady = false;
    }
  }

  /// Meminta izin notifikasi (Android 13+). Mengembalikan `true` bila diizinkan.
  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;
    return await android.requestNotificationsPermission() ?? false;
  }

  /// Menjadwalkan pengingat harian pada [minutes] sejak tengah malam.
  Future<void> scheduleDaily({required int minutes, required String body}) async {
    if (!_timezoneReady) await _setupTimezone();
    await cancelDaily();

    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      minutes ~/ 60,
      minutes % 60,
    );
    if (!next.isAfter(now)) {
      next = next.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: dailyId,
      title: 'Waktunya belajar',
      body: body,
      scheduledDate: next,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          'Pengingat harian',
          channelDescription: 'Pengingat belajar kosakata setiap hari',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDaily() => _plugin.cancel(id: dailyId);

  /// Notifikasi percobaan agar pengguna langsung melihat hasilnya.
  Future<void> showTest() => _plugin.show(
    id: dailyId + 1,
    title: 'Notifikasi aktif',
    body: 'Kamu akan diingatkan setiap hari pada jam yang dipilih.',
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        'Pengingat harian',
        channelDescription: 'Pengingat belajar kosakata setiap hari',
      ),
    ),
  );
}

/// Diisi di `main()` setelah layanan diinisialisasi.
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => throw StateError('NotificationService belum di-bootstrap'),
);
