# Parking Home trong MainLayout

`ParkingHome` là widget nội dung cho trang Home. MainLayout quản lý Scaffold,
AppBar, SafeArea, theme và thanh điều hướng chung của ứng dụng.

## Tích hợp

Chép `parking_home.dart` vào `lib/features/parking/presentation/pages/`.
Trong `lib/core/app/main_layout.dart`, import:

```dart
import '../../features/parking/presentation/pages/parking_home.dart';
```

Thêm `const ParkingHome()` vào danh sách trang đang được MainLayout quản lý.
Nếu layout dùng IndexedStack, giữ Home trong danh sách children để trạng thái
lọc, chỗ đặt và vị trí đã lưu được giữ khi chuyển tab.

## Nội dung Home

- Lời chào và vị trí bãi xe trường đại học.
- Thẻ chỗ đã đặt, thời gian đến, hủy đặt chỗ và xem đường đến ô.
- Tổng số ô trống, có xe, đã đặt và mất kết nối.
- Sơ đồ sáu ô mẫu với tuyến đường từ cổng.
- Tìm kiếm mã ô, lọc trạng thái, xem chi tiết, đặt/chuyển chỗ và lưu vị trí xe.

File chỉ import Flutter Material và dùng dữ liệu trong bộ nhớ.
Chưa nối ESP32, API, tự hết hạn đặt chỗ hoặc thông báo nền.

Đã kiểm tra định dạng/cú pháp bằng Dart formatter. Chưa chạy ứng dụng Flutter
trong môi trường này.
