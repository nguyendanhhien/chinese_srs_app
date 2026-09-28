import '../models/review_schedule.dart';

/// Thuật toán lặp lại ngắt quãng (Spaced Repetition), kiểu SM-2 rút gọn.
///
/// Đây là LOGIC THUẦN: không đụng tới database, không đụng tới UI.
/// SrsService chỉ nhận một ReviewSchedule + một hành động (đọc 1 lần,
/// hoặc đánh giá mức nhớ) và trả về ReviewSchedule MỚI - không tự lưu
/// gì cả. Việc lưu do PassageProvider + DatabaseService đảm nhiệm.
class SrsService {
  /// Số lần cần đọc trong một ngày trước khi được phép tự đánh giá mức nhớ.
  static const int requiredReadsPerDay = 3;

  /// Ghi nhận một lượt đọc trong ngày hôm nay.
  ///
  /// Nếu lần đọc gần nhất KHÔNG phải hôm nay (sang ngày mới), bộ đếm
  /// readCountToday sẽ được reset về 1 (bắt đầu đếm lại từ đầu).
  ReviewSchedule recordRead(ReviewSchedule schedule, DateTime now) {
    final isNewDay = schedule.lastReadDate == null ||
        !_isSameDay(schedule.lastReadDate!, now);

    final newCount = isNewDay ? 1 : schedule.readCountToday + 1;

    return schedule.copyWith(
      readCountToday: newCount,
      lastReadDate: now,
      status: ReviewStatus.learning,
    );
  }

  /// Người dùng đã đọc đủ số lần yêu cầu trong ngày hôm nay chưa
  /// (đủ điều kiện để hiện dialog tự đánh giá mức nhớ).
  bool hasCompletedTodayReads(ReviewSchedule schedule) {
    return schedule.readCountToday >= requiredReadsPerDay;
  }

  /// Tính lịch ôn tập MỚI dựa trên đánh giá mức nhớ của người dùng.
  ///
  /// Quy tắc:
  /// - "hard" (khó/quên) -> quay lại mốc đầu tiên (1 ngày), coi như học lại từ đầu
  /// - "normal" (bình thường) -> tiến lên MỘT mốc kế tiếp trong [defaultIntervalStepsDays]
  /// - "easy" (dễ) -> tiến lên HAI mốc kế tiếp (thưởng vì nhớ tốt, giãn cách xa hơn)
  /// - Không bao giờ vượt quá mốc cuối cùng trong danh sách (30 ngày)
  ReviewSchedule calculateNextReview(
    ReviewSchedule current,
    EaseRating rating,
    DateTime now,
  ) {
    late final int nextIntervalDays;

    if (rating == EaseRating.hard) {
      nextIntervalDays = defaultIntervalStepsDays.first;
    } else {
      final currentIndex = defaultIntervalStepsDays.indexOf(
        current.intervalDays,
      );
      // Nếu interval hiện tại không khớp mốc nào (VD: bài hoàn toàn mới,
      // intervalDays = 0), coi như đang ở "trước mốc đầu tiên".
      final baseIndex = currentIndex == -1 ? -1 : currentIndex;
      final step = rating == EaseRating.easy ? 2 : 1;
      final nextIndex = (baseIndex + step).clamp(
        0,
        defaultIntervalStepsDays.length - 1,
      );
      nextIntervalDays = defaultIntervalStepsDays[nextIndex];
    }

    final today = DateTime(now.year, now.month, now.day);
    final nextReviewDate = today.add(Duration(days: nextIntervalDays));

    return current.copyWith(
      intervalDays: nextIntervalDays,
      nextReviewDate: nextReviewDate,
      lastEaseRating: rating,
      readCountToday: 0, // reset để chuẩn bị cho chu kỳ đọc tiếp theo
      status: ReviewStatus.reviewing,
    );
  }

  /// Bài này có "đến hạn ôn tập hôm nay" không?
  /// Bài hoàn toàn mới (newPassage) luôn được coi là đủ điều kiện học.
  bool isDueForReview(ReviewSchedule schedule, DateTime now) {
    if (schedule.status == ReviewStatus.newPassage) return true;
    if (schedule.nextReviewDate == null) return false;

    final today = DateTime(now.year, now.month, now.day);
    return !schedule.nextReviewDate!.isAfter(today);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
