import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:smart_parking/core/routes/app_routes.dart';
import 'package:smart_parking/core/theme/app_colors.dart';
import 'package:smart_parking/core/theme/app_spacing.dart';
import 'package:smart_parking/core/theme/app_text_styles.dart';
import 'package:smart_parking/core/widgets/app_button.dart';

import 'package:smart_parking/features/auth/widgets/textfield.dart';
import 'package:smart_parking/features/auth/auth_dependencies.dart';
import 'package:smart_parking/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:smart_parking/features/auth/presentation/pages/otp_page.dart';

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

  late final AuthViewModel viewModel;

  bool isLoading = false;
  bool agreeTerms = false;
  String? emailError;

  @override
  void initState() {
    super.initState();
    viewModel = createAuthViewModel();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    viewModel.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> handleSignUp() async {
    if (isLoading) return;

    if (!_formKey.currentState!.validate()) return;

    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final email = emailController.text.trim();

    // VALIDATE NAME
    if (name.isEmpty) {
      _showMessage('Vui lòng nhập họ và tên');
      return;
    }

    // VALIDATE PHONE
    if (!RegExp(r'^0\d{9}$').hasMatch(phone)) {
      _showMessage(
        'Số điện thoại phải có 10 chữ số, bắt đầu bằng 0',
      );
      return;
    }

    // VALIDATE EMAIL
    if (!RegExp(
      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
    ).hasMatch(email)) {
      _showMessage('Vui lòng nhập email hợp lệ');
      return;
    }

    // VALIDATE TERMS
    if (!agreeTerms) {
      _showMessage(
        'Vui lòng đồng ý với điều khoản sử dụng',
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      isLoading = true;
      emailError = null;
    });

    // Kiểm tra trạng thái email trước khi gửi OTP đăng ký.
    final allowed = await viewModel.canRegister(email);
    if (!mounted) return;
    if (!allowed) {
      setState(() {
        isLoading = false;
        emailError = viewModel.errorMessage ?? 'Không thể đăng ký';
      });
      return;
    }

    final success = await viewModel.sendOtp(
      email: email,
      isSignup: true,
    );

    if (!mounted) return;

    setState(() => isLoading = false);

    if (!success) {
      setState(() {
        emailError = viewModel.errorMessage ?? 'Không thể gửi mã OTP';
      });
      return;
    }

    // NAVIGATE TO OTP
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtpPage(
          destination: email,
          flow: OtpFlow.signup,

          // VERIFY OTP + SAVE PROFILE
          onVerify: (code) async {
            final verified = await viewModel.verifyOtp(
              email: email,
              token: code,
            );

            if (!verified) return false;

            final saved = await viewModel.saveProfile(
              fullName: name,
              phone: phone,
              email: email,
            );

            return saved;
          },

          // RESEND OTP
          onResend: () {
            return viewModel.sendOtp(
              email: email,
              isSignup: true,
            );
          },

          // SUCCESS
          onVerified: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.mainLayout,
              (route) => false,
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // BACKGROUND
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: 5,
                sigmaY: 5,
              ),
              child: Image.asset(
                'assets/images/bg_login.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // OVERLAY
          Positioned.fill(
            child: ColoredBox(
              color: Colors.white.withValues(alpha: 0.20),
            ),
          ),

          // SIGNUP FORM
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
                    child: Center(
                      child: _buildSignUpCard(),
                    ),
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
              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
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
            if (emailError != null) ...[
              const SizedBox(height: 6),
              Text(emailError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
            ],

            const SizedBox(height: AppSpacing.md),

            // TERMS
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Checkbox(
                  value: agreeTerms,
                  activeColor: AppColors.primary,
                  onChanged: isLoading
                      ? null
                      : (value) {
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

            // SIGNUP BUTTON
            SizedBox(
              width: double.infinity,
              height: 52,
              child: AppButtons(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                ),
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
                              style:
                                  AppTextStyles.bodyMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward,
                            size: 20,
                          ),
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
                        style:
                            AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.secondary,
                        ),
                      ),
                      TextSpan(
                        text: 'Đăng nhập',
                        style:
                            AppTextStyles.bodyMedium.copyWith(
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