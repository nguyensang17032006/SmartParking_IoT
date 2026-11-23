import 'package:smart_parking/features/auth/domain/usecase/save_profile.dart';
import 'package:smart_parking/features/auth/domain/usecase/send_email_otp.dart';
import 'package:smart_parking/features/auth/domain/usecase/verify_email_otp.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/datasources/auth_remote_data_source.dart';
import 'data/repositories/auth_repository_impl.dart';

import 'presentation/viewmodels/auth_view_model.dart';

AuthViewModel createAuthViewModel() {
  final supabase = Supabase.instance.client;

  final dataSource = AuthRemoteDataSourceImpl(supabase);
  final repository = AuthRepositoryImpl(dataSource);

  return AuthViewModel(
    sendEmailOtpUseCase: SendEmailOtp(repository),
    verifyEmailOtpUseCase: VerifyEmailOtp(repository),
    saveProfileUseCase: SaveProfile(repository),
  );
}