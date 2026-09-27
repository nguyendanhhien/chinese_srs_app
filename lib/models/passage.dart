// models/passage.dart
//
// Đại diện cho MỘT bài đọc tiếng Trung (~1000 chữ).
//
// Các trường dự kiến (sẽ hoàn thiện ở bước viết model):
// - id
// - title               : tiêu đề bài đọc
// - segments            : danh sách các "khối từ" đã phân tách sẵn
//                         (mỗi khối = {hanzi, pinyin, meaningVi})
//                         -> dùng để render văn bản có thể bấm từng từ
// - source               : "builtin" (bài mẫu) hoặc "api" (lấy từ API ngoài)
// - createdAt
//
// Model KHÔNG chứa lịch ôn tập (SRS) - lịch ôn tập là một model riêng
// (review_schedule.dart) để tách rõ "nội dung" và "tiến trình học".
