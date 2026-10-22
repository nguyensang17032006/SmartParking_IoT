import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:smart_parking/core/routes/app_routes.dart';
import 'package:smart_parking/core/theme/app_colors.dart';
import 'package:smart_parking/core/theme/app_spacing.dart';
import 'package:smart_parking/core/theme/app_text_styles.dart';
import 'package:smart_parking/core/widgets/app_button.dart';
import 'package:smart_parking/features/auth/widgets/textfield.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();

  bool isLoading = false;
  bool agreeTerms = false;

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (!agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đồng ý với điều khoản sử dụng')),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() => isLoading = true);

    // TODO: Gọi API gửi OTP tại đây.
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    setState(() => isLoading = false);

    Navigator.pushNamed(
      context,
      AppRoutes.otp,
      arguments: {
        'phone': phoneController.text.trim(),
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'flow': 'signup',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // 1. BACKGROUND PHỦ TOÀN MÀN HÌNH
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Image.asset(
                'assets/images/bg_login.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 2. LỚP PHỦ GIÚP FORM DỄ ĐỌC
          Positioned.fill(
            child: ColoredBox(color: Colors.white.withValues(alpha: 0.20)),
          ),

          // FORM ĐĂNG KÝ NẰM TRÊN BACKGROUND
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 40,
                    ),
                    child: Center(child: _buildSignUpCard()),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        12,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BACK BUTTON
            IconButton(
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              alignment: Alignment.centerLeft,
              icon: const Icon(
                Icons.arrow_back,
                color: AppColors.navy,
                size: 24,
              ),
            ),

            const SizedBox(height: 8),

            // TITLE
            Text(
              'Tạo tài khoản',
              style: AppTextStyles.headingLarge.copyWith(
                color: AppColors.navy,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              'Điền thông tin để đăng ký tài khoản',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.secondary,
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // FULL NAME
            _buildLabel('Họ và tên'),
            const SizedBox(height: AppSpacing.xs),

            CustomTextField(
              prefixIcon: Icons.person_outline,
              controller: nameController,
              hintText: 'Nhập họ và tên',
            ),

            const SizedBox(height: AppSpacing.md),

            // PHONE
            _buildLabel('Số điện thoại'),
            const SizedBox(height: AppSpacing.xs),

            CustomTextField(
              prefixIcon: Icons.phone_outlined,
              controller: phoneController,
              hintText: 'Nhập số điện thoại của bạn',
              isPhoneNumber: true,
            ),

            const SizedBox(height: AppSpacing.md),

            // EMAIL
            _buildLabel('Email'),
            const SizedBox(height: AppSpacing.xs),

            CustomTextField(
              prefixIcon: Icons.email_outlined,
              controller: emailController,
              hintText: 'Nhập địa chỉ email',
            ),

            const SizedBox(height: AppSpacing.md),

            // TERMS
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Checkbox(
                  value: agreeTerms,
                  activeColor: AppColors.primary,
                  onChanged: (value) {
                    setState(() {
                      agreeTerms = value ?? false;
                    });
                  },
                ),
                Expanded(
                  child: Text(
                    'Tôi đồng ý với Điều khoản sử dụng và '
                    'Chính sách bảo mật của Smart Parking',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            // CONTINUE BUTTON
            SizedBox(
              width: double.infinity,
              height: 52,
              child: AppButtons(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                borderRadius: BorderRadius.circular(14),
                onPressed: () {
                  if (isLoading) return;
                  handleSignUp();
                },
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Tiếp tục',
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

            const SizedBox(height: AppSpacing.md),

            // LOGIN LINK
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Đã có tài khoản? ',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.secondary,
                        ),
                      ),
                      TextSpan(
                        text: 'Đăng nhập',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.navy,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
