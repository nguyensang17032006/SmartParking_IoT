import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:smart_parking/core/routes/app_routes.dart';
import 'package:smart_parking/core/theme/app_spacing.dart';
import 'package:smart_parking/core/theme/app_colors.dart';
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

  bool get isEmailOtp => widget.flow == OtpFlow.recoveryEmail;

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _verifyOtp() {
    FocusScope.of(context).unfocus();

    switch (widget.flow) {
      case OtpFlow.recoveryEmail:
        Navigator.pushNamed(
          context,
          AppRoutes.updatePhone,
          arguments: {'recoveryToken': 'ui-only'},
        );
        break;

      case OtpFlow.recoveryPhone:
        Navigator.pushNamed(
          context,
          AppRoutes.recoverySuccess,
          arguments: {'phone': widget.destination},
        );
        break;

      case OtpFlow.login:
        // TODO: Điều hướng đến HomePage.
        break;

      case OtpFlow.signup:
        // TODO: Điều hướng sau đăng ký.
        break;
    }
  }

  Future<void> _resendOtp() async {
    if (isResending || _secondsRemaining > 0) return;
    if (widget.onResend == null) {
      _showMessage('Chưa kết nối API gửi lại OTP');
      return;
    }
    setState(() => isResending = true);
    bool sent = false;
    try {
      sent = await widget.onResend!();
    } catch (_) {
      if (mounted) _showMessage('Không thể gửi lại OTP');
      return;
    } finally {
      if (mounted) setState(() => isResending = false);
    }
    if (!mounted) return;
    if (sent) {
      otpController.clear();
      setState(() => _secondsRemaining = 180);
      _startTimer();
      _showMessage('Đã gửi lại mã xác thực');
    } else {
      _showMessage('Gửi lại mã thất bại');
    }
  }

  String get formattedTime {
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    otpController.dispose();
    otpFocusNode.dispose();
    super.dispose();
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
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              icon: const Icon(
                Icons.arrow_back,
                color: AppColors.navy,
                size: 26,
              ),
            ),
          ),

          SizedBox(height: AppSpacing.sm),
          // OTP ILLUSTRATION
          _buildOtpIllustration(),

          SizedBox(height: AppSpacing.xl),

          // TITLE
          Text(
            isEmailOtp ? 'Xác thực email' : 'Nhập mã OTP',
            textAlign: TextAlign.center,
            style: AppTextStyles.headingLarge.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w800,
            ),
          ),

          SizedBox(height: AppSpacing.sm),

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

          SizedBox(height: AppSpacing.xs),

          Text(
            widget.destination,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w700,
            ),
          ),

          SizedBox(height: AppSpacing.xxl),

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

          SizedBox(height: AppSpacing.xl),

          // COUNTDOWN
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 5,
            children: [
              Text(
                'Mã OTP có hiệu lực trong',
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

          SizedBox(height: AppSpacing.xl),

          // RESEND OTP
          Text(
            'Không nhận được mã?',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.secondary,
            ),
          ),

          SizedBox(height: AppSpacing.xs),

          TextButton(
            onPressed: _secondsRemaining == 0 && !isResending
                ? _resendOtp
                : null,
            child: Text(
              isResending
                  ? 'Đang gửi lại...'
                  : _secondsRemaining > 0
                  ? 'Gửi lại mã ($formattedTime)'
                  : 'Gửi lại mã',
              style: AppTextStyles.bodyMedium.copyWith(
                color: _secondsRemaining == 0
                    ? AppColors.primary
                    : AppColors.secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          SizedBox(height: AppSpacing.xl),

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
                if (isLoading) return;
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
