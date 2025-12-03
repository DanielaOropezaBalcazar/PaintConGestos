import 'dart:async';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class CameraService {
  late CameraController _cameraController;
  late FaceDetector _faceDetector;
  bool _isInitialized = false;
  bool _isProcessing = false;
  Function(Face?)? _onFaceDetected;
  Function(String)? _onError;

  bool get isInitialized => _isInitialized;
  CameraController get cameraController => _cameraController;

  CameraService() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true,
        enableClassification: true,
        enableTracking: true,
        minFaceSize: 0.15,
      ),
    );
  }

  Future<void> initialize(
    List<CameraDescription> cameras, {
    required Function(Face?) onFaceDetected,
    Function(String)? onError,
  }) async {
    _onFaceDetected = onFaceDetected;
    _onError = onError;

    try {
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.low,
        enableAudio: false,
      );

      await _cameraController.initialize();
      await _cameraController.startImageStream(_processCameraImage);

      _isInitialized = true;
    } catch (e) {
      _onError?.call('Error al inicializar la cámara: $e');
      rethrow;
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessing) return;
    
    _isProcessing = true;
    
    try {
      final inputImage = _createInputImage(image);
      if (inputImage == null) {
        _isProcessing = false;
        return;
      }
      
      final faces = await _faceDetector.processImage(inputImage);
      _onFaceDetected?.call(faces.isNotEmpty ? faces.first : null);
    } catch (e) {
      // Error 
    } finally {
      _isProcessing = false;
    }
  }

  InputImage? _createInputImage(CameraImage image) {
    try {
      if (image.planes.isEmpty) return null;
      
      final plane = image.planes[0];
      final width = image.width;
      final height = image.height;
      
      final expectedSize = (width * height * 3) ~/ 2;
      final actualSize = plane.bytes.length;
      
      if (plane.bytesPerRow == width && actualSize >= expectedSize) {
        return InputImage.fromBytes(
          bytes: plane.bytes,
          metadata: InputImageMetadata(
            size: Size(width.toDouble(), height.toDouble()),
            rotation: InputImageRotation.rotation0deg,
            format: InputImageFormat.nv21,
            bytesPerRow: width,
          ),
        );
      }
      
      return _createCompatibleInputImage(image);
      
    } catch (e) {
      return null;
    }
  }

  InputImage? _createCompatibleInputImage(CameraImage image) {
    try {
      final width = image.width;
      final height = image.height;
      
      if (image.planes.length >= 3) {
        return _createYUV420InputImage(image, width, height);
      }
      
      return _createGrayscaleInputImage(image, width, height);
      
    } catch (e) {
      return null;
    }
  }

  InputImage? _createYUV420InputImage(CameraImage image, int width, int height) {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();
      
      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(width.toDouble(), height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.yuv420,
          bytesPerRow: width,
        ),
      );
    } catch (e) {
      return null;
    }
  }

  InputImage? _createGrayscaleInputImage(CameraImage image, int width, int height) {
    try {
      final plane = image.planes[0];
      final bytes = plane.bytes;
      
      final bufferSize = width * height;
      final buffer = Uint8List(bufferSize);
      final bytesPerRow = plane.bytesPerRow;
      
      for (int y = 0; y < height; y++) {
        final sourceStart = y * bytesPerRow;
        final sourceEnd = min(sourceStart + width, bytes.length);
        final destStart = y * width;
        final copyLength = sourceEnd - sourceStart;
        
        if (copyLength > 0) {
          buffer.setRange(destStart, destStart + copyLength, bytes, sourceStart);
        }
      }
      
      return InputImage.fromBytes(
        bytes: buffer,
        metadata: InputImageMetadata(
          size: Size(width.toDouble(), height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.yuv420,
          bytesPerRow: width,
        ),
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> dispose() async {
    _isInitialized = false;
    _isProcessing = false;
    await _cameraController.dispose();
    await _faceDetector.close();
  }

  //Vista previa de la camara
  Widget buildCameraPreview({
    double height = 120,
    Color borderColor = const Color(0xFF90CAF9),
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CameraPreview(_cameraController),
      ),
    );
  }

  //Muestra cuando se inicializa la camara
  static Widget buildCameraLoading() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 10),
            Text(
              'Inicializando cámara...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}