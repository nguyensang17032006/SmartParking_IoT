import 'package:flutter/material.dart';
import 'package:smart_parking/core/theme/app_colors.dart';
import 'package:smart_parking/core/theme/app_spacing.dart';
import 'package:smart_parking/core/theme/app_text_styles.dart';

class AuthLayout extends StatelessWidget {
  final Widget child;

  const AuthLayout({
    super.key,
    required this.child,
  });

  static const double keyboardGap = 8;

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    final keyboardOpen = keyboardHeight > 0;
    final topPadding = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      resizeToAvoidBottomInset: false,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final height = constraints.maxHeight;
          final bgHeight = height * 0.56;

          final cardBottom =
              keyboardOpen ? keyboardHeight + keyboardGap : 70.0;

          final cardMaxHeight = keyboardOpen
              ? height - keyboardHeight - keyboardGap - topPadding - 8
              : height * 0.58;

          return Stack(
            children: [
              const Positioned.fill(
                child: ColoredBox(color: Color(0xFFF5F8FC)),
              ),

              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: bgHeight,
                child: Image.asset(
                  'assets/images/bg_login.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),

              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: _buildBranding(),
                ),
              ),

              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                left: 16,
                right: 16,
                bottom: cardBottom,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight:
                        cardMaxHeight > 0 ? cardMaxHeight : height,
                  ),
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: _buildCard(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBranding() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/logo.png',
          width: 90,
          height: 90,
          fit: BoxFit.contain,
        ),
        Text(
          'Smart Parking',
          textAlign: TextAlign.center,
          style: AppTextStyles.headingLarge.copyWith(
            color: AppColors.navy,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Đỗ xe thông minh, an tâm mỗi hành trình',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: const Color(0xFF53657A),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 24,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}