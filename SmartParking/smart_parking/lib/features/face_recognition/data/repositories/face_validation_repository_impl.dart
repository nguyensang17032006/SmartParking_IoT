import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

import '../../domain/entities/face_validation_result.dart';
import '../../domain/repositories/face_validation_repository.dart';
import '../datasources/face_detection_datasource.dart';
import '../models/face_validation_model.dart';

class FaceValidationRepositoryImpl implements FaceValidationRepository {
  final FaceDetectionDataSource dataSource;

  static const double _minBrightness = 55;
  static const double _maxBrightness = 215;

  FaceValidationRepositoryImpl({required this.dataSource});

  FaceValidationModel _result({
    required bool isValid,
    required String message,
    required int faceCount,
  }) {
    return FaceValidationModel(
      isValid: isValid,
      message: message,
      faceCount: faceCount,
    );
  }

  double? _calculateAverageLuminance(
    File imageFile, {
    int? cropLeft,
    int? cropTop,
    int? cropWidth,
    int? cropHeight,
  }) {
    final bytes = imageFile.readAsBytesSync();
    if (bytes.isEmpty) return null;

    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;

    img.Image targetRegion = decoded;
    if (cropLeft != null &&
        cropTop != null &&
        cropWidth != null &&
        cropHeight != null) {
      final x = cropLeft.clamp(0, math.max(0, decoded.width - 1)).toInt();
      final y = cropTop.clamp(0, math.max(0, decoded.height - 1)).toInt();
      final w = cropWidth.clamp(1, decoded.width - x).toInt();
      final h = cropHeight.clamp(1, decoded.height - y).toInt();
      if (w > 0 && h > 0) {
        targetRegion = img.copyCrop(decoded, x: x, y: y, width: w, height: h);
      }
    }

    double sumLuminance = 0;
    int pixelCount = 0;

    final int area = targetRegion.width * targetRegion.height;
    final int approxStep = math.sqrt(area / 20000).floor();
    final int step = approxStep < 1 ? 1 : approxStep;

    for (int y = 0; y < targetRegion.height; y += step) {
      for (int x = 0; x < targetRegion.width; x += step) {
        final p = targetRegion.getPixel(x, y);
        final lum = 0.299 * p.r + 0.587 * p.g + 0.114 * p.b;
        sumLuminance += lum;
        pixelCount++;
      }
    }

    if (pixelCount == 0) return null;
    return sumLuminance / pixelCount;
  }

  @override
  Future<FaceValidationResult> validateImage(File imageFile) async {
    try {
      if (!imageFile.existsSync() || imageFile.lengthSync() <= 0) {
        return _result(
          isValid: false,
          message: 'Ảnh không hợp lệ.',
          faceCount: 0,
        );
      }

      final faces = await dataSource.detectFaces(imageFile);

      if (faces.isEmpty) {
        return _result(
          isValid: false,
          message: 'Không tìm thấy khuôn mặt.',
          faceCount: 0,
        );
      }

      if (faces.length > 1) {
        return _result(
          isValid: false,
          message: 'Chỉ được có một khuôn mặt trong ảnh.',
          faceCount: faces.length,
        );
      }

      final face = faces.first;
      final box = face.boundingBox;

      final yaw = face.headEulerAngleY ?? 0;
      final roll = face.headEulerAngleZ ?? 0;

      if (yaw.abs() > 20 || roll.abs() > 15) {
        return _result(
          isValid: false,
          message: 'Vui lòng nhìn thẳng camera.',
          faceCount: 1,
        );
      }

      final leftEye = face.leftEyeOpenProbability;
      final rightEye = face.rightEyeOpenProbability;

      if (leftEye != null &&
          rightEye != null &&
          (leftEye < 0.4 || rightEye < 0.4)) {
        return _result(
          isValid: false,
          message: 'Vui lòng mở mắt khi chụp ảnh.',
          faceCount: 1,
        );
      }

      final brightness = _calculateAverageLuminance(
        imageFile,
        cropLeft: box.left.round(),
        cropTop: box.top.round(),
        cropWidth: box.width.round(),
        cropHeight: box.height.round(),
      );

      if (brightness != null) {
        if (brightness < _minBrightness) {
          return _result(
            isValid: false,
            message: 'Ảnh quá tối, vui lòng tăng thêm ánh sáng.',
            faceCount: 1,
          );
        }
        if (brightness > _maxBrightness) {
          return _result(
            isValid: false,
            message: 'Ảnh quá chói sáng, vui lòng điều chỉnh lại ánh sáng.',
            faceCount: 1,
          );
        }
      }

      return _result(
        isValid: true,
        message: 'Ảnh khuôn mặt hợp lệ.',
        faceCount: 1,
      );
    } catch (e) {
      return _result(
        isValid: false,
        message: 'Không thể phân tích ảnh: $e',
        faceCount: 0,
      );
    }
  }
}
