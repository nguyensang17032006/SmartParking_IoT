import 'package:flutter/material.dart';
import 'package:smart_parking/core/theme/app_theme.dart';

class ParkingFeedbackPanel extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final bool loading;
  final VoidCallback? onRetry;
  const ParkingFeedbackPanel({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.info_outline_rounded,
    this.loading = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE6EBEF)),
    ),
    child: Column(
      children: [
        if (loading)
          const SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.greenDark,
            ),
          )
        else
          Icon(icon, size: 36, color: AppColors.textMuted),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            height: 1.5,
            color: AppColors.textMuted,
          ),
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Thử lại'),
          ),
        ],
      ],
    ),
  );
}
