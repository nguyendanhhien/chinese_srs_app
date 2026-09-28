/// Đánh giá mức độ nhớ mà người dùng tự chọn sau khi đọc đủ số lần trong ngày.
enum EaseRating { easy, normal, hard }

/// Trạng thái hiện tại của một bài đọc, xét theo tiến trình ôn tập.
enum ReviewStatus {
  /// Chưa đọc lần nào.
  newPassage,

  /// Đang đọc trong ngày hôm nay (readCountToday > 0 nhưng chưa đủ 3 lần).
  learning,

  /// Đã hoàn thành ít nhất 1 chu kỳ đọc, đang chờ tới ngày ôn tiếp theo.
  reviewing,
}

/// Các mốc số ngày mặc định cho lịch ôn tập (kiểu SM-2 đơn giản hoá).
/// Dùng trong SrsService ở bước sau, để ở đây cho dễ tham chiếu.
const List<int> defaultIntervalStepsDays = [1, 3, 7, 14, 30];

/// Tiến trình ôn tập (SRS) của MỘT bài đọc, gắn với MỘT người dùng cụ thể.
///
/// Đây là bảng sẽ được lưu trong SQLite (services/database_service.dart).
/// Model này KHÔNG chứa logic tính toán lịch ôn tiếp theo - việc đó thuộc
/// về SrsService, để tách riêng "dữ liệu" và "thuật toán".
class ReviewSchedule {
  final String passageId;
  final String userId;
  final int readCountToday;
  final DateTime? lastReadDate;
  final EaseRating? lastEaseRating;
  final int intervalDays;
  final DateTime? nextReviewDate;
  final ReviewStatus status;

  const ReviewSchedule({
    required this.passageId,
    required this.userId,
    this.readCountToday = 0,
    this.lastReadDate,
    this.lastEaseRating,
    this.intervalDays = 0,
    this.nextReviewDate,
    this.status = ReviewStatus.newPassage,
  });

  /// Tạo lịch ôn tập ban đầu cho một bài đọc vừa được thêm vào (chưa đọc
  /// lần nào). Dùng khi PassageProvider thêm bài mới.
  factory ReviewSchedule.initial({
    required String passageId,
    required String userId,
  }) {
    return ReviewSchedule(passageId: passageId, userId: userId);
  }

  /// Tạo bản sao với một vài trường được thay đổi, giữ nguyên các trường
  /// còn lại. Dùng mỗi khi cần "cập nhật" (vì các trường trên đều là final).
  ReviewSchedule copyWith({
    int? readCountToday,
    DateTime? lastReadDate,
    EaseRating? lastEaseRating,
    int? intervalDays,
    DateTime? nextReviewDate,
    ReviewStatus? status,
  }) {
    return ReviewSchedule(
      passageId: passageId,
      userId: userId,
      readCountToday: readCountToday ?? this.readCountToday,
      lastReadDate: lastReadDate ?? this.lastReadDate,
      lastEaseRating: lastEaseRating ?? this.lastEaseRating,
      intervalDays: intervalDays ?? this.intervalDays,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      status: status ?? this.status,
    );
  }

  factory ReviewSchedule.fromMap(Map<String, Object?> map) {
    return ReviewSchedule(
      passageId: map['passageId'] as String,
      userId: map['userId'] as String,
      readCountToday: map['readCountToday'] as int? ?? 0,
      lastReadDate: map['lastReadDate'] == null
          ? null
          : DateTime.parse(map['lastReadDate'] as String),
      lastEaseRating: map['lastEaseRating'] == null
          ? null
          : EaseRating.values.byName(map['lastEaseRating'] as String),
      intervalDays: map['intervalDays'] as int? ?? 0,
      nextReviewDate: map['nextReviewDate'] == null
          ? null
          : DateTime.parse(map['nextReviewDate'] as String),
      status: ReviewStatus.values.byName(map['status'] as String),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'passageId': passageId,
      'userId': userId,
      'readCountToday': readCountToday,
      'lastReadDate': lastReadDate?.toIso8601String(),
      'lastEaseRating': lastEaseRating?.name,
      'intervalDays': intervalDays,
      'nextReviewDate': nextReviewDate?.toIso8601String(),
      'status': status.name,
    };
  }
}
