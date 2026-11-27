import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_parking/core/theme/app_colors.dart';
import 'package:smart_parking/features/face_recognition/data/datasources/face_detection_datasource.dart';
import 'package:smart_parking/features/face_recognition/data/repositories/face_validation_repository_impl.dart';
import 'package:smart_parking/features/face_recognition/domain/usecases/validate_face_image.dart';
import 'package:smart_parking/features/face_recognition/presentations/bloc/face_capture_bloc.dart';
import 'package:smart_parking/features/face_recognition/presentations/pages/face_camera_capture_page.dart';

class FaceRegisterofilePage extends StatelessWidget {
  const FaceRegisterofilePage({super.key});

  Future<void> _openFaceCamera(BuildContext context) async {
    // 1. Khởi tạo Data Source
    final dataSource = FaceDetectionDataSource();

    // 2. Khởi tạo Repository
    final repository = FaceValidationRepositoryImpl(dataSource: dataSource);

    // 3. Khởi tạo Use Case
    final validateFaceImage = ValidateFaceImage(repository);

    try {
      // 4. Mở màn hình camera và cung cấp BLoC
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) =>
                FaceCaptureBloc(validateFaceImage: validateFaceImage),
            child: const FaceCameraCapturePage(),
          ),
        ),
      );
    } finally {
      // 5. Giải phóng tài nguyên ML Kit khi đóng màn hình
      await dataSource.dispose();
    }
  }

  static const List<_FaceConditionItem> _conditions = [
    _FaceConditionItem(
      icon: Icons.center_focus_strong_outlined,
      title: "1. Khuôn mặt trong khung hình & nhìn thẳng",
      subtitle: "Đưa mặt vào giữa khung, nhìn thẳng vào camera.",
    ),
    _FaceConditionItem(
      icon: Icons.wb_sunny_outlined,
      title: "2. Ánh sáng đầy đủ",
      subtitle: "Đảm bảo đủ sáng, tránh nơi tối hoặc bị ngược sáng.",
    ),
    _FaceConditionItem(
      icon: Icons.visibility_off_outlined,
      title: "3. Không đeo kính, khẩu trang, mũ",
      subtitle: "Tháo kính, khẩu trang và nón/mũ để lộ rõ toàn bộ khuôn mặt.",
    ),
    _FaceConditionItem(
      icon: Icons.face_outlined,
      title: "4. Không nghiêng hoặc quay góc",
      subtitle: "Giữ đầu thẳng, không cúi, ngước hoặc quay sang trái/phải.",
    ),
    _FaceConditionItem(
      icon: Icons.wallpaper_outlined,
      title: "5. Nền đơn giản & không có người phía sau",
      subtitle:
          "Chọn phông nền gọn gàng, không có người khác xuất hiện sau lưng.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text(
          "Đăng kí nhận diện khuôn mặt",
          style: TextStyle(
            color: AppColors.surface,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        foregroundColor: AppColors.surface,
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Vui lòng đáp ứng đủ 5 điều kiện dưới đây trước khi mở camera chụp ảnh đăng ký.",
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.35,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                "Điều kiện chụp ảnh hợp lệ",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.separated(
                  itemCount: _conditions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = _conditions[index];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              item.icon,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  item.subtitle,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    height: 1.35,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => _openFaceCamera(context),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text(
                    "Mở camera chụp ảnh",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaceConditionItem {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FaceConditionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}
