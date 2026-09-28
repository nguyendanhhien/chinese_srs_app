import 'package:flutter/material.dart';

/// Hiển thị số lần đã đọc bài trong ngày hôm nay, dạng chấm tròn
/// (đã đọc / chưa đọc) + chữ "Lần đọc: x/3", kèm nút xác nhận
/// "Tôi đã đọc xong lượt này".
///
/// Widget này THUẦN HIỂN THỊ - không tự gọi provider hay service nào.
/// [onMarkRead] là null thì nút tự ẩn đi (ví dụ khi đã đọc đủ số lần
/// yêu cầu, DetailScreen sẽ không truyền callback này nữa).
class ReadingCounter extends StatelessWidget {
  const ReadingCounter({
    super.key,
    required this.readCount,
    required this.requiredCount,
    this.onMarkRead,
  });

  final int readCount;
  final int requiredCount;
  final VoidCallback? onMarkRead;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(requiredCount, (index) {
            final isDone = index < readCount;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                isDone ? Icons.check_circle : Icons.circle_outlined,
                color: isDone ? Colors.green : Colors.grey,
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          'Lần đọc: $readCount/$requiredCount',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        if (onMarkRead != null) ...[
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onMarkRead,
            child: const Text('Tôi đã đọc xong lượt này'),
          ),
        ],
      ],
    );
  }
}
