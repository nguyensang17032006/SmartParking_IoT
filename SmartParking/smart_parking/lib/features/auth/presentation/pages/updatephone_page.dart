import 'package:flutter/material.dart';
import 'package:smart_parking/core/theme/app_colors.dart';
import 'package:smart_parking/core/theme/app_spacing.dart';
import 'package:smart_parking/core/theme/app_text_styles.dart';
import 'package:smart_parking/core/widgets/app_button.dart';
import 'package:smart_parking/features/auth/widgets/auth_layout.dart';
import 'package:smart_parking/core/routes/app_routes.dart';

class UpdatePhonePage extends StatefulWidget {
  final String recoveryToken;

  const UpdatePhonePage({super.key, required this.recoveryToken});

  @override
  State<UpdatePhonePage> createState() => _UpdatePhonePageState();
}

class _UpdatePhonePageState extends State<UpdatePhonePage> {
  final _formKey = GlobalKey<FormState>();
  final phoneController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  String? validatePhone(String? value) {
    final phone = value?.trim() ?? '';

    if (phone.isEmpty) {
      return 'Vui lòng nhập số điện thoại mới';
    }

    if (!RegExp(r'^0\d{9}$').hasMatch(phone)) {
      return 'Số điện thoại phải có 10 chữ số, bắt đầu bằng 0';
    }

    return null;
  }

  Future<void> handleUpdatePhone() async {
    if (isLoading) return;

    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    final phone = phoneController.text.trim();

    setState(() => isLoading = true);

    try {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa kết nối API gửi OTP đến số điện thoại mới'),
        ),
      );

      //Khi API thành công, chuyển sang OtpPage:

      Navigator.pushNamed(
        context,
        AppRoutes.otp,
        arguments: {
          'phone': phone,
          'flow': 'recoveryPhone',
          'recoveryToken': widget.recoveryToken,
        },
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(child: _buildUpdatePhoneForm());
  }

  Widget _buildUpdatePhoneForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xxs),

          Text(
            'Đổi số điện thoại',
            style: AppTextStyles.headingLarge.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          Text(
            'Email đã được xác thực. Hãy nhập số điện thoại mới để tiếp tục khôi phục tài khoản.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.secondary,
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          Text(
            'Số điện thoại mới',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

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

          const SizedBox(height: AppSpacing.md),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: AppButtons(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              borderRadius: BorderRadius.circular(14),
              onPressed: () {
                if (isLoading) return;
                handleUpdatePhone();
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

          const SizedBox(height: AppSpacing.xxs),

          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.recovery);
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),

                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Quay lại',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
