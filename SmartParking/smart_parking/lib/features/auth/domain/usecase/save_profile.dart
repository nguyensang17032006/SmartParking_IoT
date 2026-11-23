import '../repositories/auth_repository.dart';

class SaveProfile {
  final AuthRepository repository;

  SaveProfile(this.repository);

  Future<void> call({
    required String fullName,
    required String phone,
    required String email,
  }) {
    return repository.saveProfile(
      fullName: fullName,
      phone: phone,
      email: email,
    );
  }
}