import 'package:flutter/foundation.dart';

import '../models/passage.dart';
import '../models/review_schedule.dart';
import '../services/database_service.dart';
import '../services/passage_api_service.dart';
import '../services/srs_service.dart';

/// State management cho bài đọc + tiến trình ôn tập (SRS).
///
/// Là "cầu nối" giữa HomeScreen/DetailScreen và ba service:
/// DatabaseService (lưu trữ), SrsService (thuật toán), PassageApiService
/// (lấy thêm bài khi cần).
///
/// Lưu ý: các hàm ở đây nhận [userId] làm tham số thay vì tự đọc từ
/// AuthProvider, để PassageProvider không phụ thuộc trực tiếp vào
/// AuthProvider (tránh provider phụ thuộc chéo lẫn nhau). Màn hình gọi
/// hàm sẽ tự lấy userId từ AuthProvider rồi truyền vào.
class PassageProvider extends ChangeNotifier {
  PassageProvider({
    DatabaseService? databaseService,
    SrsService? srsService,
    PassageApiService? passageApiService,
  })  : _databaseService = databaseService ?? DatabaseService.instance,
        _srsService = srsService ?? SrsService(),
        _passageApiService = passageApiService ?? PassageApiService();

  final DatabaseService _databaseService;
  final SrsService _srsService;
  final PassageApiService _passageApiService;

  Passage? _todayPassage;
  Passage? get todayPassage => _todayPassage;

  ReviewSchedule? _todaySchedule;
  ReviewSchedule? get todaySchedule => _todaySchedule;

  int get readCountToday => _todaySchedule?.readCountToday ?? 0;

  bool get hasCompletedTodayReads =>
      _todaySchedule != null &&
      _srsService.hasCompletedTodayReads(_todaySchedule!);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Tìm bài đọc của "hôm nay" cho [userId], theo đúng thứ tự ưu tiên:
  /// 1. Bài đã đến hạn ôn tập (status = reviewing, nextReviewDate <= hôm nay)
  /// 2. Bài hoàn toàn mới, chưa từng có lịch ôn tập nào
  /// 3. Nếu kho không còn bài nào ở (1) và (2) -> tự động lấy thêm từ API
  Future<void> loadTodayPassage(String userId) async {
    _setLoading(true);
    try {
      final now = DateTime.now();
      final allPassages = await _databaseService.getAllPassages();
      final allSchedules = await _databaseService.getAllReviewSchedules(
        userId,
      );
      final scheduleByPassageId = {
        for (final s in allSchedules) s.passageId: s,
      };

      Passage? chosenPassage;
      ReviewSchedule? chosenSchedule;

      // Bước 1: tìm bài đã đến hạn ôn tập
      for (final passage in allPassages) {
        final schedule = scheduleByPassageId[passage.id];
        if (schedule != null && _srsService.isDueForReview(schedule, now)) {
          chosenPassage = passage;
          chosenSchedule = schedule;
          break;
        }
      }

      // Bước 2: không có bài đến hạn -> tìm bài hoàn toàn mới
      if (chosenPassage == null) {
        for (final passage in allPassages) {
          if (!scheduleByPassageId.containsKey(passage.id)) {
            chosenPassage = passage;
            chosenSchedule = ReviewSchedule.initial(
              passageId: passage.id,
              userId: userId,
            );
            break;
          }
        }
      }

      // Bước 3: kho hết sạch -> lấy thêm 1 bài mới từ API
      if (chosenPassage == null) {
        chosenPassage = await _fetchAndStoreNewPassageFromApi();
        chosenSchedule = ReviewSchedule.initial(
          passageId: chosenPassage.id,
          userId: userId,
        );
      }

      _todayPassage = chosenPassage;
      _todaySchedule = chosenSchedule;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Không thể tải bài đọc hôm nay. Vui lòng thử lại.';
    } finally {
      _setLoading(false);
    }
  }

  Future<Passage> _fetchAndStoreNewPassageFromApi() async {
    final passage = await _passageApiService.fetchRandomPassage();
    await _databaseService.insertPassage(passage);
    return passage;
  }

  /// Ghi nhận một lượt đọc bài "hôm nay" (gọi mỗi khi người dùng đọc xong
  /// một lượt trong DetailScreen).
  Future<void> markReadOnce() async {
    if (_todaySchedule == null) return;

    final updated = _srsService.recordRead(_todaySchedule!, DateTime.now());
    await _databaseService.upsertReviewSchedule(updated);

    _todaySchedule = updated;
    notifyListeners();
  }

  /// Người dùng tự đánh giá mức nhớ sau khi đọc đủ số lần yêu cầu trong
  /// ngày -> tính và lưu lại lịch ôn tập tiếp theo.
  Future<void> submitEaseRating(EaseRating rating) async {
    if (_todaySchedule == null) return;

    final updated = _srsService.calculateNextReview(
      _todaySchedule!,
      rating,
      DateTime.now(),
    );
    await _databaseService.upsertReviewSchedule(updated);

    _todaySchedule = updated;
    notifyListeners();
  }

  /// Chủ động lấy thêm 1 bài mới từ API (ví dụ khi người dùng bấm nút
  /// "Lấy thêm bài đọc" trong Settings hoặc Home, không phải tự động).
  Future<void> fetchMoreFromApi() async {
    _setLoading(true);
    try {
      await _fetchAndStoreNewPassageFromApi();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Không thể lấy bài mới từ API. Kiểm tra kết nối mạng.';
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
