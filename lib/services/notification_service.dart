import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Quản lý thông báo nhắc học hằng ngày.
///
/// Dùng Singleton giống DatabaseService: toàn app chỉ có một đối tượng
/// quản lý thông báo duy nhất.
class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Khởi tạo plugin thông báo + dữ liệu múi giờ.
  /// Gọi một lần duy nhất, thường là trong main.dart lúc khởi động app.
  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);
    _initialized = true;
  }

  /// Xin quyền hiển thị thông báo (bắt buộc trên Android 13+ và iOS).
  /// Gọi sau initialize(), thường ngay khi người dùng vào Settings lần đầu
  /// hoặc ngay sau khi đăng nhập thành công.
  Future<void> requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Đặt lịch nhắc học lặp lại MỖI NGÀY vào đúng [hour]:[minute].
  /// [duePassageCount] là số bài đến hạn ôn TẠI THỜI ĐIỂM đặt lịch - dùng để
  /// hiện số lượng trong nội dung thông báo (PassageProvider sẽ tính số này
  /// mỗi khi Settings được cập nhật).
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    required int duePassageCount,
  }) async {
    await initialize();

    final scheduledDate = _nextInstanceOfTime(hour, minute);

    await _plugin.zonedSchedule(
      _dailyReminderNotificationId,
      'Đến giờ ôn tập tiếng Trung!',
      duePassageCount > 0
          ? 'Bạn có $duePassageCount bài cần ôn hôm nay.'
          : 'Hãy vào app đọc một bài mới hôm nay nhé.',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder_channel',
          'Nhắc học hằng ngày',
          channelDescription: 'Thông báo nhắc ôn tập/đọc bài mỗi ngày',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // lặp lại mỗi ngày
    );
  }

  Future<void> cancelDailyReminder() async {
    await _plugin.cancel(_dailyReminderNotificationId);
  }

  /// Gửi ngay một thông báo thử nghiệm - dùng để chụp ảnh
  /// evidence-notification-alert (chứng minh thông báo hoạt động thật).
  Future<void> showTestNotification() async {
    await initialize();

    await _plugin.show(
      _testNotificationId,
      'Thông báo thử nghiệm',
      'Nếu bạn thấy thông báo này, tính năng nhắc học đã hoạt động!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel',
          'Thông báo thử nghiệm',
          channelDescription: 'Dùng để kiểm tra tính năng thông báo',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Nếu giờ đã đặt hôm nay đã trôi qua rồi, dời sang đúng giờ đó của
    // ngày mai (để lịch nhắc "hằng ngày" luôn có một mốc kế tiếp hợp lệ).
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  static const int _dailyReminderNotificationId = 0;
  static const int _testNotificationId = 1;
}