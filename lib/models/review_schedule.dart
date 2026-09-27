// models/review_schedule.dart
//
// Đại diện cho TIẾN TRÌNH ÔN TẬP của một bài đọc, gắn với một user cụ thể.
// Đây là "trái tim" của tính năng lặp lại ngắt quãng (SRS).
//
// Các trường dự kiến:
// - passageId
// - userId
// - readCountToday      : số lần đã đọc trong ngày hôm nay (0, 1, 2, 3)
// - lastReadDate         : ngày đọc gần nhất
// - easeRating           : đánh giá gần nhất của người dùng (dễ / bình thường / khó)
// - intervalDays         : số ngày tới lần ôn tiếp theo (1 -> 3 -> 7 -> 14 -> 30...)
// - nextReviewDate       : ngày cần ôn lại tiếp theo (tính từ intervalDays)
// - status               : "new" | "learning" (đang đọc trong ngày) | "reviewing"
//
// Thuật toán tính nextReviewDate (kiểu SM-2 đơn giản hoá) sẽ được viết
// riêng trong services/srs_service.dart, KHÔNG viết trực tiếp trong model.
