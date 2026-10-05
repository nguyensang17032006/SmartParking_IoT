# Home và MainLayout — bãi xe trường đại học

Bản này dựa trên cấu trúc thư mục trong ảnh bạn gửi. File bắt đầu của bản đồ
nằm tại `lib/features/parking/presentation/pages/widget/parking_map.dart`.
Các phần nhỏ của bản đồ nằm trong thư mục `pages/widget/parking_map/`.

## 1. Cài vào dự án

Giải nén ZIP. Chép các file trong `lib/`, `test/` và `tool/` vào các thư mục
cùng tên của dự án Flutter hiện tại, ở cấp có `pubspec.yaml`.
Gói là phần cập nhật cho dự án hiện tại, không phải một dự án Flutter độc lập.
Không cần thêm package. Giữ các entity ParkingSlot, repository, datasource,
WatchParkingSlots và trang đăng nhập/OTP đang có trong dự án.

Sau khi chép, chạy từ thư mục có pubspec.yaml:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Đóng app rồi chạy lại khi thay cấu trúc và route.

MainLayout đã nằm đúng tại `lib/core/app/main_layout.dart`.
ParkingPage chỉ chứa nội dung, không tạo Scaffold hoặc AppBar thứ hai.

## 2. Xem Home ngay trong giai đoạn làm giao diện

Mặc định app mở `/login` và luồng OTP hiện tại chuyển sang `/home`.
Các trang đăng nhập/OTP của dự án vẫn đang mô phỏng xác thực; gói này không
bổ sung xác thực người dùng.

Để xem Home trực tiếp, sửa dòng runApp trong `main.dart`:

```dart
runApp(
  MyApp(
    watchParkingSlots: watchParkingSlots,
    initialRoute: '/home',
  ),
);
```

Home vẫn cần cấu hình Supabase hiện tại để nhận dữ liệu.
Không chép lại ParkingPage cũ có Scaffold vào trong MainLayout.

## 3. Thiết kế giao diện

- AppBar: biểu tượng P, tên Smart Parking, nút hướng dẫn đỗ xe.
- Home: tiêu đề, thẻ tổng quan nền xanh đậm, nút xem bản đồ.
- Bốn thẻ số liệu: còn trống, đang có xe, tổng số ô, tỷ lệ lấp đầy.
- Màn hình hẹp có hai thẻ mỗi hàng; màn hình rộng có bốn thẻ mỗi hàng.
- Tìm kiếm mã ô và bộ lọc chỉ hiện ô trống. Bộ lọc làm mờ các ô khác,
  không thay đổi vị trí vật lý của các ô trên bản đồ.
- Cổng vào trái, đường ngang ở giữa, cổng ra phải; dãy A ở trên, B ở dưới.
- Chạm ô trống để xem tuyến, nút Bỏ chọn xóa tuyến.
- Có giao diện tải dữ liệu, danh sách rỗng và lỗi kèm nút Thử lại.
- Thanh điều hướng có Trang chủ và Sơ đồ. Hai mục dùng cùng một ParkingPage;
  Sơ đồ ẩn phần tổng quan và giữ tìm kiếm, lựa chọn, mức phóng to bản đồ.

Model hiện tại chỉ có occupied, nên chưa thể suy ra trạng thái đã đặt hoặc
mất kết nối cảm biến. Giao diện dùng các số liệu mà model thực sự cung cấp.
Lỗi tải dữ liệu được hiển thị riêng, không quy đổi thành số ô mất kết nối.
Việc chọn ô trên bản đồ chỉ hiển thị đường đi, chưa giữ chỗ.

## 4. Trách nhiệm và thư mục

| Đường dẫn, tính từ lib/ | Trách nhiệm |
| --- | --- |
| core/app/main_layout.dart | Scaffold, AppBar, hướng dẫn và điều hướng Trang chủ/Sơ đồ. |
| core/theme/app_theme.dart | Theme và màu dùng chung. Giữ tên cũ ink/muted qua alias. |
| main.dart | Khởi tạo dependencies hiện có; đặt BlocProvider trên MaterialApp; khai báo route. |
| features/parking/domain/entities/parking_overview.dart | Tổng số ô, có xe, còn trống, tỷ lệ lấp đầy; không phụ thuộc Flutter. |
| features/parking/domain/entities/parking_map_layout.dart | Vị trí vật lý của từng ô theo hàng/cột. |
| features/parking/domain/entities/parking_route.dart | Đích của tuyến logic. |
| features/parking/domain/usecases/build_parking_route.dart | Kiểm tra ô trống và có vị trí trước khi tạo tuyến. |
| features/parking/presentation/parking_bloc/parking_bloc.dart | Theo dõi dữ liệu, lỗi, thử lại và hủy subscription khi đóng. |
| features/parking/presentation/parking_map_cubit/ | Trạng thái chọn ô và tuyến, xử lý cập nhật dữ liệu/filter/bố trí. |
| features/parking/presentation/pages/parking_page.dart | Ghép nội dung Home/Sơ đồ; quản lý tìm kiếm và bộ lọc UI. |
| features/parking/presentation/pages/widget/parking_home_header.dart | Nhãn trường đại học, tiêu đề và mô tả. |
| features/parking/presentation/pages/widget/parking_availability_card.dart | Tổng quan số chỗ trống và nút mở bản đồ. |
| features/parking/presentation/pages/widget/parking_stat_card.dart | Thẻ số liệu và bố cục responsive của bốn thẻ. |
| features/parking/presentation/pages/widget/parking_filter_bar.dart | TextField, nút xóa và FilterChip. |
| features/parking/presentation/pages/widget/parking_feedback_panel.dart | Tải, lỗi/thử lại và dữ liệu rỗng. |
| features/parking/presentation/pages/widget/parking_map.dart | Entry point để import ParkingMap đúng theo ảnh. |
| features/parking/presentation/pages/widget/parking_map/ | Các widget bản đồ đã tách nhỏ, geometry và style. |
| features/parking/presentation/painters/horizontal_parking_lane_painter.dart | Vẽ đường ngang, vạch đứt, trụ cổng, mũi tên và tuyến. |

Tầng Data và luồng WatchParkingSlots hiện có được sử dụng lại. MainLayout
không đọc Supabase trực tiếp; dữ liệu đến ParkingPage qua ParkingBloc.

## 5. Luồng hệ thống

Luồng IoT đề xuất: ESP32 đọc cảm biến tại các ô, cập nhật trạng thái trên
Supabase. Flutter nhận cập nhật từ parking_slots thông qua datasource,
repository và WatchParkingSlots. Firmware ESP32 không nằm trong gói này.

Khi mở Home, ParkingBloc nhận ParkingWatchStarted và mở một subscription.
Khi cảm biến cập nhật, Bloc phát ParkingLoaded. ParkingPage tính tổng quan
và truyền slots sang bản đồ. Khi chạm ô, ParkingMapCubit gọi BuildParkingRoute;
Presentation chuyển hàng/cột thành tọa độ và painter vẽ tuyến.

Khi ô đang chọn có xe, bị lọc khỏi tập nổi bật hoặc bị xóa khỏi bố trí,
Cubit tự bỏ chọn. Khi thử lại, Bloc hủy subscription trước rồi mở luồng mới.
Mỗi lần theo dõi có một generation; dữ liệu từ lượt cũ bị bỏ qua.
Khi đóng Bloc, subscription được hủy.

## 6. Route và provider

BlocProvider nằm phía trên MaterialApp để mọi route truy cập cùng ParkingBloc.
Không đặt provider chỉ bên trong home của MaterialApp, vì named route `/home`
được tạo trong Navigator và cần nhận provider từ phía trên.

| Route | Widget |
| --- | --- |
| /login | LoginPage |
| /register | RegisterScreen |
| /otp | OtpPage |
| /home | MainLayout |

## 7. Kiểm tra

Đã chạy thành công script Dart độc lập: **15 kiểm tra Domain** gồm bố trí,
tuyến đến ô hợp lệ và số liệu tổng quan (danh sách rỗng, đủ chỗ, hết chỗ,
số liệu kết hợp và snapshot bất biến).

```bash
dart tool/check_parking_map_domain.dart
```

Đã kiểm tra cú pháp/định dạng, import tương đối, các import smart_parking,
icon Flutter, tên AppColors và tính đầy đủ của ZIP.

Có thêm 6 test Flutter:

- Home hiển thị số liệu thật trên màn hình rộng 320px.
- Chuyển Trang chủ/Sơ đồ giữ tìm kiếm và tuyến, không đăng ký dữ liệu lần hai.
- Named route /home nhận được ParkingBloc ở root.
- Retry hủy luồng cũ và nhận dữ liệu luồng mới.
- Lỗi luồng được chuyển tới UI và có thể thử lại.
- Đóng Bloc hủy subscription và bỏ qua cập nhật muộn.

Các test Flutter, flutter analyze và giao diện app **chưa chạy trong môi trường
soạn mã** vì thiếu dependency Flutter đã resolve và Flutter test runtime.
Chạy các lệnh ở mục 1 trong dự án của bạn để kiểm tra trên Flutter đầy đủ.
