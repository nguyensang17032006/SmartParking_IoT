# Parking Home — xem giao diện trước

Màn hình độc lập với dữ liệu mẫu, không gọi API, Supabase hay ESP32.
File màn hình chỉ import `package:flutter/material.dart`.

## Chép vào dự án Flutter hiện tại

1. Chép `parking_home.dart` vào `lib/features/parking/presentation/pages/`.
2. Chép `parking_home_preview.dart` vào `lib/`.
3. Trong thư mục chứa `pubspec.yaml`, chạy:

```bash
flutter run -t lib/parking_home_preview.dart
```

Nếu muốn xem trên Chrome:

```bash
flutter run -d chrome -t lib/parking_home_preview.dart
```

Điểm chạy này mở thẳng Parking Home, không khởi tạo đăng nhập hoặc dịch vụ ngoài.
Nếu dự án chưa lấy dependencies, chạy `flutter pub get` trước.
Nếu `pubspec.yaml` có `assets: - .env` nhưng chưa có file `.env`, bỏ khai báo asset đó khi chỉ xem UI.
Màn hình và điểm chạy xem trước không đọc file môi trường.

## Các tương tác mẫu

- Chạm ô trên sơ đồ hoặc thẻ ô để xem chi tiết.
- Tìm theo mã ô và lọc Trống / Đã đặt / Có xe.
- Chọn thời gian giữ chỗ và đặt/chuyển ô; tổng số cập nhật trong màn hình.
- Hủy chỗ đặt trên thẻ đầu trang.
- Xem tuyến từ cổng đến ô đã chọn.
- Lưu vị trí tại ô có xe, sau đó mở Xe của tôi để xem lại.
- Mở thông báo và thẻ tài khoản mẫu.

Các thay đổi chỉ ở bộ nhớ màn hình và đặt lại khi mở lại ứng dụng.
Chưa nối logic nghiệp vụ, thời gian tự hết hạn hoặc thông báo nền.

Đã kiểm tra cú pháp bằng Dart formatter và tên icon theo Flutter SDK.
Chưa chạy ứng dụng hoặc kiểm chứng ảnh giao diện trong môi trường phát triển này.
