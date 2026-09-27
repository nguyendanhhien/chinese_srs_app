// services/notification_service.dart
//
// Quản lý thông báo nhắc học hằng ngày (dùng package flutter_local_notifications).
// Chịu trách nhiệm cho tiêu chí: notifications implementation +
// evidence-notification-configure + evidence-notification-alert.
//
// Chức năng dự kiến:
// - scheduleDailyReminder(TimeOfDay time) : đặt lịch nhắc theo giờ người
//   dùng chọn trong Settings
// - Nội dung thông báo: "Hôm nay có bài cần ôn tập!" (lấy số bài đến hạn
//   từ PassageProvider/DatabaseService)
