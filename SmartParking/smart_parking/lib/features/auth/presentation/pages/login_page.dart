import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_parking/core/theme/app_theme.dart';
import 'package:smart_parking/core/widget/common.dart';
import 'package:smart_parking/features/auth/presentation/pages/otp_page.dart';
import 'package:smart_parking/features/auth/presentation/pages/register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final phoneController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  Future<void> handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const OtpPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),

      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,

          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),

          child: Form(
            key: _formKey,

            child: Column(
              children: [
                const SizedBox(height: 30),

                SectionCard(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 28,
                      horizontal: 16,
                    ),

                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,

                          decoration: BoxDecoration(
                            color: AppColors.primary,

                            borderRadius: BorderRadius.circular(24),

                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.18),
                                blurRadius: 22,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),

                          child: const Icon(
                            Icons.local_parking_rounded,
                            color: Colors.white,
                            size: 44,
                          ),
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          'Smart Parking',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.3,
                            color: Colors.grey,
                          ),
                        ),

                        const SizedBox(height: 6),

                        const Text(
                          'Đăng nhập tài khoản',
                          textAlign: TextAlign.center,

                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                SectionCard(
                  child: Padding(
                    padding: const EdgeInsets.all(4),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,

                          children: [
                            const Text(
                              'Số điện thoại',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        TextFormField(
                          controller: phoneController,

                          keyboardType: TextInputType.phone,

                          textInputAction: TextInputAction.done,

                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],

                          decoration: const InputDecoration(
                            hintText: 'Nhập số điện thoại của bạn',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                            ),
                          ),

                          validator: (value) {
                            final phone = value?.trim() ?? '';

                            if (phone.isEmpty) {
                              return 'Vui lòng nhập số điện thoại';
                            }

                            if (!RegExp(r'^0\d{9}$').hasMatch(phone)) {
                              return 'Số điện thoại phải gồm 10 chữ số';
                            }

                            return null;
                          },

                          onFieldSubmitted: (_) {
                            if (!isLoading) {
                              handleLogin();
                            }
                          },
                        ),

                        const SizedBox(height: 25),

                        SizedBox(
                          width: double.infinity,
                          height: 56,

                          child: ElevatedButton(
                            onPressed: isLoading ? null : handleLogin,

                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,

                              foregroundColor: Colors.white,

                              disabledBackgroundColor: AppColors.secondary
                                  .withValues(alpha: 0.5),

                              elevation: 3,

                              shadowColor: AppColors.secondary.withValues(
                                alpha: 0.3,
                              ),

                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),

                            child: isLoading
                                ? const SizedBox(
                                    width: 23,
                                    height: 23,

                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,

                                    children: [
                                      Text(
                                        'Đăng nhập bằng mã OTP',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [
                    Text(
                      'Chưa có tài khoản?',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),

                    const SizedBox(width: 2),

                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        );
                      },

                      child: Text(
                        'Đăng ký ngay',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                /// =============================
                /// SECURITY FOOTER
                /// =============================
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 15,
                      color: Colors.grey.shade500,
                    ),

                    const SizedBox(width: 5),

                    Text(
                      'Thông tin đăng nhập được bảo mật',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
