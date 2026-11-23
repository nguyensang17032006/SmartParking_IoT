import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_parking/features/auth/domain/usecase/send_email_otp.dart';
import 'package:smart_parking/features/auth/domain/usecase/save_profile.dart';
import 'package:smart_parking/features/auth/domain/usecase/verify_email_otp.dart';

class AuthViewModel extends ChangeNotifier {
  final SendEmailOtp sendEmailOtpUseCase;
  final VerifyEmailOtp verifyEmailOtpUseCase;
  final SaveProfile saveProfileUseCase;

  AuthViewModel({
    required this.sendEmailOtpUseCase,
    required this.verifyEmailOtpUseCase,
    required this.saveProfileUseCase,
  });

  bool isLoading = false;
  String? errorMessage;

  Future<bool> _execute(Future<void> Function() action) async {
    if (isLoading) return false;
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on AuthException catch (e) {
      errorMessage = e.message;
      return false;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Edge Function kiểm tra auth.users bằng quyền phía server.
  Future<String?> _getEmailStatus(String email) async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'check-email-status',
        body: {'email': email.trim().toLowerCase()},
      );
      if (response.status != 200 || response.data is! Map) {
        throw Exception('Không thể kiểm tra trạng thái tài khoản');
      }
      final status = (response.data as Map)['status'];
      if (status != 'not_found' && status != 'unverified' && status != 'verified') {
        throw Exception('Phản hồi kiểm tra tài khoản không hợp lệ');
      }
      return status as String;
    } catch (e) {
      debugPrint('check-email-status failed: $e');
      errorMessage = 'Không thể kiểm tra tài khoản. Vui lòng thử lại.';
      notifyListeners();
      return null;
    }
  }

  Future<bool> canLogin(String email) async {
    errorMessage = null;
    final status = await _getEmailStatus(email);
    if (status == null) return false;
    if (status == 'not_found') {
      errorMessage = 'Tài khoản không tồn tại';
    } else if (status == 'unverified') {
      errorMessage = 'Email chưa được xác thực. Vui lòng đăng ký lại để nhận OTP.';
    }
    notifyListeners();
    return status == 'verified';
  }

  Future<bool> canRegister(String email) async {
    errorMessage = null;
    final status = await _getEmailStatus(email);
    if (status == null) return false;
    if (status == 'verified') {
      errorMessage = 'Email đã được sử dụng';
      notifyListeners();
      return false;
    }
    return true; // not_found hoặc unverified
  }

  Future<bool> sendOtp({required String email, required bool isSignup}) {
    return _execute(() => sendEmailOtpUseCase(email: email, isSignup: isSignup));
  }

  Future<bool> verifyOtp({required String email, required String token}) {
    return _execute(() => verifyEmailOtpUseCase(email: email, token: token));
  }

  Future<bool> saveProfile({
    required String fullName,
    required String phone,
    required String email,
  }) {
    return _execute(() => saveProfileUseCase(
      fullName: fullName, phone: phone, email: email,
    ));
  }
}
