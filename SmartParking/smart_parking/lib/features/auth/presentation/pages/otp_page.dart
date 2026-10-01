import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_parking/core/theme/app_theme.dart';

class OtpPage extends StatefulWidget {
  const OtpPage({super.key});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final TextEditingController otpController = TextEditingController();
  final FocusNode otpFocusNode = FocusNode();

  Timer? timer;

  int seconds = 60;
  bool isLoading = false;

  String phone = '';
  String type = 'login';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map<String, dynamic>) {
      phone = args['phone']?.toString() ?? '';
      type = args['type']?.toString() ?? 'login';
    }
  }

  @override
  void initState() {
    super.initState();

    startTimer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      otpFocusNode.requestFocus();
    });
  }

  void startTimer() {
    timer?.cancel();

    seconds = 45;

    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      if (seconds <= 0) {
        timer?.cancel();
        return;
      }

      setState(() {
        seconds--;
      });
    });
  }

  String get maskedPhone {
    if (phone.isEmpty) {
      return '0912 *** 678';
    }

    String value = phone.replaceAll(' ', '');

    if (value.length >= 10) {
      return '${value.substring(0, 3)} *** ${value.substring(value.length - 3)}';
    }

    return value;
  }

  Future<void> verifyOtp() async {
    final otp = otpController.text.trim();

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đầy đủ mã OTP gồm 6 chữ số'),
        ),
      );

      otpFocusNode.requestFocus();
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      isLoading = true;
    });

    // TODO:
    // Xác thực OTP bằng Supabase / FastAPI tại đây.
    await Future.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    if (type == 'register') {
      // Sau này có thể đổi thành:
      //
      // Navigator.pushReplacementNamed(
      //   context,
      //   '/profile-setup',
      // );
      //
      // để người dùng cập nhật khuôn mặt + xe.

      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } else {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    }
  }

  Future<void> resendOtp() async {
    if (seconds > 0) return;

    setState(() {
      seconds = 45;
    });

    startTimer();

    // TODO:
    // Gửi lại OTP qua Supabase / Backend.

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã gửi lại mã OTP đến $maskedPhone')),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    otpController.dispose();
    otpFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),

      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,

          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),

          child: Column(
            children: [
              /// ================================
              /// HEADER
              /// ================================
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  ),

                  const SizedBox(width: 12),

                  const Expanded(
                    child: Text(
                      'Xác thực OTP',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 36),

              /// ================================
              /// OTP ICON
              /// ================================
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFDADA),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Icon(
                      Icons.verified_user_rounded,
                      size: 48,
                      color: AppColors.secondary,
                    ),
                  ),

                  Positioned(
                    right: -6,
                    bottom: -5,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.sms_outlined,
                        size: 18,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              const Text(
                'Nhập mã xác thực',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800),
              ),

              const SizedBox(height: 10),

              Text(
                'Mã OTP gồm 6 chữ số đã được gửi đến ',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),

              const SizedBox(height: 6),

              /// PHONE
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      maskedPhone,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(width: 5),
                  ],
                ),
              ),

              const SizedBox(height: 38),

              /// ================================
              /// OTP INPUT
              /// ================================
              GestureDetector(
                onTap: () {
                  otpFocusNode.requestFocus();
                },
                child: Stack(
                  children: [
                    /// 6 OTP BOXES
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (index) {
                        final otp = otpController.text;

                        final value = index < otp.length ? otp[index] : '';

                        final isActive = index == otp.length;

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 48,
                          height: 58,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFFFFF0F2)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isActive
                                  ? AppColors.secondary
                                  : Colors.grey.shade200,
                              width: isActive ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            value,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        );
                      }),
                    ),

                    /// INVISIBLE TEXT FIELD
                    Opacity(
                      opacity: 0,
                      child: TextField(
                        controller: otpController,
                        focusNode: otpFocusNode,
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        onChanged: (value) {
                          setState(() {});

                          if (value.length == 6) {
                            verifyOtp();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 26),

              /// ================================
              /// COUNTDOWN
              /// ================================
              if (seconds > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 17,
                      color: AppColors.secondary,
                    ),

                    const SizedBox(width: 6),

                    Text(
                      'Gửi lại mã sau ',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),

                    Text(
                      '00:${seconds.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Chưa nhận được mã?',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),

                    TextButton(
                      onPressed: resendOtp,
                      child: const Text(
                        'Gửi lại OTP',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 32),

              /// ================================
              /// VERIFY BUTTON
              /// ================================
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoading ? null : verifyOtp,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,

                    foregroundColor: Colors.white,

                    disabledBackgroundColor: AppColors.secondary.withOpacity(
                      0.5,
                    ),

                    elevation: 3,

                    shadowColor: AppColors.secondary.withOpacity(0.25),

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
                              'Tiếp tục',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 24),

              /// SECURITY FOOTER
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
                    'Mã OTP được mã hóa và bảo mật',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
