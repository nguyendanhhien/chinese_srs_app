import 'package:flutter/material.dart';

import '../models/passage.dart';
import '../services/dictionary_service.dart';

/// Popup nhỏ hiện ngay tại vị trí bấm (không rời màn hình đọc), hiển thị:
/// chữ Hán - pinyin - nghĩa (tiếng Việt nếu có, tiếng Anh dự phòng, hoặc
/// "chưa có nghĩa" nếu cả hai đều không có).
///
/// Dùng OverlayEntry thay vì Dialog để popup xuất hiện ĐÚNG NGAY VỊ TRÍ
/// bấm thay vì giữa màn hình.
class WordPopup {
  WordPopup._();

  static OverlayEntry? _currentEntry;

  static void show({
    required BuildContext context,
    required PassageSegment segment,
    required Offset globalPosition,
    required DictionaryService dictionaryService,
  }) {
    // Đóng popup cũ (nếu có) trước khi mở popup mới.
    hide();

    final overlay = Overlay.of(context);
    _currentEntry = OverlayEntry(
      builder: (overlayContext) => _WordPopupContent(
        segment: segment,
        globalPosition: globalPosition,
        dictionaryService: dictionaryService,
        onDismiss: hide,
      ),
    );
    overlay.insert(_currentEntry!);
  }

  static void hide() {
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

class _WordPopupContent extends StatefulWidget {
  const _WordPopupContent({
    required this.segment,
    required this.globalPosition,
    required this.dictionaryService,
    required this.onDismiss,
  });

  final PassageSegment segment;
  final Offset globalPosition;
  final DictionaryService dictionaryService;
  final VoidCallback onDismiss;

  @override
  State<_WordPopupContent> createState() => _WordPopupContentState();
}

class _WordPopupContentState extends State<_WordPopupContent> {
  String? _pinyin;
  String? _meaning;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMeaning();
  }

  Future<void> _loadMeaning() async {
    final segment = widget.segment;

    // Bài mẫu tự soạn đã có sẵn nghĩa trong chính segment -> dùng ngay,
    // không cần tra cứu thêm.
    if (segment.meaningVi.isNotEmpty) {
      setState(() {
        _pinyin = segment.pinyin;
        _meaning = segment.meaningVi;
        _isLoading = false;
      });
      return;
    }

    // Bài từ API chưa có nghĩa sẵn -> tra qua DictionaryService.
    final result = await widget.dictionaryService.lookup(segment.hanzi);
    if (!mounted) return;

    setState(() {
      _pinyin = result.pinyin;
      _meaning = result.meaning ?? 'Chưa có nghĩa cho từ này';
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    const popupWidth = 200.0;

    // Đặt popup ngay dưới vị trí bấm, tự kéo vào trong nếu tràn màn hình.
    final left = (widget.globalPosition.dx - popupWidth / 2)
        .clamp(8.0, screenSize.width - popupWidth - 8.0);
    final top = widget.globalPosition.dy + 24;

    return Stack(
      children: [
        // Lớp trong suốt phủ toàn màn hình - bấm ra ngoài để đóng popup.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: widget.onDismiss,
          ),
        ),
        Positioned(
          left: left,
          top: top,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            color: Theme.of(context).colorScheme.surface,
            child: Container(
              width: popupWidth,
              padding: const EdgeInsets.all(12),
              child: _isLoading
                  ? const Center(
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.segment.hanzi,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _pinyin ?? '',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 4),
                        Text(_meaning ?? ''),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
