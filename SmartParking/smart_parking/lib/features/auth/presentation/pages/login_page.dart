import 'package:flutter/material.dart';
import 'package:smart_parking/features/auth/widgets/auth_layout.dart';
import 'package:smart_parking/core/theme/app_colors.dart';
import 'package:smart_parking/core/theme/app_spacing.dart';
import 'package:smart_parking/core/widgets/app_button.dart';
import 'package:smart_parking/core/theme/app_text_styles.dart';
import 'package:smart_parking/core/routes/app_routes.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  String? validatePhone(String? value) {
    final phone = value?.trim() ?? '';

    if (phone.isEmpty) {
      return 'Vui lòng nhập số điện thoại ';
    }

    if (!RegExp(r'^0\d{9}$').hasMatch(phone)) {
      return 'Số điện thoại phải có 10 chữ số, bắt đầu bằng 0';
    }

    return null;
  }

  Future<void> handleLogin() async {
    if (isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    final phone = phoneController.text.trim();

    FocusScope.of(context).unfocus();

    setState(() {
      isLoading = true;
    });

    // TODO: Thay bằng API gửi OTP đăng nhập.
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    Navigator.pushNamed(
      context,
      AppRoutes.otp,
      arguments: {'phone': phone, 'flow': 'login'},
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(child: _buildLoginForm());
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Đăng nhập',
            style: AppTextStyles.headingLarge.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w800,
            ),
          ),

          Text(
            'Chào mừng bạn quay trở lại!',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.secondary,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          _buildLabel('Số điện thoại'),
          const SizedBox(height: AppSpacing.xxs),

          TextFormField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            validator: validatePhone,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: InputDecoration(
              hintText: 'Nhập số điện thoại mới',
              prefixIcon: const Icon(Icons.phone_outlined),
              counterText: '',
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

          const SizedBox(height: AppSpacing.sm),

          // LOGIN BUTTON
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
                handleLogin();
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
                            'Đăng nhập bằng mã OTP',
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

          // RECOVERY
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.recovery);
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Khôi phục tài khoản?',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xxs),

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

          // SIGN UP
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.signup);
              },
              icon: const Icon(Icons.person_add_alt_1_outlined, size: 20),
              label: Text(
                'Đăng ký ngay',
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
