import 'dart:io';

import 'package:equatable/equatable.dart';

import '../../domain/entities/face_validation_result.dart';

abstract class FaceCaptureState extends Equatable {
  const FaceCaptureState();

  @override
  List<Object?> get props => [];
}

class FaceCaptureInitial extends FaceCaptureState {
  const FaceCaptureInitial();
}

class FaceCaptureChecking extends FaceCaptureState {
  final File imageFile;

  const FaceCaptureChecking(this.imageFile);

  @override
  List<Object?> get props => [imageFile.path];
}

class FaceCaptureSuccess extends FaceCaptureState {
  final File imageFile;
  final FaceValidationResult result;

  const FaceCaptureSuccess({required this.imageFile, required this.result});

  @override
  List<Object?> get props => [imageFile.path, result.isValid, result.message];
}

class FaceCaptureFailure extends FaceCaptureState {
  final String message;

  const FaceCaptureFailure(this.message);

  @override
  List<Object?> get props => [message];
}
