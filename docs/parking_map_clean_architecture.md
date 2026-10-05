# Parking Map — giải thích widget và Clean Architecture

Bản này tách từ code ParkingMap bạn gửi. Bố trí là cổng vào ở bên trái,
cổng ra ở bên phải, dãy A ở trên và dãy B ở dưới. Trạng thái cảm biến vẫn đến
qua ParkingBloc hiện tại; bản đồ nhận List<ParkingSlot> từ màn hình.

## 1. Gắn vào dự án

Giải nén gói mã nguồn và chép thư mục `lib` vào thư mục dự án có `pubspec.yaml`.
Gói chỉ chứa các file bản đồ mới và file export tương thích. Các thành phần
`ParkingSlot`, `ParkingBloc`, repository và datasource của dự án đang được dùng.
Dự án đã có dependencies `bloc`, `flutter_bloc` và `equatable`.

Trong ParkingPage, dùng import trực tiếp đến widget mới:

```dart
import 'package:smart_parking/features/parking/presentation/pages/widget/parking_map.dart';
```

Ở nhánh ParkingLoaded của BlocBuilder:

```dart
return ParkingMap(
  slots: state.slots,
  topRowCodes: const ['A01', 'A02', 'A03'],
  bottomRowCodes: const ['B01', 'B02', 'B03'],
);
```

Nếu đã import `presentation/pages/parking_map.dart`, file đó hiện export widget
mới nên cách gọi cũ cũng hoạt động. Chỉ dùng một import cho ParkingMap trong
mỗi màn hình. Sau khi thay file và chuyển cấu trúc lớp, dừng app rồi chạy lại.
MainLayout tiếp tục quản lý khung trang và điều hướng.

`topRowCodes` và `bottomRowCodes` là thứ tự ô ngoài thực tế, từ trái sang phải.
Thay đổi thứ tự danh sách để đổi vị trí vật lý của ô. Tìm kiếm/lọc chỉ làm mờ
ô không phù hợp, không xếp lại các ô trên sơ đồ.

## 2. Trách nhiệm của ba tầng

| Tầng | Nội dung trong dự án | Công việc |
| --- | --- | --- |
| Domain | ParkingSlot, ParkingRepository, WatchParkingSlots và các lớp bố trí/tuyến mới | Dữ liệu nghiệp vụ và quy tắc hợp lệ của ô đỗ. Không dùng Flutter, Canvas, Color hoặc Supabase. |
| Data | ParkingRemoteDataSource, ParkingSlotModel, ParkingRepositoryImpl đang có | Đọc Supabase, chuyển dữ liệu về entity, triển khai interface repository. |
| Presentation | ParkingBloc, ParkingMapCubit, widget, painter, geometry, style | Nhận dữ liệu, xử lý tương tác, giữ trạng thái giao diện và vẽ bản đồ. |

ParkingBloc theo dõi cảm biến thông qua WatchParkingSlots. Màn hình truyền
slots sang ParkingMap. ParkingMapCubit quản lý ô được chọn và bộ lọc, đồng
thời gọi BuildParkingRoute để kiểm tra đích. Widget hiển thị state của Cubit.
Không cần thêm repository để lưu màu sắc hoặc kích thước widget.

## 3. Các file của bản đồ

Tất cả đường dẫn trong bảng tính từ `lib/features/parking/`.

| File | Vai trò |
| --- | --- |
| `domain/entities/parking_map_layout.dart` | Hai dãy ô, vị trí hàng/cột, kiểm tra mã ô trống hoặc trùng. Sao chép danh sách để tránh cấu hình bị thay đổi từ ngoài. |
| `domain/entities/parking_route.dart` | Tuyến logic: mã ô đích và vị trí hàng/cột. Chưa chứa tọa độ pixel. |
| `domain/usecases/build_parking_route.dart` | Trả tuyến nếu ô chưa có xe và đã được bố trí trên sơ đồ; trường hợp khác trả null. |
| `presentation/parking_map_cubit/parking_map_state.dart` | Slots, bố trí, tập mã được làm nổi bật, selectedId và route. |
| `presentation/parking_map_cubit/parking_map_cubit.dart` | selectSlot, clearSelection và updateData. Xóa lựa chọn khi ô có xe, bị lọc khỏi tập nổi bật hoặc bị loại khỏi bố trí. |
| `presentation/pages/widget/parking_map/parking_map.dart` | Widget công khai. Tạo Cubit khi mở, cập nhật đầu vào khi widget cha đổi dữ liệu, đóng Cubit khi hủy. |
| `presentation/pages/widget/parking_map/parking_map_view.dart` | Khung thẻ chứa header, viewport, thông tin tuyến và thông báo ô chưa bố trí. |
| `presentation/pages/widget/parking_map/parking_map_header.dart` | Tiêu đề, hướng dẫn và chú giải trạng thái. |
| `presentation/pages/widget/parking_map/parking_map_viewport.dart` | Vùng phóng to/di chuyển; đặt đường, ô và nhãn cổng trên cùng Stack. |
| `presentation/pages/widget/parking_map/parking_bay_tile.dart` | Một ô đỗ: mã ô, biểu tượng, trạng thái, viền chọn và thao tác chạm. |
| `presentation/pages/widget/parking_map/parking_map_legend.dart` | Chấm màu và tên một trạng thái. |
| `presentation/pages/widget/parking_map/parking_map_gate.dart` | Biểu tượng và nhãn cổng vào/cổng ra. |
| `presentation/pages/widget/parking_map/parking_map_route_summary.dart` | Hiện “Cổng vào → mã ô” và nút Bỏ chọn. |
| `presentation/pages/widget/parking_map/parking_map_geometry.dart` | Tọa độ màn hình, kích thước ô, vị trí cổng, chuyển route logic thành Offset. |
| `presentation/pages/widget/parking_map/parking_map_style.dart` | Màu của ô trống, có xe, được chọn, chưa có dữ liệu. |
| `presentation/painters/horizontal_parking_lane_painter.dart` | Vẽ đường ngang, vạch đứt, mũi tên một chiều, trụ cổng và tuyến xanh. |
| `presentation/pages/parking_map.dart` | Export tương thích để màn hình cũ dùng widget mới. |

Các tên `_MapBay`, `_GateLabel`, `_MapLegend` của file cũ đã đổi thành tên
công khai để các file khác import được. Trong Dart, dấu `_` biểu thị riêng tư
ở phạm vi library; một file Dart thông thường là một library.

## 4. Từng widget của Flutter

| Widget | Làm gì trong bản đồ? |
| --- | --- |
| StatefulWidget | ParkingMap có State tồn tại giữa các lượt build để sở hữu vòng đời Cubit. Logic chọn ô đã nằm trong Cubit. |
| StatelessWidget | Các phần hiển thị nhận dữ liệu/callback và trả về UI; vẫn được build lại khi dữ liệu cha thay đổi. |
| BlocBuilder | Nghe ParkingMapCubit. Khi Cubit emit state mới, dựng lại phần giao diện bản đồ. |
| Material | Tạo bề mặt Material cho thẻ, ô đỗ và hiệu ứng InkWell; bo góc/viền và cắt theo đường bo. |
| Padding | Tạo khoảng đệm trong thẻ hoặc bên trong từng ô. |
| Column | Xếp tiêu đề, chú giải, bản đồ, thông tin tuyến theo chiều dọc; cũng xếp các nội dung trong ô. |
| Row | Xếp chấm màu + tên trạng thái; biểu tượng tuyến + mã ô + nút Bỏ chọn theo chiều ngang. |
| Text | Hiện tiêu đề, mã ô, nhãn trạng thái, cổng và hướng dẫn. |
| SizedBox | Tạo khoảng cách hoặc một vùng có kích thước xác định. Vùng bản vẽ có kích thước thiết kế cố định trước khi scale. |
| Wrap | Chú giải tự xuống dòng khi chiều rộng màn hình không đủ. |
| AspectRatio | Giữ tỷ lệ chiều rộng/chiều cao vùng bản đồ khi màn hình đổi kích thước. |
| InteractiveViewer | Cho phép kéo và phóng to bản đồ, mức scale từ 1 đến 3. |
| FittedBox | Thu/phóng bản thiết kế để vừa vùng hiển thị; BoxFit.contain giữ tỷ lệ và hiển thị toàn bộ hình. |
| Stack | Chồng các lớp: đường ở dưới, các ô và nhãn cổng ở trên. |
| Positioned | Đặt một phần tử trong Stack bằng tọa độ. Positioned.fill phủ hết vùng; Positioned.fromRect dùng hình chữ nhật của một ô. |
| CustomPaint | Nhận painter và cho painter vẽ trên Canvas. |
| Container | Trang trí nền/bo góc cho thông tin tuyến; vẽ chấm màu chú giải. |
| Expanded | Trong Row thông tin tuyến, cấp phần chiều rộng còn lại cho tên tuyến để nút Bỏ chọn không bị đẩy ra ngoài. |
| Icon | Hiện P, xe, dấu hỏi, biểu tượng cổng và tuyến. |
| TextButton | Nút Bỏ chọn gọi Cubit.clearSelection. |
| Opacity | Làm mờ các ô không khớp bộ lọc nhưng giữ nguyên vị trí. |
| Semantics | Cung cấp tên ô, trạng thái chọn và khả năng chạm cho trình đọc màn hình. |
| InkWell | Nhận thao tác chạm và tạo hiệu ứng Material. Chỉ bật khi ô có dữ liệu, còn trống và được bộ lọc cho phép. |

`Size`, `Offset`, `Rect`, `RRect`, `Canvas`, `Paint`, `Path`, `TextStyle`,
`BoxDecoration`, `BorderSide`, `RoundedRectangleBorder`, `ValueKey` và Cubit
không phải widget.

- Size: chiều rộng và chiều cao vùng thiết kế.
- Offset: một điểm (x, y); x tăng sang phải, y tăng xuống dưới.
- Rect/RRect: hình chữ nhật/hình chữ nhật bo góc.
- Canvas: bề mặt mà painter vẽ lên.
- Paint: màu, độ rộng nét, kiểu tô hoặc nét viền.
- Path: chuỗi nét vẽ, bắt đầu bằng moveTo, nối bằng lineTo.
- TextStyle/BoxDecoration/BorderSide/RoundedRectangleBorder: cấu hình kiểu dáng.
- ValueKey: thông tin định danh của widget trong cây UI.
- Cubit: đối tượng quản lý state, không hiển thị UI.

## 5. Vòng đời và các thao tác

Trong bản gốc, `_selectedId` nằm trong State và `setState` cập nhật lựa chọn.
Bản đã tách chuyển việc đó sang ParkingMapCubit để widget tập trung hiển thị.

| Thành phần | Vai trò sau khi tách |
| --- | --- |
| initState | Chạy khi State được tạo; khởi tạo ParkingMapCubit với dữ liệu đầu vào. |
| didUpdateWidget | Khi widget cha cung cấp slots/bố trí/bộ lọc mới, chuyển dữ liệu mới vào Cubit. |
| build | Trả về BlocBuilder và các widget hiển thị state hiện tại. |
| dispose | Đóng Cubit để giải phóng luồng state. |
| selectSlot | Nhận id được chạm, gọi use case; chỉ emit tuyến hợp lệ. |
| clearSelection | Xóa selectedId và route, ô trở về màu trạng thái cảm biến. |
| updateData | Giữ lựa chọn nếu còn hợp lệ, xóa tuyến nếu ô chuyển thành có xe hoặc không còn phù hợp. |
| paint | Dùng Canvas vẽ đường, trụ cổng, mũi tên và tuyến đến điểm đích. |
| shouldRepaint | So sánh điểm đích khi delegate painter thay đổi để giúp Flutter quyết định có cần vẽ lại. |

Các hàm vòng đời, paint và shouldRepaint cũng không phải widget.

## 6. Ví dụ đường đến A01

A01 nằm ở hàng trên, cột 0. Domain trả mã ô + vị trí hàng/cột.
Presentation tính điểm đích từ vị trí đó:

- x = 112 + 0 × 108 + 88 / 2 = 156.
- y = 22 + 102 + 4 = 128, ngay ngoài lối vào ô.
- Điểm bắt đầu = (72 + 12, 168) = (84, 168).

Painter vẽ ba điểm:

```dart
final path = Path()
  ..moveTo(84, 168)   // Điểm vào ở phía trái.
  ..lineTo(156, 168)  // Đi ngang trên lối đi.
  ..lineTo(156, 128); // Rẽ lên ngay cửa ô A01.
```

Với B01, x vẫn là 156, y = 212 - 4 = 208. Tuyến đi ngang rồi rẽ xuống.
Đường chính luôn ngang từ cổng vào trái sang cổng ra phải.
Đây là tuyến trên sơ đồ bố trí cố định; app chưa xác định vị trí xe bằng GPS.

## 7. Kiểm tra và giới hạn

Đã chạy `tool/check_parking_map_domain.dart`: 15 kiểm tra Domain qua, gồm hai dãy,
ô có xe, ô ngoài bố trí, thứ tự vật lý, hàng dài/ngắn khác nhau, cấu hình bất biến,
mã trùng, mã trống, bố trí rỗng và năm kiểm tra số liệu tổng quan bãi xe. Script chạy độc lập bằng Dart:

```bash
dart tool/check_parking_map_domain.dart
```

Đã kiểm tra cú pháp/định dạng bằng Dart formatter và đường dẫn import của các
file mới. Chưa chạy widget/app Flutter trong môi trường này. Sau khi ghép vào
dự án của bạn, chạy flutter analyze và thử chọn A01/B03, Bỏ chọn, cùng cập nhật
occupied sang true khi đang chọn ô.

## Tài liệu chính thức

- [Flutter: Guide to app architecture](https://docs.flutter.dev/app-architecture/guide)
- [Flutter: Communicating between layers](https://docs.flutter.dev/app-architecture/case-study/dependency-injection)
- [Dart: Libraries and imports](https://dart.dev/language/libraries)
