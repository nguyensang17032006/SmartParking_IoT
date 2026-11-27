import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/validate_face_image.dart';
import 'face_capture_event.dart';
import 'face_capture_state.dart';

class FaceCaptureBloc extends Bloc<FaceCaptureEvent, FaceCaptureState> {
  final ValidateFaceImage validateFaceImage;

  FaceCaptureBloc({required this.validateFaceImage})
    : super(const FaceCaptureInitial()) {
    on<ValidateFaceImageEvent>(_onValidateFaceImage);
    on<ResetFaceCaptureEvent>(_onReset);
  }

  Future<void> _onValidateFaceImage(
    ValidateFaceImageEvent event,
    Emitter<FaceCaptureState> emit,
  ) async {
    emit(FaceCaptureChecking(event.imageFile));

    try {
      final result = await validateFaceImage(event.imageFile);

      if (result.isValid) {
        emit(FaceCaptureSuccess(imageFile: event.imageFile, result: result));
      } else {
        emit(FaceCaptureFailure(result.message));
      }
    } catch (e) {
      emit(FaceCaptureFailure('Không thể kiểm tra ảnh: $e'));
    }
  }

  void _onReset(ResetFaceCaptureEvent event, Emitter<FaceCaptureState> emit) {
    emit(const FaceCaptureInitial());
  }
}
