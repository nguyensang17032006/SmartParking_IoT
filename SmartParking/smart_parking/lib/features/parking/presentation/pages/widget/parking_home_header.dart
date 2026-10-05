import 'package:flutter/material.dart';
import 'package:smart_parking/core/theme/app_theme.dart';

class ParkingHomeHeader extends StatelessWidget {
  final bool mapOnly;
  const ParkingHomeHeader({super.key, this.mapOnly = false});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Row(
        children: [
          Icon(Icons.school_outlined, size: 16, color: AppColors.textMuted),
          SizedBox(width: 7),
          Expanded(
            child: Text(
              'BÃI XE TRƯỜNG ĐẠI HỌC',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Text(
        mapOnly ? 'Sơ đồ bãi xe' : 'Tìm chỗ đỗ của bạn',
        style: const TextStyle(
          fontSize: 28,
          height: 1.2,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        mapOnly
            ? 'Chọn một ô trống để xem đường từ cổng vào.'
            : 'Một chỗ đỗ thuận tiện, một ngày học thật tốt.',
        style: const TextStyle(
          fontSize: 14,
          height: 1.5,
          color: AppColors.textMuted,
        ),
      ),
    ],
  );
}
