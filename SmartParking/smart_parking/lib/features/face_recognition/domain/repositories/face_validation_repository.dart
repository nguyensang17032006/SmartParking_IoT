import 'dart:io';

import '../entities/face_validation_result.dart';

abstract class FaceValidationRepository {
  Future<FaceValidationResult> validateImage(File imageFile);
}
