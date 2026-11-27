import 'dart:io';

import 'package:equatable/equatable.dart';

abstract class FaceCaptureEvent extends Equatable {
  const FaceCaptureEvent();

  @override
  List<Object?> get props => [];
}

class ValidateFaceImageEvent extends FaceCaptureEvent {
  final File imageFile;

  const ValidateFaceImageEvent(this.imageFile);

  @override
  List<Object?> get props => [imageFile.path];
}

class ResetFaceCaptureEvent extends FaceCaptureEvent {
  const ResetFaceCaptureEvent();
}
