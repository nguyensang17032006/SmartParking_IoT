
import 'package:flutter/material.dart';

import 'package:smart_parking/core/theme/app_spacing.dart';
import 'package:smart_parking/core/theme/app_text_styles.dart';

class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailingText;
  final VoidCallback onTap;

  const ProfileMenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailingText,
  });

  static const navy = Color(0xFF111A31);
  static const primary = Color(0xFFF0194B);
  static const secondary = Color(0xFF8791A4);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
      ),
      leading: Icon(
        icon,
        size: 21,
        color: navy,
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          color: navy,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null)
            Text(
              trailingText!,
              style: AppTextStyles.bodySmall.copyWith(
                color: primary,
                fontWeight: FontWeight.w700,
              ),
            ),

          const SizedBox(width: AppSpacing.xs),

          const Icon(
            Icons.chevron_right,
            size: 20,
            color: secondary,
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
