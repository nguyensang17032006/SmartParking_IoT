import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final phone = TextEditingController();
  final otp = TextEditingController();
  bool register = false;
  bool sent = false;
  bool busy = false;
  int cooldown = 0;
  String? error;
  String? sentPhone;
  Timer? timer;

  String normalizePhone(String value) {
    var result = value.replaceAll(RegExp(r'[\s.-]'), '');
    if (result.startsWith('0')) result = '+84${result.substring(1)}';
    if (!RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(result)) {
      throw const FormatException(
        'Nhập số điện thoại hợp lệ, ví dụ 09xxxxxxxx.',
      );
    }
    return result;
  }

  Future<void> send() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final number = normalizePhone(phone.text.trim());
      await Supabase.instance.client.auth.signInWithOtp(
        phone: number,
        shouldCreateUser: register,
      );
      if (!mounted) return;
      setState(() {
        sent = true;
        sentPhone = number;
        cooldown = 60;
      });
      timer?.cancel();
      timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) {
          t.cancel();
          return;
        }
        setState(() => cooldown--);
        if (cooldown == 0) t.cancel();
      });
    } catch (e) {
      if (mounted)
        setState(
          () => error = e is AuthException
              ? e.message
              : e is FormatException
              ? e.message
              : 'Không thể gửi OTP. Kiểm tra kết nối.',
        );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> verify() async {
    if (!RegExp(r'^\d{6}$').hasMatch(otp.text.trim())) {
      setState(() => error = 'Vui lòng nhập mã OTP gồm 6 chữ số.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await Supabase.instance.client.auth.verifyOTP(
        phone: sentPhone!,
        token: otp.text.trim(),
        type: OtpType.sms,
      );
      // AuthGate switches screens only after Supabase creates a valid session.
    } catch (e) {
      if (mounted)
        setState(
          () => error = e is AuthException
              ? e.message
              : 'Không thể xác thực OTP. Kiểm tra kết nối.',
        );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    phone.dispose();
    otp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.local_parking_rounded,
                  size: 72,
                  color: AppColors.secondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Bãi xe đại học',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  sent
                      ? 'Nhập mã SMS gửi đến $sentPhone'
                      : 'Theo dõi và đặt chỗ đỗ ô tô trong khuôn viên trường.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (!sent) ...[
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Đăng nhập')),
                      ButtonSegment(value: true, label: Text('Đăng ký')),
                    ],
                    selected: {register},
                    onSelectionChanged: busy
                        ? null
                        : (v) => setState(() => register = v.first),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phone,
                    enabled: !busy,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại',
                      hintText: '09xxxxxxxx',
                    ),
                  ),
                ] else
                  TextField(
                    controller: otp,
                    enabled: !busy,
                    maxLength: 6,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'Mã OTP'),
                  ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: busy
                      ? null
                      : sent
                      ? verify
                      : send,
                  child: Text(
                    busy
                        ? 'Đang xử lý…'
                        : sent
                        ? 'Xác thực'
                        : 'Gửi mã OTP',
                  ),
                ),
                if (sent) ...[
                  TextButton(
                    onPressed: busy || cooldown > 0 ? null : send,
                    child: Text(
                      cooldown > 0 ? 'Gửi lại sau ${cooldown}s' : 'Gửi lại OTP',
                    ),
                  ),
                  TextButton(
                    onPressed: busy
                        ? null
                        : () => setState(() {
                            sent = false;
                            otp.clear();
                            error = null;
                            timer?.cancel();
                            cooldown = 0;
                          }),
                    child: const Text('Đổi số điện thoại'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
