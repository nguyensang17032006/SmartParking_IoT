# Bãi đỗ ô tô thông minh trong trường đại học

MVP dành cho người lái ô tô trong khuôn viên trường: cán bộ, giảng viên và khách.
Mô hình minh họa một khu bãi trong nhà gồm A01–A03, B01–B03, sử dụng chỗ đỗ chung.
Đây là mô hình ESP32 + IR để trình diễn đồ án; chưa phải hệ thống vận hành bãi xe thật.

## Chức năng

| Chức năng | Cách hoạt động |
|---|---|
| Đăng ký/đăng nhập | Số điện thoại + OTP thật qua Supabase Auth |
| Sơ đồ bãi xe | Hiển thị trống, có xe, đã đặt và thiết bị mất kết nối |
| Tìm ô trống | Lọc ô khả dụng, gợi ý theo tuyến gần cổng |
| Đặt chỗ | Giữ chỗ 5–120 phút để đến bãi; giao dịch DB ngăn giữ trùng |
| Tự hết hạn | Hạn kiểm tra bằng thời gian DB; Cron dọn trạng thái mỗi phút |
| Thông báo | Trong ứng dụng khi đang mở: có ô trống, sắp hết hạn, hết chỗ |
| Thống kê | 7 ngày: tỷ lệ có xe, mức bao phủ tín hiệu, thời gian đỗ, giờ cao điểm |
| Nhớ vị trí xe | Lưu thủ công có ghi chú; tự lưu sau khi xác nhận đã đỗ |
| Điều hướng | Dijkstra trên lối đi của sơ đồ mẫu, từ cổng đến ô đã chọn |

Thời gian giữ chỗ là hạn **đến bãi và xác nhận đã đỗ**, không phải thời hạn được đỗ xe.
Ứng dụng chưa gửi push khi đóng, chưa thu phí, chưa điều khiển cổng và chưa xác minh quan hệ
cán bộ/giảng viên/sinh viên. Supabase Auth hiện cho phép đăng ký số điện thoại;
đơn vị triển khai cần bổ sung phê duyệt hoặc danh sách người được vào nếu muốn hạn chế nội bộ.

## Kiến trúc và trạng thái

ESP32 đọc IR → HTTP API FastAPI → Supabase PostgreSQL → Realtime → Flutter.

Flutter giữ các lớp data/domain/presentation. Các thao tác đặt, hủy, xác nhận và lưu vị trí
đi qua RPC có kiểm tra tài khoản. Flutter chỉ giữ publishable key; server giữ secret key.
Khóa thiết bị chỉ nằm ở ESP32 và backend.

Thiết bị gửi tín hiệu mỗi 10 giây, kể cả trạng thái không đổi.
Không có tín hiệu trong 30 giây hoặc chưa nhận dữ liệu thì ô ở trạng thái mất kết nối.
Ưu tiên hiển thị: mất kết nối → có xe → đã đặt → trống.
Không thể đặt ô mất kết nối hoặc ô có xe.

IR chỉ phát hiện vật cản. Khi IR báo có xe, người dùng cần nhấn **Tôi đã đỗ tại đây**.
Sau xác nhận, app tự lưu vị trí và mở phiên đỗ. Khi IR báo xe rời đi, DB đóng phiên.
IR không chứng minh danh tính xe; bảo vệ/quy định sử dụng cần hỗ trợ tránh chiếm ô đã đặt.
Tự xác định danh tính xe cần bổ sung nhận diện, QR/RFID hoặc cơ chế khác.

## 1. Chuẩn bị Supabase

1. Dùng một dự án Supabase cho mô hình. Nếu đang có dữ liệu thật, đọc SQL và sao lưu trước khi áp dụng.
2. Chạy `supabase/migrations/001_university_parking.sql` trong SQL Editor.
   Script thêm bảng, RPC, RLS và Realtime; không xóa bản ghi hiện có.
   Bảng `parking_slots` đã có cần có cột `id`, `code` và giá trị `code` không trùng.
   Các cột bắt buộc khác của bảng cũ cần có mặc định để thêm được 6 ô mẫu.
   Script đặt lại quyền ghi các bảng của MVP: tài khoản app chỉ đọc; các RPC kiểm soát thao tác ghi.
3. Bật extension **pg_cron**, rồi chạy `002_expiry_schedule.sql`.
   Lượt đặt hết hiệu lực đúng hạn ngay cả giữa hai lần Cron; trạng thái lịch sử được dọn mỗi phút.
4. Trong Authentication, bật Phone và cấu hình nhà cung cấp SMS.
   Với demo, có thể dùng chức năng **test phone numbers** của Supabase theo tài liệu chính thức;
   việc xác thực vẫn đi qua Supabase, app không chấp nhận OTP tùy ý.
5. Lấy Project URL, publishable key cho app và secret/service_role key cho backend.
   Không đưa secret key vào Flutter.
6. Bảng slot không chứa biển số hoặc thông tin cá nhân. RLS chỉ cho tài khoản đã đăng nhập đọc slot,
   mỗi người chỉ đọc lượt đặt/vị trí/phiên đỗ của chính mình. Báo cáo chỉ trả tổng hợp.

Tài liệu: [Phone Auth](https://supabase.com/docs/guides/auth/phone-login),
[Realtime Flutter](https://supabase.com/docs/reference/dart/stream),
[Cron](https://supabase.com/docs/guides/cron).

## 2. Chạy backend

Trong `smart_parking_backend`:

```bash
python -m venv .venv
# Windows: .venv\Scripts\activate
# Linux/macOS: source .venv/bin/activate
python -m pip install -r requirements.txt
# Sao chép .env.example thành .env, rồi nhập thông tin Supabase.
python -c "import secrets; print(secrets.token_urlsafe(32))"
# Dùng khóa mới tạo làm DEVICE_API_KEY của backend và ESP32.
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Truy cập `http://localhost:8000/docs` để kiểm tra API.
GET `/health` chỉ kiểm tra tiến trình còn chạy; không xác nhận Supabase kết nối được.
GET `/api/v1/parking-slots` và POST `/api/v1/parking-slots/A01/sensor`
cần header `X-Device-Key`. Body mẫu: `{"occupied": false}`.
Endpoint nhận cảm biến không tự tạo ô đỗ khi mã không tồn tại.

Laptop và ESP32 phải cùng mạng Wi-Fi. Lấy IPv4 bằng `ipconfig` trên Windows.
Cho phép cổng 8000 qua firewall trong mạng nội bộ.
Địa chỉ trong cấu hình là ví dụ; không dùng `localhost` trên ESP32.
HTTP chỉ phục vụ demo trong mạng nội bộ. Triển khai từ xa cần HTTPS kiểm tra chứng chỉ.

## 3. ESP32 + IR

1. Sao chép `esp32/include/parking_config.example.h` thành `parking_config.h`.
2. Sửa SSID, mật khẩu Wi-Fi, IPv4 laptop và khóa thiết bị.
3. Mặc định bật **một IR cho A01 tại GPIO27**. Chỉ bỏ comment các ô đã gắn cảm biến.
4. Xác minh điện áp cấp và mức OUT theo module IR đang dùng.
   ESP32 dùng mức logic 3.3V: không nối OUT 5V trực tiếp vào GPIO.
   Nếu module hỗ trợ 3.3V, dùng cấu hình cấp phù hợp; nếu không, cần chuyển mức.
   GND cảm biến và ESP32 phải chung.
5. Mẫu dùng LOW = có vật cản. Nếu module đảo logic, sửa `occupiedLevel`.
   LED ngoài tùy chọn tại GPIO25 phải có điện trở hạn dòng.
6. Trong thư mục `esp32`:

```bash
python -m pip install platformio
python -m platformio run
python -m platformio run --target upload
python -m platformio device monitor
```

| Ô | GPIO mẫu |
|---|---|
| A01 | 27 |
| A02 | 26 |
| A03 | 33 |
| B01 | 32 |
| B02 | 18 |
| B03 | 19 |

Các ô chưa gắn thiết bị sẽ hiện mất kết nối, không bị coi là trống.
Heartbeat chỉ kiểm tra đường truyền thiết bị; chưa chẩn đoán dây IR bị rút hoặc IR bị lỗi.
Firmware ổn định tín hiệu 250ms, thử gửi lại khi lỗi và xoay lần lượt các ô.
Mất Wi-Fi không khiến vòng lặp chờ kết nối vô hạn.

## 4. Chạy Flutter

Trong `SmartParking/smart_parking`, sao chép `.env.example` thành `.env`,
điền URL và **publishable key** của cùng dự án Supabase.

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Sau khi đăng ký/đăng nhập, chọn ô trống → đặt chỗ → đến ô → đặt vật mô phỏng xe lên IR →
nhấn xác nhận đã đỗ → xem **Xe của tôi**. Dời vật ra để mô phỏng xe rời bãi.

Sơ đồ mẫu có một lối đi ngang và cổng phía trái. `map_x/map_y` nằm trong [0,1].
Muốn áp dụng cho trường cụ thể cần khảo sát sơ đồ, vị trí ô, lối một chiều và kích thước;
cập nhật đồ thị trong `indoor_route.dart` cùng giao diện bản đồ.
Điểm bắt đầu là cổng; hệ thống chưa theo dõi vị trí điện thoại bằng GPS/BLE/UWB trong nhà.

## 5. Thống kê và kiểm thử

Tỷ lệ có xe = thời gian quan sát có xe / tổng thời gian quan sát có tín hiệu.
Mức bao phủ = thời gian quan sát / (số ô × 7 ngày).
Không có dữ liệu trả về trạng thái chưa có dữ liệu, không tạo số minh họa.

Thời gian đỗ trung bình chỉ dùng phiên người dùng đã xác nhận và kết thúc bằng tín hiệu xe rời đi.
Các phiên mất tín hiệu được đánh dấu riêng và không đưa vào trung bình.
Giờ cao điểm dùng tổng phút-ô có xe, theo giờ Việt Nam.
Các thông số là ước lượng theo cảm biến và thời điểm xác nhận, không thay thế hệ thống tính phí.

```bash
# API
cd smart_parking_backend
python -m pip install -r requirements-dev.txt
python -m pytest -q

# SQL: DB PostgreSQL cô lập bằng PGlite, không cần tài khoản Supabase
cd supabase
npm install
npm test
```

Đã kiểm chứng trong phiên phát triển: 10 ca API, 22 tình huống SQL và build PlatformIO.
Cú pháp Dart được kiểm tra bằng formatter.
Chưa chạy được Flutter analyze/widget tests/build ứng dụng trong phiên này vì bộ duyệt tự động
chặn bước chuẩn bị SDK khi nó truy cập endpoint metadata cloud.
Chưa kiểm thử gửi SMS thật hoặc phần cứng thật. Chạy các lệnh Flutter trên máy phát triển
sau khi cấu hình dự án; không coi các kiểm tra cú pháp là kết quả kiểm thử giao diện.
