class FaceValidationResult {
  final bool isValid;
  final String message;
  final int faceCount;

  const FaceValidationResult({
    required this.isValid,
    required this.message,
    required this.faceCount,
  });
}
