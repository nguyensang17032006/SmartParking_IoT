import 'package:flutter/material.dart';
import 'package:smart_parking/features/auth/widgets/auth_layout.dart';
import 'package:smart_parking/core/theme/app_colors.dart';
import 'package:smart_parking/core/theme/app_spacing.dart';
import 'package:smart_parking/core/widgets/app_button.dart';
import 'package:smart_parking/core/theme/app_text_styles.dart';

class RecoveryPage extends StatefulWidget {
  const RecoveryPage({super.key});

  @override
  State<RecoveryPage> createState() => _RecoveryPageState();
}

class _RecoveryPageState extends State<RecoveryPage> {
  final emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  String? validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Vui lòng nhập email';
    }

    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Vui lòng nhập email hợp lệ';
    }

    return null;
  }

  Future<void> handleRecovery() async {
    if (isLoading) return;
    if (!_formKey.currentState!.validate()) return;
    final email = emailController.text.trim();

    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập email hợp lệ')),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      isLoading = true;
    });

    // TODO: Gọi API gửi OTP khôi phục qua email.
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    // TODO: Chuyển sang OTP email sau khi API gửi mã thành công.
    // OtpPage hiện tại cần hỗ trợ flow recovery và email.
    Navigator.pushNamed(
      context,
      '/otp',
      arguments: {'email': email, 'flow': 'recoveryEmail'},
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(child: _buildRecoveryForm());
  }

  Widget _buildRecoveryForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TITLE
          Text(
            'Khôi phục tài khoản',
            style: AppTextStyles.headingLarge.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w800,
            ),
          ),

          // SUBTITLE
          Text(
            'Nhập email đã đăng ký để nhận mã xác thực khôi phục tài khoản',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.secondary,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          _buildLabel('Email'),
          const SizedBox(height: AppSpacing.xxs),

          // EMAIL INPUT
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            validator: validateEmail,
            autovalidateMode: AutovalidateMode.disabled,
            decoration: InputDecoration(
              hintText: 'Nhập email của bạn',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // SEND OTP BUTTON
          SizedBox(
            width: double.infinity,
            height: 50,
            child: AppButtons(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              borderRadius: const BorderRadius.all(Radius.circular(14)),
              onPressed: () {
                if (isLoading) return;
                handleRecovery();
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
                            'Gửi mã xác thực',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_forward, size: 20),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          // DIVIDER
          const Row(
            children: [
              Expanded(child: Divider(color: Color(0xFFD6D9E0))),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'hoặc',
                  style: TextStyle(fontSize: 13, color: AppColors.secondary),
                ),
              ),
              Expanded(child: Divider(color: Color(0xFFD6D9E0))),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // BACK TO LOGIN
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back, size: 20),
              label: Text(
                'Quay lại đăng nhập',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),
        ],
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
