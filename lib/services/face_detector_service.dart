import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Servicio para detección de rostros usando ML Kit
class FaceDetectorService {
  FaceDetector? _faceDetector;
  bool _isProcessing = false;

  FaceDetectorService() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: false,
        enableClassification: true,
        enableTracking: false,
        minFaceSize: 0.1,
        performanceMode: FaceDetectorMode.fast,
      ),
    );
  }

  /// Procesa una imagen de la cámara y detecta rostros
  Future<List<Face>> detectFaces(CameraImage image) async {
    if (_isProcessing || _faceDetector == null) {
      return [];
    }

    _isProcessing = true;

    try {
      final inputImage = _createInputImage(image);
      if (inputImage == null) {
        return [];
      }

      final faces = await _faceDetector!.processImage(inputImage);
      return faces;
    } catch (e) {
      debugPrint('Error detectando rostros: $e');
      return [];
    } finally {
      _isProcessing = false;
    }
  }

  /// Crea un InputImage desde CameraImage
  InputImage? _createInputImage(CameraImage image) {
    if (kIsWeb) return null;

    try {
      if (image.planes.isEmpty) return null;

      InputImageFormat format;
      InputImageRotation rotation;

      bool isAndroid = false;
      try {
        if (!kIsWeb) {
          isAndroid = defaultTargetPlatform == TargetPlatform.android;
        }
      } catch (e) {
        isAndroid = true;
      }

      if (isAndroid) {
        format = InputImageFormat.nv21;
        rotation = InputImageRotation.rotation270deg;
      } else {
        format = InputImageFormat.bgra8888;
        rotation = InputImageRotation.rotation0deg;
      }

      final WriteBuffer allBytes = WriteBuffer();
      for (final plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );
    } catch (e) {
      debugPrint('Error creando InputImage: $e');
      return null;
    }
  }

  Future<void> dispose() async {
    await _faceDetector?.close();
    _faceDetector = null;
  }
}