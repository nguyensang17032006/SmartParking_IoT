abstract class AuthRepository {
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