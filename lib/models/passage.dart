/// Một "khối từ" trong đoạn văn - đơn vị nhỏ nhất có thể bấm vào để tra nghĩa.
///
/// Ví dụ: chữ Hán "学习" là MỘT segment (một từ), không phải hai chữ riêng lẻ.
class PassageSegment {
  final String hanzi; // chữ Hán, ví dụ: "学习"
  final String pinyin; // phiên âm, ví dụ: "xué xí"
  final String meaningVi; // nghĩa tiếng Việt, ví dụ: "học tập"

  const PassageSegment({
    required this.hanzi,
    required this.pinyin,
    required this.meaningVi,
  });

  factory PassageSegment.fromJson(Map<String, dynamic> json) {
    return PassageSegment(
      hanzi: json['hanzi'] as String,
      pinyin: json['pinyin'] as String,
      meaningVi: json['meaningVi'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hanzi': hanzi,
      'pinyin': pinyin,
      'meaningVi': meaningVi,
    };
  }
}

/// Nguồn gốc của bài đọc: bài mẫu có sẵn trong app, hay lấy từ API ngoài.
enum PassageSource { builtin, api }

/// Một bài đọc tiếng Trung hoàn chỉnh (~1000 chữ).
class Passage {
  final String id;
  final String title;
  final List<PassageSegment> segments;
  final PassageSource source;
  final DateTime createdAt;

  const Passage({
    required this.id,
    required this.title,
    required this.segments,
    required this.source,
    required this.createdAt,
  });

  /// Ghép toàn bộ segment lại thành một chuỗi văn bản đầy đủ.
  /// Dùng khi cần hiển thị nhanh hoặc tính độ dài bài đọc, không cần
  /// hiển thị từng từ có thể bấm.
  String get fullText => segments.map((s) => s.hanzi).join();

  factory Passage.fromJson(Map<String, dynamic> json) {
    return Passage(
      id: json['id'] as String,
      title: json['title'] as String,
      segments: (json['segments'] as List<dynamic>)
          .map((s) => PassageSegment.fromJson(s as Map<String, dynamic>))
          .toList(),
      source: json['source'] == 'api'
          ? PassageSource.api
          : PassageSource.builtin,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'segments': segments.map((s) => s.toJson()).toList(),
      'source': source == PassageSource.api ? 'api' : 'builtin',
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
