import 'package:pinyin/pinyin.dart';

import 'database_service.dart';

/// Kết quả tra một chữ/từ, dùng để hiển thị trong WordPopup.
///
/// [meaning] có thể null khi từ đó chưa có trong từ điển mini VÀ chưa
/// tích hợp CC-CEDICT (xem TODO trong DictionaryService) - lúc đó UI nên
/// hiển thị "chưa có nghĩa" thay vì để trống hoặc báo lỗi.
class DictionaryLookupResult {
  final String hanzi;
  final String pinyin;
  final String? meaning;

  const DictionaryLookupResult({
    required this.hanzi,
    required this.pinyin,
    this.meaning,
  });

  bool get hasMeaning => meaning != null;
}

/// Tra nghĩa một từ khi người dùng bấm vào trong DetailScreen.
///
/// Thứ tự ưu tiên:
/// 1. Từ điển mini (SQLite, bảng "vocabulary") - nghĩa tiếng Việt, do mình
///    tự soạn kèm theo các bài đọc mẫu.
/// 2. TODO (bước sau): nếu không có ở (1), tra tiếp trong bảng CC-CEDICT
///    (nghĩa tiếng Anh) - dành cho chữ Hán xuất hiện trong bài lấy từ API.
///    Hiện tại bước này CHƯA làm, nên khi không tìm thấy ở (1), service
///    chỉ tự tính pinyin và trả về meaning = null.
class DictionaryService {
  DictionaryService({DatabaseService? databaseService})
      : _databaseService = databaseService ?? DatabaseService.instance;

  final DatabaseService _databaseService;

  Future<DictionaryLookupResult> lookup(String hanzi) async {
    final entry = await _databaseService.lookupVocabulary(hanzi);

    if (entry != null) {
      return DictionaryLookupResult(
        hanzi: hanzi,
        pinyin: entry.pinyin,
        meaning: entry.displayMeaning,
      );
    }

    // Không có trong từ điển mini -> tự tính pinyin, tạm chưa có nghĩa.
    final computedPinyin = PinyinHelper.getPinyin(hanzi, separator: ' ');

    return DictionaryLookupResult(
      hanzi: hanzi,
      pinyin: computedPinyin,
      meaning: null,
    );
  }
}
