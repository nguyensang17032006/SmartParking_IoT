import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_parking/core/theme/app_colors.dart';

import '../../data/datasources/face_detection_datasource.dart';
import '../bloc/face_capture_bloc.dart';
import '../bloc/face_capture_event.dart';
import '../bloc/face_capture_state.dart';

class FaceCameraCapturePage extends StatefulWidget {
  const FaceCameraCapturePage({super.key});

  @override
  State<FaceCameraCapturePage> createState() => _FaceCameraCapturePageState();
}

class _FaceCameraCapturePageState extends State<FaceCameraCapturePage> {
  CameraController? _cameraController;

  bool _isCameraReady = false;
  String? _cameraError;

  late final FaceDetectionDataSource _faceDataSource;

  @override
  void initState() {
    super.initState();

    _faceDataSource = FaceDetectionDataSource();

    _setupCamera();
  }

  // Khởi tạo camera
  Future<void> _setupCamera() async {
    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        if (!mounted) return;

        setState(() {
          _cameraError = 'Không tìm thấy camera.';
        });
        return;
      }

      // Ưu tiên camera trước để chụp khuôn mặt
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _isCameraReady = true;
        _cameraError = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cameraError = 'Lỗi mở camera: $e';
      });
    }
  }

  // Chụp ảnh và gửi sự kiện đến BLoC
  Future<void> _takePhoto() async {
    final controller = _cameraController;

    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture) {
      return;
    }

    try {
      final shot = await controller.takePicture();

      if (!mounted) return;

      context.read<FaceCaptureBloc>().add(
        ValidateFaceImageEvent(File(shot.path)),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Chụp ảnh không thành công: $e')));
    }
  }

  // Chụp lại
  void _resetCapture() {
    context.read<FaceCaptureBloc>().add(const ResetFaceCaptureEvent());
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDataSource.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        title: const Text(
          'Chụp ảnh khuôn mặt',
          style: TextStyle(
            color: AppColors.surface,
            fontWeight: FontWeight.bold,
            fontSize: 19,
          ),
        ),
        foregroundColor: AppColors.surface,
        backgroundColor: AppColors.primary,
      ),

      body: SafeArea(
        child: Column(
          children: [
            // Khu vực camera
            Expanded(
              child: BlocConsumer<FaceCaptureBloc, FaceCaptureState>(
                listener: (context, state) {
                  if (state is FaceCaptureFailure) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }

                  if (state is FaceCaptureSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ảnh khuôn mặt hợp lệ!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },

                builder: (context, state) {
                  final isChecking = state is FaceCaptureChecking;

                  final capturedFile = switch (state) {
                    FaceCaptureChecking(:final imageFile) => imageFile,
                    FaceCaptureSuccess(:final imageFile) => imageFile,
                    _ => null,
                  };

                  final errorMessage = state is FaceCaptureFailure
                      ? state.message
                      : _cameraError;

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      // Ảnh đã chụp
                      if (capturedFile != null)
                        Image.file(capturedFile, fit: BoxFit.cover)
                      // Lỗi camera hoặc kiểm tra ảnh
                      else if (errorMessage != null)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              errorMessage,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        )
                      // Camera preview
                      else if (_isCameraReady && _cameraController != null)
                        CameraPreview(_cameraController!)
                      // Loading camera
                      else
                        const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),

                      // Loading kiểm tra ảnh
                      if (isChecking)
                        Container(
                          color: Colors.black54,
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(color: Colors.white),
                                SizedBox(height: 12),
                                Text(
                                  'Đang kiểm tra ảnh...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),

            // Khu vực nút chức năng
            BlocBuilder<FaceCaptureBloc, FaceCaptureState>(
              builder: (context, state) {
                final isChecking = state is FaceCaptureChecking;
                final showRetake =
                    state is FaceCaptureSuccess || state is FaceCaptureFailure;

                return Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,

                    child: showRetake
                        ? OutlinedButton.icon(
                            onPressed: _resetCapture,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Chụp lại'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: BorderSide(color: AppColors.primary),
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: (_isCameraReady && !isChecking)
                                ? _takePhoto
                                : null,
                            icon: const Icon(Icons.camera),
                            label: Text(
                              isChecking ? 'Đang xử lý...' : 'Chụp ảnh',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.surface,
                            ),
                          ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
