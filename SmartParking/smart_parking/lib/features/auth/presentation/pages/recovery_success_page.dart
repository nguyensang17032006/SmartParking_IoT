
import 'package:flutter/material.dart';
import 'package:smart_parking/core/routes/app_routes.dart';
import 'package:smart_parking/core/theme/app_colors.dart';
import 'package:smart_parking/core/theme/app_spacing.dart';
import 'package:smart_parking/core/theme/app_text_styles.dart';
import 'package:smart_parking/core/widgets/app_button.dart';
import 'package:smart_parking/features/auth/widgets/auth_layout.dart';

class RecoverySuccessPage extends StatelessWidget {


  const RecoverySuccessPage({
    super.key,
    
  });

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.md),

          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F8EE),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF22A765),
              size: 76,
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          Text(
            'Khôi phục thành công!',
            textAlign: TextAlign.center,
            style: AppTextStyles.headingLarge.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          Text(
            'Số điện thoại đăng nhập của bạn đã được cập nhật thành công.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.secondary,
            ),
          ),

         

      

          const SizedBox(height: AppSpacing.xl),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: AppButtons(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              borderRadius: BorderRadius.circular(14),
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.login,
                  (route) => false,
                );
              },
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Đăng nhập ngay',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward, size: 20),
                ],
              ),
            ),
          ),

    
        ],
      ),
    );
  }
}
