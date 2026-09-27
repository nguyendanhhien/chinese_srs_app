// services/passage_api_service.dart
//
// Gọi API ngoài để lấy thêm văn bản tiếng Trung.
// Chịu trách nhiệm cho tiêu chí: "API integration" + evidence-api-ux.
//
// Sẽ chọn API cụ thể ở bước sau (ví dụ: một API tin tức tiếng Trung, hoặc
// nguồn văn bản mở). Kết quả trả về được map sang model Passage
// (source = "api") rồi lưu cache qua DatabaseService để đọc offline.
