import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/passage.dart';
import '../../models/review_schedule.dart';
import '../../providers/passage_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/dictionary_service.dart';
import '../../services/srs_service.dart';
import '../../widgets/reading_counter.dart';
import '../../widgets/tappable_text.dart';
import '../../widgets/word_popup.dart';

/// Màn hình đọc chi tiết bài đọc "hôm nay".
///
/// Ghép TappableText (hiển thị + bấm từ), WordPopup (tra nghĩa),
/// ReadingCounter (đếm số lần đọc) và dialog tự đánh giá mức nhớ.
class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  // Không cần đăng ký qua Provider vì DictionaryService không giữ state
  // riêng ngoài việc tự truy cập DatabaseService.instance bên trong.
  final _dictionaryService = DictionaryService();

  @override
  void dispose() {
    // Đảm bảo không để sót popup đang mở khi rời khỏi màn hình.
    WordPopup.hide();
    super.dispose();
  }

  void _handleSegmentTap(PassageSegment segment, Offset globalPosition) {
    WordPopup.show(
      context: context,
      segment: segment,
      globalPosition: globalPosition,
      dictionaryService: _dictionaryService,
    );
  }

  Future<void> _handleMarkRead() async {
    final passageProvider = context.read<PassageProvider>();
    await passageProvider.markReadOnce();

    if (!mounted) return;
    if (passageProvider.hasCompletedTodayReads) {
      await _showRatingDialog();
    }
  }

  Future<void> _showRatingDialog() async {
    final rating = await showDialog<EaseRating>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Bạn nhớ bài này ở mức nào?'),
        content: const Text(
          'Đánh giá này sẽ quyết định khi nào bạn cần ôn lại bài.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, EaseRating.hard),
            child: const Text('Khó / Quên'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, EaseRating.normal),
            child: const Text('Bình thường'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, EaseRating.easy),
            child: const Text('Dễ'),
          ),
        ],
      ),
    );

    if (rating == null || !mounted) return;

    await context.read<PassageProvider>().submitEaseRating(rating);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã lưu! Hẹn gặp lại bạn ở lần ôn tập tiếp theo.'),
      ),
    );
    Navigator.of(context).pop(); // quay lại HomeScreen
  }

  @override
  Widget build(BuildContext context) {
    final passageProvider = context.watch<PassageProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final passage = passageProvider.todayPassage;

    if (passage == null) {
      return const Scaffold(
        body: Center(child: Text('Không có bài đọc nào.')),
      );
    }

    final hasCompletedToday = passageProvider.hasCompletedTodayReads;

    return Scaffold(
      appBar: AppBar(title: Text(passage.title)),
      // evidence-detail-screen: màn hình chi tiết hiển thị nội dung bài
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TappableText(
                segments: passage.segments,
                onSegmentTap: _handleSegmentTap,
                fontSize: settingsProvider.fontSize,
                showPinyin: settingsProvider.showPinyin,
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              ReadingCounter(
                readCount: passageProvider.readCountToday,
                requiredCount: SrsService.requiredReadsPerDay,
                onMarkRead: hasCompletedToday ? null : _handleMarkRead,
              ),
              if (hasCompletedToday) ...[
                const SizedBox(height: 16),
                Text(
                  'Bạn đã đọc đủ số lần hôm nay!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _showRatingDialog,
                  child: const Text('Đánh giá mức nhớ'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
