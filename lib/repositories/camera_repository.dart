import 'dart:async';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../services/platform_camera_service.dart';

/// Repositorio que maneja la cámara y detección facial
/// Actúa como intermediario entre BLoC y servicios
class CameraRepository {
  final PlatformCameraService _cameraService;

  CameraRepository({PlatformCameraService? cameraService})
      : _cameraService = cameraService ?? PlatformCameraService();

  Stream<Face?> get faceStream => _cameraService.faceStream;

  Future<void> initialize(List<CameraDescription> cameras) async {
    await _cameraService.initialize(cameras);
  }

  Future<void> startDetection() async {
    await _cameraService.startImageStream();
  }

  Future<void> stopDetection() async {
    await _cameraService.stopImageStream();
  }

  CameraController? getCameraController() {
    return _cameraService.isInitialized ? _cameraService.cameraController : null;
  }

  bool get isInitialized => _cameraService.isInitialized;
  bool get isStreamActive => _cameraService.isStreamActive;
  int get processedFrames => _cameraService.processedFrames;

  Future<void> dispose() async {
    await _cameraService.dispose();
  }
}