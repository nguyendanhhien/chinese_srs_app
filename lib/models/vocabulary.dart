/// Một mục từ điển, dùng khi người dùng bấm vào một từ trong bài đọc
/// để tra nghĩa (thông qua DictionaryService).
///
/// [meaningVi] là nghĩa tiếng Việt, ưu tiên hiển thị trước - do mình tự
/// soạn cho các bài đọc mẫu (builtin).
///
/// [meaningEn] là nghĩa tiếng Anh, dùng làm phương án DỰ PHÒNG khi
/// [meaningVi] chưa có sẵn - ví dụ với chữ Hán xuất hiện trong bài lấy
/// từ API mà từ điển mini (tự soạn) chưa kịp bổ sung nghĩa Việt.
/// Nguồn dữ liệu cho [meaningEn] dự kiến là CC-CEDICT.
class VocabularyEntry {
  final String hanzi;
  final String pinyin;
  final String? meaningVi;
  final String? meaningEn;

  const VocabularyEntry({
    required this.hanzi,
    required this.pinyin,
    this.meaningVi,
    this.meaningEn,
  }) : assert(
          meaningVi != null || meaningEn != null,
          'Phải có ít nhất một trong hai: meaningVi hoặc meaningEn',
        );

  /// Nghĩa sẽ thực sự hiển thị lên popup: ưu tiên tiếng Việt,
  /// nếu không có thì rơi về tiếng Anh.
  String get displayMeaning => meaningVi ?? meaningEn!;

  factory VocabularyEntry.fromJson(Map<String, dynamic> json) {
    return VocabularyEntry(
      hanzi: json['hanzi'] as String,
      pinyin: json['pinyin'] as String,
      meaningVi: json['meaningVi'] as String?,
      meaningEn: json['meaningEn'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hanzi': hanzi,
      'pinyin': pinyin,
      if (meaningVi != null) 'meaningVi': meaningVi,
      if (meaningEn != null) 'meaningEn': meaningEn,
    };
  }
}
