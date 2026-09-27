// services/database_service.dart
//
// Quản lý database SQLite cục bộ (dùng package sqflite).
// Chịu trách nhiệm cho tiêu chí: "local storage implementation" +
// evidence-persistence + evidence-integrateScreen-persistence.
//
// Các bảng dự kiến:
// - passages           : lưu bài đọc (kể cả bài lấy từ API, cache lại để đọc offline)
// - review_schedules    : tiến trình ôn tập SRS của từng bài (theo user)
// - vocabulary          : từ điển mini (hanzi, pinyin, nghĩa Việt/Anh)
