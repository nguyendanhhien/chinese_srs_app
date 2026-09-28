import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/review_schedule.dart';
import '../../providers/auth_provider.dart';
import '../../providers/passage_provider.dart';

/// Màn hình chính: hiển thị bài đọc của "hôm nay" (bài đến hạn ôn tập,
/// hoặc bài mới nếu không có bài nào đến hạn).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Gọi sau khi frame đầu tiên đã render xong, vì cần dùng context
    // để đọc provider bên trong initState.
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTodayPassage());
  }

  Future<void> _loadTodayPassage() async {
    final userId = context.read<AuthProvider>().currentUser?.uid;
    if (userId == null) return;
    await context.read<PassageProvider>().loadTodayPassage(userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Logo trong header (evidence: home-screen-evidence)
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_rounded, size: 28),
            SizedBox(width: 8),
            Text('Đọc Tiếng Trung'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Cài đặt',
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
          ),
        ],
      ),
      body: Consumer<PassageProvider>(
        builder: (context, passageProvider, _) {
          if (passageProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (passageProvider.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      passageProvider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadTodayPassage,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          final passage = passageProvider.todayPassage;
          final schedule = passageProvider.todaySchedule;

          if (passage == null || schedule == null) {
            return const Center(child: Text('Chưa có bài đọc nào.'));
          }

          final isNew = schedule.status == ReviewStatus.newPassage;

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Bài đọc hôm nay',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          passage.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Chip(
                          label: Text(isNew ? 'Bài mới' : 'Cần ôn tập'),
                          backgroundColor: isNew
                              ? Colors.blue.shade50
                              : Colors.orange.shade50,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Đã đọc hôm nay: '
                          '${passageProvider.readCountToday}/3 lần',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Nút + icon điều hướng sang màn hình chi tiết
                // (evidence: evidence-detail-navigation)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/detail');
                  },
                  icon: const Icon(Icons.menu_book),
                  label: const Text('Bắt đầu đọc'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
