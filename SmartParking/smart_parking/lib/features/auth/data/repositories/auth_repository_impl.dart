import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource dataSource;

  AuthRepositoryImpl(this.dataSource);

  @override
  Future<void> sendEmailOtp({
    required String email,
    required bool isSignup,
  }) {
    return dataSource.sendEmailOtp(
      email: email,
      isSignup: isSignup,
    );
  }

  @override
  Future<void> verifyEmailOtp({
    required String email,
    required String token,
  }) {
    return dataSource.verifyEmailOtp(
      email: email,
      token: token,
    );
  }

  @override
  Future<void> saveProfile({
    required String fullName,
    required String phone,
    required String email,
  }) {
    return dataSource.saveProfile(
      fullName: fullName,
      phone: phone,
      email: email,
    );
  }
}