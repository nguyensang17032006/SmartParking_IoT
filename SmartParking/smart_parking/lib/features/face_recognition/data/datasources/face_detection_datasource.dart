import 'dart:io';

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectionDataSource {
  late final FaceDetector _detector;

  FaceDetectionDataSource() {
    _detector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        enableLandmarks: true,
        enableContours: false,
        enableClassification: true,
        enableTracking: false,
      ),
    );
  }

  Future<List<Face>> detectFaces(File imageFile) async {
    final inputImage = InputImage.fromFilePath(imageFile.path);
    return await _detector.processImage(inputImage);
  }

  Future<void> dispose() async {
    await _detector.close();
  }
}
