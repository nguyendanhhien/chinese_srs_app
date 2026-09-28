import 'package:flutter/material.dart';

import '../models/passage.dart';

/// Widget hiển thị đoạn văn tiếng Trung dưới dạng các "khối từ" có thể
/// bấm được từng cái (dùng Wrap, mỗi khối là một GestureDetector).
///
/// Mỗi khối hiển thị pinyin phía trên, chữ Hán phía dưới (kiểu chú âm
/// trong sách song ngữ). Khi bấm vào, [onSegmentTap] được gọi kèm theo
/// segment và vị trí bấm trên màn hình (globalPosition) - dùng để
/// WordPopup biết đặt popup ở đâu.
class TappableText extends StatelessWidget {
  const TappableText({
    super.key,
    required this.segments,
    required this.onSegmentTap,
    this.fontSize = 22,
    this.showPinyin = true,
  });

  final List<PassageSegment> segments;
  final void Function(PassageSegment segment, Offset globalPosition)
      onSegmentTap;
  final double fontSize;
  final bool showPinyin;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.end,
      children: segments.map((segment) {
        return GestureDetector(
          onTapDown: (details) {
            onSegmentTap(segment, details.globalPosition);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showPinyin && segment.pinyin.isNotEmpty)
                  Text(
                    segment.pinyin,
                    style: TextStyle(
                      fontSize: fontSize * 0.45,
                      color: Colors.grey.shade600,
                    ),
                  ),
                Text(
                  segment.hanzi,
                  style: TextStyle(fontSize: fontSize, height: 1.3),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
