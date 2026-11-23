import 'package:flutter/material.dart';
import 'package:smart_parking/core/routes/app_routes.dart';
import 'package:smart_parking/core/theme/app_colors.dart';
import 'package:smart_parking/core/theme/app_spacing.dart';
import 'package:smart_parking/core/theme/app_text_styles.dart';
import 'package:smart_parking/core/widgets/app_button.dart';
import 'package:smart_parking/features/auth/widgets/auth_layout.dart';
import 'package:smart_parking/features/auth/auth_dependencies.dart';
import 'package:smart_parking/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:smart_parking/features/auth/presentation/pages/otp_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late final AuthViewModel viewModel;
  bool isLoading = false;
  String? emailError;

  @override
  void initState() {
    super.initState();
    viewModel = createAuthViewModel();
  }

  @override
  void dispose() {
    emailController.dispose();
    viewModel.dispose();
    super.dispose();
  }

  String? validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Vui lòng nhập email';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Vui lòng nhập email hợp lệ';
    }
    return null;
  }

  Future<void> handleLogin() async {
    if (isLoading) return;
    setState(() => emailError = null);
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final email = emailController.text.trim();
    setState(() => isLoading = true);
    try {
      final allowed = await viewModel.canLogin(email);
      if (!mounted) return;
      if (!allowed) {
        setState(() => emailError = viewModel.errorMessage ?? 'Không thể đăng nhập');
        return;
      }
      final success = await viewModel.sendOtp(email: email, isSignup: false);
      if (!mounted) return;
      if (!success) {
        setState(() => emailError = viewModel.errorMessage ?? 'Không thể gửi mã OTP');
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpPage(
            destination: email,
            flow: OtpFlow.login,
            onVerify: (code) => viewModel.verifyOtp(email: email, token: code),
            onResend: () => viewModel.sendOtp(email: email, isSignup: false),
            onVerified: () => Navigator.pushNamedAndRemoveUntil(
              context, AppRoutes.mainLayout, (route) => false,
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => emailError = 'Đã xảy ra lỗi. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthLayout(child: _buildLoginForm());

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Đăng nhập', style: AppTextStyles.headingLarge.copyWith(
            color: AppColors.navy, fontWeight: FontWeight.w800,
          )),
          Text('Chào mừng bạn quay trở lại!', style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.secondary,
          )),
          const SizedBox(height: AppSpacing.sm),
          _buildLabel('Email'),
          const SizedBox(height: AppSpacing.xxs),
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validator: validateEmail,
            autovalidateMode: AutovalidateMode.disabled,
            forceErrorText: emailError,
            onChanged: (_) {
              if (emailError != null) setState(() => emailError = null);
            },
            decoration: InputDecoration(
              hintText: 'Nhập email của bạn',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.red, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.red, width: 1.5),
              ),
              errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: AppButtons(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              borderRadius: const BorderRadius.all(Radius.circular(14)),
              onPressed: () { if (!isLoading) handleLogin(); },
              child: isLoading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2,
                    ))
                  : Row(children: [
                      Expanded(child: Text('Đăng nhập bằng mã OTP',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                      )),
                      const Icon(Icons.arrow_forward, size: 20),
                    ]),
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          const Row(children: [
            Expanded(child: Divider(color: Color(0xFFD6D9E0))),
            Padding(padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('hoặc', style: TextStyle(fontSize: 13, color: AppColors.secondary)),
            ),
            Expanded(child: Divider(color: Color(0xFFD6D9E0))),
          ]),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.signup),
              icon: const Icon(Icons.person_add_alt_1_outlined, size: 20),
              label: Text('Đăng ký ngay', style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              )),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Text(text,
    style: AppTextStyles.bodyMedium.copyWith(
      color: AppColors.navy, fontWeight: FontWeight.w600,
    ),
  );
}
