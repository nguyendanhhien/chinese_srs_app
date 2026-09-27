// services/srs_service.dart
//
// Thuật toán lặp lại ngắt quãng (Spaced Repetition), kiểu SM-2 đơn giản hoá.
//
// Hàm chính dự kiến:
//   ReviewSchedule calculateNextReview(ReviewSchedule current, EaseRating rating)
//
// Input: lịch ôn hiện tại + đánh giá của người dùng (dễ / bình thường / khó)
// Output: lịch ôn mới (intervalDays và nextReviewDate được cập nhật)
//
// Đây là phần LOGIC THUẦN (không phụ thuộc UI hay database) để dễ viết
// unit test riêng.
