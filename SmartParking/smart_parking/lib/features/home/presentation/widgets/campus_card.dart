
import 'package:flutter/material.dart';

import 'package:smart_parking/core/theme/app_colors.dart';
import 'package:smart_parking/core/theme/app_text_styles.dart';
import '../../domain/entities/campus.dart';

class CampusCard extends StatelessWidget {
  final Campus campus;
  final VoidCallback? onDirections;
  final VoidCallback onViewParking;

  const CampusCard({
    super.key,
    required this.campus,
    required this.onDirections,
    required this.onViewParking,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CAMPUS INFORMATION
          Row(
            children: [
              Container(
                width: 64,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EEF8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.apartment_rounded,
                  color: Color(0xFF2474D2),
                  size: 32,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      campus.name,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      campus.code,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      campus.address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          const Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFEDF0F4),
          ),

          const SizedBox(height: 12),

          // ACTION BUTTONS
          Row(
            children: [
              // DIRECTIONS BUTTON
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: onDirections,
                    icon: const Icon(
                      Icons.near_me_outlined,
                      size: 18,
                    ),
                    label: const Text('Đường đi'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      disabledForegroundColor: AppColors.secondary,
                      side: BorderSide(
                        color: onDirections != null
                            ? AppColors.primary
                            : const Color(0xFFDCE1E8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // VIEW PARKING BUTTON
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: onViewParking,
                    icon: const Icon(
                      Icons.directions_car_outlined,
                      size: 18,
                    ),
                    label: const Text('Xem bãi xe'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
