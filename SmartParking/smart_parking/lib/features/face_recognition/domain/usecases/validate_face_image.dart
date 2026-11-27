import 'dart:io';

import '../entities/face_validation_result.dart';
import '../repositories/face_validation_repository.dart';

class ValidateFaceImage {
  final FaceValidationRepository repository;

  ValidateFaceImage(this.repository);

  Future<FaceValidationResult> call(File imageFile) {
    return repository.validateImage(imageFile);
  }
}
