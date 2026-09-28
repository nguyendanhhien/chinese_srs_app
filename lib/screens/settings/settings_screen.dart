import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/notification_service.dart';

/// Màn hình cài đặt.
///
/// Gộp chung "menu cài đặt" và "màn hình cài đặt" thành MỘT danh sách -
/// đây là cách làm tự nhiên trong Flutter (mỗi mục có control riêng ngay
/// tại chỗ), thay vì tách thành nhiều màn hình con.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _pickReminderTime(SettingsProvider settingsProvider) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: settingsProvider.reminderHour,
        minute: settingsProvider.reminderMinute,
      ),
    );
    if (picked == null) return;

    await settingsProvider.updateReminderTime(
      hour: picked.hour,
      minute: picked.minute,
    );

    // TODO: khi có bước tổng hợp "tổng số bài đến hạn ôn trên toàn bộ kho",
    // thay 0 bằng con số thực tế thay vì giá trị tạm thời này.
    await NotificationService.instance.scheduleDailyReminder(
      hour: picked.hour,
      minute: picked.minute,
      duePassageCount: 0,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã đặt giờ nhắc học: ${picked.format(context)}'),
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    await context.read<AuthProvider>().logout();
    if (mounted) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();

    if (!settingsProvider.isLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      // evidence-menu-items + evidence-settings-screen: danh sách các mục
      // cài đặt hiển thị trên cùng một màn hình.
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.menu_book),
            title: const Text('Số bài học mỗi ngày'),
            subtitle: Text('${settingsProvider.dailyPassageCount} bài/ngày'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: settingsProvider.dailyPassageCount > 1
                      ? () => settingsProvider.updateDailyPassageCount(
                          settingsProvider.dailyPassageCount - 1,
                        )
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => settingsProvider.updateDailyPassageCount(
                    settingsProvider.dailyPassageCount + 1,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.alarm),
            title: const Text('Giờ nhắc học'),
            subtitle: Text(
              '${settingsProvider.reminderHour.toString().padLeft(2, '0')}:'
              '${settingsProvider.reminderMinute.toString().padLeft(2, '0')}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickReminderTime(settingsProvider),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.format_size),
            title: const Text('Cỡ chữ'),
            subtitle: Slider(
              value: settingsProvider.fontSize,
              min: 14,
              max: 32,
              divisions: 9,
              label: settingsProvider.fontSize.round().toString(),
              onChanged: settingsProvider.updateFontSize,
            ),
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.translate),
            title: const Text('Hiển thị pinyin'),
            value: settingsProvider.showPinyin,
            onChanged: settingsProvider.updateShowPinyin,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Đăng xuất',
              style: TextStyle(color: Colors.red),
            ),
            onTap: _handleLogout,
          ),
        ],
      ),
    );
  }
}
