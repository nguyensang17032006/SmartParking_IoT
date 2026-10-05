import 'package:flutter/material.dart';
import 'package:smart_parking/core/theme/app_theme.dart';

import '../../../domain/entities/parking_overview.dart';

class ParkingAvailabilityCard extends StatelessWidget {
  final ParkingOverview overview;
  final VoidCallback onViewMap;
  const ParkingAvailabilityCard({
    super.key,
    required this.overview,
    required this.onViewMap,
  });

  @override
  Widget build(BuildContext context) {
    final free = overview.availableCount;
    final total = overview.totalCount;
    final occupied = overview.occupiedCount;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF263C50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(24),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CHỖ ĐỖ HIỆN TẠI',
                      style: TextStyle(
                        color: Color(0xFFB8C6D2),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      overview.isFull ? 'Bãi xe đã đầy' : '$free chỗ còn trống',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      overview.isFull
                          ? 'Theo dõi sơ đồ để biết khi có ô trống.'
                          : 'Xem sơ đồ và chọn vị trí phù hợp với bạn.',
                      style: const TextStyle(
                        color: Color(0xFFB8C6D2),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(16),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.local_parking_rounded,
                  color: AppColors.green,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: overview.occupancyRate,
              minHeight: 6,
              backgroundColor: Colors.white.withAlpha(24),
              color: overview.isFull ? AppColors.amber : AppColors.green,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            '$occupied/$total ô đang có xe',
            style: const TextStyle(fontSize: 12, color: Color(0xFFB8C6D2)),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onViewMap,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.map_outlined, size: 20),
              label: const Text(
                'Xem bản đồ bãi xe',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
