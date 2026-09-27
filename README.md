# Chinese SRS Reading App (tên tạm)

App Flutter giúp người học đọc văn bản tiếng Trung mỗi ngày theo phương pháp
lặp lại ngắt quãng (Spaced Repetition).

## Trạng thái hiện tại
Đây là khung thư mục (skeleton) — các file `.dart` mới chỉ có comment mô tả
vai trò, CHƯA có code thật. Sẽ lấp dần từng file ở các bước tiếp theo.

## Cấu trúc thư mục

```
lib/
├── main.dart                      # entry point
├── models/
│   ├── passage.dart                # 1 bài đọc (~1000 chữ)
│   ├── vocabulary.dart             # 1 mục từ điển (hanzi/pinyin/nghĩa)
│   └── review_schedule.dart        # tiến trình ôn tập SRS của 1 bài
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── signup_screen.dart
│   ├── home/
│   │   └── home_screen.dart        # bài của "hôm nay"
│   ├── reading/
│   │   └── detail_screen.dart      # đọc bài, bấm từ để tra nghĩa
│   └── settings/
│       └── settings_screen.dart
├── services/
│   ├── auth_service.dart           # Firebase Auth
│   ├── database_service.dart       # SQLite (sqflite) - local storage
│   ├── srs_service.dart            # thuật toán lặp lại ngắt quãng (SM-2)
│   ├── passage_api_service.dart    # lấy thêm bài đọc từ API ngoài
│   ├── dictionary_service.dart     # tra nghĩa từ (Việt ưu tiên, Anh dự phòng)
│   └── notification_service.dart   # nhắc học hằng ngày
├── providers/
│   ├── auth_provider.dart
│   ├── passage_provider.dart
│   └── settings_provider.dart
├── widgets/
│   ├── tappable_text.dart          # văn bản có thể bấm từng từ
│   ├── word_popup.dart             # popup nghĩa của từ
│   └── reading_counter.dart        # "Lần đọc: 2/3"
└── utils/
    └── constants.dart

assets/
└── data/
    ├── sample_passages.json        # bài đọc mẫu (sẽ soạn ở bước sau)
    └── mini_dictionary.json        # từ điển mini tiếng Việt (sẽ soạn sau)

test/                                # unit test (ít nhất cho srs_service.dart)
```

## Luồng chính của app
1. Người dùng đăng nhập/đăng ký (Firebase Auth)
2. Home screen: hiển thị bài đọc của "hôm nay" — ưu tiên bài đến hạn ôn tập,
   nếu không có thì lấy bài mới
3. Detail screen: đọc đoạn văn ~1000 chữ, có thể bấm từng từ để tra nghĩa,
   theo dõi số lần đọc trong ngày (mục tiêu: 3 lần/ngày)
4. Sau khi đọc đủ số lần, người dùng tự đánh giá mức nhớ (dễ/bình
   thường/khó) → app tính lại ngày cần ôn tiếp theo
5. Settings: chỉnh số bài/ngày, giờ nhắc học, cỡ chữ, hiển thị pinyin
6. Notification: nhắc nhở vào giờ đã đặt nếu có bài cần ôn hôm đó
