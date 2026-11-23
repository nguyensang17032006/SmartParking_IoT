
import 'package:flutter/material.dart';

import 'package:smart_parking/core/theme/app_spacing.dart';
import 'package:smart_parking/core/theme/app_text_styles.dart';

import '../../widgets/profile_menu_item.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const navy = Color(0xFF111A31);
  static const secondary = Color(0xFF8791A4);

  void showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$feature sẽ được phát triển sau',
          style: AppTextStyles.bodyMedium,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => showComingSoon(context, 'Cài đặt'),
              ),
            ),

            const CircleAvatar(
              radius: 43,
              backgroundColor: Color(0xFFE5EAF3),
              child: Icon(
                Icons.person_outline,
                size: 52,
                color: secondary,
              ),
            ),

            AppSpacing.gapSM,

            Text(
              'Trần Quốc Khánh',
              style: AppTextStyles.headingSmall.copyWith(
                color: navy,
              ),
            ),

            AppSpacing.gapXXS,

            Text(
              '+84 912 345 678',
              style: AppTextStyles.bodySmall.copyWith(
                color: secondary,
              ),
            ),

            AppSpacing.gapXXL,

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 18,
                  ),
                ],
              ),
              child: Column(
                children: [
                  ProfileMenuItem(
                    icon: Icons.person_outline,
                    title: 'Thông tin cá nhân',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditProfilePage(),
                        ),
                      );
                    },
                  ),

                  const Divider(height: 1),

                  ProfileMenuItem(
                    icon: Icons.directions_car_outlined,
                    title: 'Phương tiện của tôi',
                    onTap: () => showComingSoon(
                      context,
                      'Phương tiện của tôi',
                    ),
                  ),

                  const Divider(height: 1),

                  ProfileMenuItem(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Ví của tôi',
                    trailingText: '120.000đ',
                    onTap: () => showComingSoon(
                      context,
                      'Ví của tôi',
                    ),
                  ),

                  const Divider(height: 1),

                  ProfileMenuItem(
                    icon: Icons.local_offer_outlined,
                    title: 'Ưu đãi của tôi',
                    onTap: () => showComingSoon(
                      context,
                      'Ưu đãi',
                    ),
                  ),

                  const Divider(height: 1),

                  ProfileMenuItem(
                    icon: Icons.help_outline,
                    title: 'Trung tâm hỗ trợ',
                    onTap: () => showComingSoon(
                      context,
                      'Hỗ trợ',
                    ),
                  ),

                  const Divider(height: 1),

                  ProfileMenuItem(
                    icon: Icons.settings_outlined,
                    title: 'Cài đặt',
                    onTap: () => showComingSoon(
                      context,
                      'Cài đặt',
                    ),
                  ),

                  const Divider(height: 1),

                  ProfileMenuItem(
                    icon: Icons.logout,
                    title: 'Đăng xuất',
                    onTap: () => showComingSoon(
                      context,
                      'Đăng xuất',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
