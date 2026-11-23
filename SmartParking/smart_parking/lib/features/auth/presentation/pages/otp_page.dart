import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';

import 'package:smart_parking/core/routes/app_routes.dart';
import 'package:smart_parking/core/theme/app_colors.dart';
import 'package:smart_parking/core/theme/app_spacing.dart';
import 'package:smart_parking/core/theme/app_text_styles.dart';
import 'package:smart_parking/core/widgets/app_button.dart';

enum OtpFlow { login, signup, recoveryEmail, recoveryPhone }

class OtpPage extends StatefulWidget {
  final String destination;
  final OtpFlow flow;

  final Future<bool> Function(String code)? onVerify;
  final Future<bool> Function()? onResend;
  final VoidCallback? onVerified;

  const OtpPage({
    super.key,
    required this.destination,
    required this.flow,
    this.onVerify,
    this.onResend,
    this.onVerified,
  });

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final otpController = TextEditingController();
  final otpFocusNode = FocusNode();

  Timer? _timer;

  int _secondsRemaining = 180;

  bool isLoading = false;
  bool isResending = false;

  // Login, Signup và Recovery Email đều dùng email.
  bool get isEmailOtp =>
      widget.flow == OtpFlow.login ||
      widget.flow == OtpFlow.signup ||
      widget.flow == OtpFlow.recoveryEmail;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    otpController.dispose();
    otpFocusNode.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // COUNTDOWN
  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  String get formattedTime {
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  // VERIFY OTP
  Future<void> _verifyOtp() async {
    if (isLoading || isResending) return;

    final code = otpController.text.trim();

    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      _showMessage('Vui lòng nhập đủ 6 chữ số OTP');
      return;
    }

    if (widget.onVerify == null) {
      _showMessage('Chưa kết nối chức năng xác thực OTP');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      isLoading = true;
    });

    try {
      // Callback gọi AuthViewModel -> UseCase -> Supabase.
      final success = await widget.onVerify!(code);

      if (!mounted) return;

      if (!success) {
        _showMessage('Xác thực thất bại. Vui lòng kiểm tra mã OTP.');
        return;
      }

      // Callback điều hướng do Login/Signup truyền vào.
      if (widget.onVerified != null) {
        widget.onVerified!();
        return;
      }

      // Điều hướng mặc định chỉ cho Login/Signup.
      switch (widget.flow) {
        case OtpFlow.login:
        case OtpFlow.signup:
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.home,
            (route) => false,
          );
          break;

        case OtpFlow.recoveryEmail:
        case OtpFlow.recoveryPhone:
          _showMessage('Chức năng khôi phục chưa được triển khai');
          break;
      }
    } catch (e) {
      _showMessage('Có lỗi xảy ra: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // RESEND OTP
  Future<void> _resendOtp() async {
    if (isLoading || isResending || _secondsRemaining > 0) {
      return;
    }

    if (widget.onResend == null) {
      _showMessage('Chưa kết nối chức năng gửi lại OTP');
      return;
    }

    setState(() {
      isResending = true;
    });

    try {
      final success = await widget.onResend!();

      if (!mounted) return;

      if (!success) {
        _showMessage('Không thể gửi lại mã OTP');
        return;
      }

      otpController.clear();

      setState(() {
        _secondsRemaining = 180;
      });

      _startTimer();

      _showMessage('Đã gửi lại mã xác thực');
    } catch (e) {
      _showMessage('Gửi lại OTP thất bại: $e');
    } finally {
      if (mounted) {
        setState(() {
          isResending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // BACKGROUND BLUR
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Image.asset(
                'assets/images/bg_login.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // LIGHT OVERLAY
          Positioned.fill(
            child: ColoredBox(color: Colors.white.withValues(alpha: 0.20)),
          ),

          // OTP CARD
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
                    child: Center(child: _buildOtpCard()),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpCard() {
    final pinTheme = PinTheme(
      width: 48,
      height: 56,
      textStyle: AppTextStyles.headingLarge.copyWith(
        color: AppColors.navy,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // BACK BUTTON
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              icon: const Icon(
                Icons.arrow_back,
                color: AppColors.navy,
                size: 26,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // OTP ILLUSTRATION
          _buildOtpIllustration(),

          const SizedBox(height: AppSpacing.xl),

          // TITLE
          Text(
            isEmailOtp ? 'Xác thực email' : 'Nhập mã OTP',
            textAlign: TextAlign.center,
            style: AppTextStyles.headingLarge.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // DESCRIPTION
          Text(
            isEmailOtp
                ? 'Chúng tôi đã gửi mã xác thực đến email'
                : 'Chúng tôi đã gửi mã xác thực đến số điện thoại',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.secondary,
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          // DESTINATION
          Text(
            widget.destination,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          // OTP INPUT
          LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;

              final pinWidth = ((availableWidth - 40) / 6)
                  .clamp(32.0, 48.0)
                  .toDouble();

              return Pinput(
                length: 6,
                controller: otpController,
                focusNode: otpFocusNode,
                keyboardType: TextInputType.number,
                enabled: !isLoading && !isResending,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                defaultPinTheme: pinTheme.copyWith(width: pinWidth),
                focusedPinTheme: pinTheme.copyWith(
                  width: pinWidth,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.primary, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                submittedPinTheme: pinTheme.copyWith(width: pinWidth),
                separatorBuilder: (index) => const SizedBox(width: 8),
                onCompleted: (pin) {
                  FocusScope.of(context).unfocus();
                },
              );
            },
          ),

          const SizedBox(height: AppSpacing.xl),

          // COUNTDOWN
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 5,
            children: [
              Text(
                'Có thể gửi lại mã sau',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.secondary,
                ),
              ),
              Text(
                formattedTime,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // RESEND OTP
          Text(
            'Không nhận được mã?',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.secondary,
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          TextButton(
            onPressed: _secondsRemaining == 0 && !isResending && !isLoading
                ? _resendOtp
                : null,
            child: Text(
              isResending
                  ? 'Đang gửi lại...'
                  : _secondsRemaining > 0
                  ? 'Gửi lại mã ($formattedTime)'
                  : 'Gửi lại mã',
              style: AppTextStyles.bodyMedium.copyWith(
                color: _secondsRemaining == 0 && !isResending && !isLoading
                    ? AppColors.primary
                    : AppColors.secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // VERIFY BUTTON
          SizedBox(
            width: double.infinity,
            height: 52,
            child: AppButtons(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              borderRadius: BorderRadius.circular(14),
              onPressed: () {
                if (isLoading || isResending) return;
                _verifyOtp();
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
                            'Xác thực',
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
        ],
      ),
    );
  }

  Widget _buildOtpIllustration() {
    return SizedBox(
      width: 130,
      height: 130,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 115,
            height: 115,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
          ),

          Transform.rotate(
            angle: -0.10,
            child: Icon(
              isEmailOtp
                  ? Icons.mark_email_read_rounded
                  : Icons.phone_iphone_rounded,
              size: 96,
              color: AppColors.navy,
            ),
          ),

          Positioned(
            right: 0,
            top: 42,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: const Text(
                '***',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
