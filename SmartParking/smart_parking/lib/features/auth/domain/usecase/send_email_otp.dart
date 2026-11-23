import '../repositories/auth_repository.dart';

class SendEmailOtp {
  final AuthRepository repository;

  SendEmailOtp(this.repository);

  Future<void> call({
    required String email,
    required bool isSignup,
  }) {
    return repository.sendEmailOtp(
      email: email,
      isSignup: isSignup,
    );
  }
}