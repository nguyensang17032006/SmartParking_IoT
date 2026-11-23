import '../repositories/auth_repository.dart';

class VerifyEmailOtp {
  final AuthRepository repository;

  VerifyEmailOtp(this.repository);

  Future<void> call({
    required String email,
    required String token,
  }) {
    return repository.verifyEmailOtp(
      email: email,
      token: token,
    );
  }
}