import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// State management cho các cài đặt của người dùng.
///
/// Lưu qua SharedPreferences (key-value đơn giản) - khác với bài đọc và
/// tiến trình ôn tập (lưu trong SQLite qua DatabaseService), vì đây chỉ
/// là các tuỳ chọn nhỏ, không cần truy vấn phức tạp.
class SettingsProvider extends ChangeNotifier {
  static const _keyDailyPassageCount = 'dailyPassageCount';
  static const _keyReminderHour = 'reminderHour';
  static const _keyReminderMinute = 'reminderMinute';
  static const _keyFontSize = 'fontSize';
  static const _keyShowPinyin = 'showPinyin';

  int _dailyPassageCount = 1;
  int _reminderHour = 20; // mặc định: nhắc lúc 20:00
  int _reminderMinute = 0;
  double _fontSize = 20.0;
  bool _showPinyin = true;
  bool _isLoaded = false;

  int get dailyPassageCount => _dailyPassageCount;
  int get reminderHour => _reminderHour;
  int get reminderMinute => _reminderMinute;
  double get fontSize => _fontSize;
  bool get showPinyin => _showPinyin;

  /// true sau khi loadSettings() đã đọc xong dữ liệu đã lưu từ trước.
  /// UI (SettingsScreen) nên chờ giá trị này = true rồi mới hiển thị,
  /// tránh nháy giá trị mặc định rồi đổi sang giá trị thật đã lưu.
  bool get isLoaded => _isLoaded;

  /// Đọc lại toàn bộ cài đặt đã lưu từ trước. Gọi một lần khi app khởi động.
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _dailyPassageCount = prefs.getInt(_keyDailyPassageCount) ?? 1;
    _reminderHour = prefs.getInt(_keyReminderHour) ?? 20;
    _reminderMinute = prefs.getInt(_keyReminderMinute) ?? 0;
    _fontSize = prefs.getDouble(_keyFontSize) ?? 20.0;
    _showPinyin = prefs.getBool(_keyShowPinyin) ?? true;
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> updateDailyPassageCount(int value) async {
    _dailyPassageCount = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDailyPassageCount, value);
  }

  /// Cập nhật giờ nhắc học. Lưu ý: chỉ đổi GIÁ TRỊ cài đặt ở đây - việc đặt
  /// lại lịch thông báo thật (gọi NotificationService.scheduleDailyReminder)
  /// sẽ do SettingsScreen chủ động gọi sau khi hàm này chạy xong.
  Future<void> updateReminderTime({
    required int hour,
    required int minute,
  }) async {
    _reminderHour = hour;
    _reminderMinute = minute;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyReminderHour, hour);
    await prefs.setInt(_keyReminderMinute, minute);
  }

  Future<void> updateFontSize(double value) async {
    _fontSize = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyFontSize, value);
  }

  Future<void> updateShowPinyin(bool value) async {
    _showPinyin = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowPinyin, value);
  }
}
