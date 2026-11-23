import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRemoteDataSource {
  Future<void> sendEmailOtp({
    required String email,
    required bool isSignup,
  });

  Future<void> verifyEmailOtp({
    required String email,
    required String token,
  });

  Future<void> saveProfile({
    required String fullName,
    required String phone,
    required String email,
  });
}

class AuthRemoteDataSourceImpl
    implements AuthRemoteDataSource {
  final SupabaseClient supabase;

  AuthRemoteDataSourceImpl(this.supabase);

  @override
  Future<void> sendEmailOtp({
    required String email,
    required bool isSignup,
  }) async {
    debugPrint('AUTH DEBUG: isSignup = $isSignup');
    await supabase.auth.signInWithOtp(
      email: email.trim(),
      shouldCreateUser: isSignup,
    );
  }

  @override
  Future<void> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    final response = await supabase.auth.verifyOTP(
      email: email.trim(),
      token: token.trim(),
      type: OtpType.email,
    );

    if (response.session == null) {
      throw Exception('Xác thực OTP thất bại');
    }
  }

  @override
  Future<void> saveProfile({
    required String fullName,
    required String phone,
    required String email,
  }) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Người dùng chưa đăng nhập');
    }

    await supabase.from('profiles').upsert({
      'id': user.id,
      'full_name': fullName.trim(),
      'phone': phone.trim(),
      'email': email.trim(),
    }, onConflict: 'id');
  }
}