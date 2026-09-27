// screens/reading/detail_screen.dart
//
// Ứng với tiêu chí: "detail screen implementation" + evidence-detail-screen.
//
// Nội dung chính:
// - Hiển thị đoạn văn ~1000 chữ dưới dạng văn bản CÓ THỂ BẤM TỪNG TỪ
//   (dùng widget TappableText từ widgets/tappable_text.dart)
// - Bấm vào 1 từ -> hiện WordPopup (widgets/word_popup.dart) với
//   pinyin + nghĩa (tiếng Việt ưu tiên, tiếng Anh dự phòng)
// - Hiển thị ReadingCounter ("Lần đọc: x/3") - widgets/reading_counter.dart
// - Sau khi đủ 3 lần đọc trong ngày -> hiện dialog tự đánh giá mức nhớ
//   (dễ / bình thường / khó) -> gọi SrsService để tính lịch ôn tiếp theo
