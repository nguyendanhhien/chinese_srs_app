// services/dictionary_service.dart
//
// Tra nghĩa một từ/chữ khi người dùng bấm vào trong DetailScreen.
//
// Thứ tự ưu tiên tra cứu:
// 1. Từ điển mini tiếng Việt tự soạn (assets/data/mini_dictionary.json,
//    nạp sẵn vào bảng "vocabulary" trong SQLite)
// 2. Nếu không có -> dự phòng bằng CC-CEDICT (nghĩa tiếng Anh) + pinyin
//    tính tự động bằng package "pinyin"
