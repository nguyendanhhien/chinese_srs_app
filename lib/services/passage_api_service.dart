import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pinyin/pinyin.dart';

import '../models/passage.dart';

/// Lấy thêm bài đọc tiếng Trung từ Wikipedia tiếng Trung (zh.wikipedia.org).
///
/// Dùng Wikipedia vì: API công khai, miễn phí, không cần đăng ký key,
/// và hỗ trợ tham số exchars để giới hạn đúng số chữ mong muốn (~1000).
class PassageApiService {
  static const _baseUrl = 'https://zh.wikipedia.org/w/api.php';

  /// Lấy MỘT bài đọc ngẫu nhiên từ Wikipedia tiếng Trung, dài khoảng
  /// [maxChars] chữ.
  Future<Passage> fetchRandomPassage({int maxChars = 1000}) async {
    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {
        'action': 'query',
        'generator': 'random',
        'grnnamespace': '0',
        'prop': 'extracts',
        'explaintext': '1',
        'exchars': maxChars.toString(),
        'format': 'json',
        'formatversion': '2',
      },
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'Không thể tải bài đọc từ API (mã lỗi ${response.statusCode}).',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final pages = data['query']?['pages'] as List<dynamic>?;

    if (pages == null || pages.isEmpty) {
      throw Exception('API không trả về bài đọc nào, thử lại sau.');
    }

    final page = pages.first as Map<String, dynamic>;
    final title = (page['title'] as String?) ?? 'Bài đọc từ Wikipedia';
    final extract = ((page['extract'] as String?) ?? '').trim();

    if (extract.isEmpty) {
      throw Exception('Bài đọc lấy được không có nội dung, thử lại sau.');
    }

    return Passage(
      id: 'api_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      segments: _buildSegmentsFromRawText(extract),
      source: PassageSource.api,
      createdAt: DateTime.now(),
    );
  }

  /// Văn bản từ API chưa có sẵn ranh giới từ (khác với bài mẫu tự soạn),
  /// nên tạm thời tách theo TỪNG KÝ TỰ.
  ///
  /// meaningVi để trống ('') có chủ đích: DetailScreen sẽ gọi
  /// DictionaryService.lookup() ngay lúc người dùng bấm vào một chữ,
  /// thay vì tra nghĩa trước cho toàn bộ ~1000 chữ.
  List<PassageSegment> _buildSegmentsFromRawText(String text) {
    return text.runes.map((rune) {
      final char = String.fromCharCode(rune);
      final pinyin = PinyinHelper.getPinyin(char, separator: '');
      return PassageSegment(hanzi: char, pinyin: pinyin, meaningVi: '');
    }).toList();
  }
}
