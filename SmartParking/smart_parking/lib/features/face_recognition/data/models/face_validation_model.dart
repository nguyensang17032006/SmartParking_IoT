import '../../domain/entities/face_validation_result.dart';

class FaceValidationModel extends FaceValidationResult {
  const FaceValidationModel({
    required super.isValid,
    required super.message,
    required super.faceCount,
  });

  factory FaceValidationModel.fromEntity(FaceValidationResult entity) {
    return FaceValidationModel(
      isValid: entity.isValid,
      message: entity.message,
      faceCount: entity.faceCount,
    );
  }
}
