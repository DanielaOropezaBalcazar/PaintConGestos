import 'dart:async';
import 'dart:io' if (dart.library.html) 'dart:html' as html;

import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class PlatformCameraService extends ChangeNotifier {
  late CameraController _cameraController;
  FaceDetector? _faceDetector;
  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _isStreamActive = false;
  Function(Face?)? _onFaceDetected;
  Function(String)? _onError;
  List<CameraDescription> _cameras = [];
  int _frameSkipCounter = 0;
  int _processedFrames = 0;
  Timer? _debugTimer;

  bool get isInitialized => _isInitialized;
  bool get isStreamActive => _isStreamActive;
  int get processedFrames => _processedFrames;
  CameraController get cameraController => _cameraController;

  PlatformCameraService() {
    _debugTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      debugPrint(
        '📊 Estado: Init=$_isInitialized, Stream=$_isStreamActive, Processing=$_isProcessing, Frames=$_processedFrames',
      );
    });
  }

  Future<void> initialize(
    List<CameraDescription> cameras, {
    required Function(Face?) onFaceDetected,
    Function(String)? onError,
  }) async {
    _onFaceDetected = onFaceDetected;
    _onError = onError;
    _cameras = cameras;

    try {
      debugPrint('🎥 PASO 1: Inicializando cámara...');
      await _initializeCameraFast();
      _isInitialized = true;
      notifyListeners();
      debugPrint('✅ Cámara inicializada');

      debugPrint('🧠 PASO 2: Inicializando detector...');
      await _initializeDetectionNow();
    } catch (e) {
      debugPrint('❌ ERROR: $e');
      _onError?.call('Error: $e');
      rethrow;
    }
  }

  Future<void> _initializeCameraFast() async {
    if (_cameras.isEmpty) {
      throw Exception('No hay cámaras');
    }

    CameraDescription selectedCamera;
    try {
      selectedCamera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );
      debugPrint('📷 Cámara frontal');
    } catch (e) {
      selectedCamera = _cameras.first;
      debugPrint('📷 Primera cámara');
    }

    _cameraController = CameraController(
      selectedCamera,
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: _getImageFormatGroup(),
    );

    await _cameraController.initialize();
    debugPrint('✅ CameraController OK');
  }

  ImageFormatGroup _getImageFormatGroup() {
    if (kIsWeb) {
      debugPrint('🌐 Web');
      return ImageFormatGroup.jpeg;
    }

    try {
      if (!kIsWeb) {
        // Usamos defaultTargetPlatform en lugar de Platform
        if (defaultTargetPlatform == TargetPlatform.android) {
          debugPrint('🤖 Android');
          return ImageFormatGroup.yuv420;
        } else if (defaultTargetPlatform == TargetPlatform.iOS) {
          debugPrint('🍎 iOS');
          return ImageFormatGroup.bgra8888;
        }
      }
    } catch (e) {
      debugPrint('⚠ Plataforma desconocida');
    }

    return ImageFormatGroup.yuv420;
  }

  Future<void> _initializeDetectionNow() async {
    try {
      debugPrint('📸 Creando detector...');
      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableContours: false,
          enableClassification: true,
          enableTracking: false,
          minFaceSize: 0.1,
          performanceMode: FaceDetectorMode.fast,
        ),
      );
      debugPrint('✅ Detector creado');

      debugPrint(
        '🔍 Estado: Web=$kIsWeb, Init=${_cameraController.value.isInitialized}, Streaming=${_cameraController.value.isStreamingImages}',
      );

      if (kIsWeb) {
        debugPrint('⚠ Web no soporta stream');
        return;
      }

      if (!_cameraController.value.isInitialized) {
        throw Exception('Cámara no inicializada');
      }

      debugPrint('🎬 Iniciando stream...');
      await startImageStreamManually();
    } catch (e) {
      debugPrint('❌ Error detector: $e');
      _onError?.call('Error detector: $e');
    }
  }

  Future<void> startImageStreamManually() async {
    debugPrint('👆 startImageStreamManually llamado');

    if (kIsWeb) {
      debugPrint('⚠ No disponible en web');
      return;
    }

    if (_isStreamActive) {
      debugPrint('⚠ Stream ya activo');
      return;
    }

    if (!_cameraController.value.isInitialized) {
      debugPrint('❌ Cámara no inicializada');
      return;
    }

    try {
      debugPrint('🎬 Llamando startImageStream()...');

      await _cameraController.startImageStream(_processCameraImage);

      _isStreamActive = true;
      notifyListeners();

      debugPrint('✅✅✅ STREAM ACTIVO ✅✅✅');
      debugPrint('Verificación: ${_cameraController.value.isStreamingImages}');
    } catch (e, stack) {
      debugPrint('❌ ERROR STREAM: $e');
      debugPrint('Stack: $stack');

      _isStreamActive = false;
      notifyListeners();
      _onError?.call('Error stream: $e');
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    _frameSkipCounter++;

    if (_frameSkipCounter % 2 != 0) return;

    if (_isProcessing || _faceDetector == null) return;

    _isProcessing = true;
    _processedFrames++;

    if (_processedFrames % 10 == 0) {
      notifyListeners(); // Actualizar UI cada 10 frames
    }

    try {
      final inputImage = _createInputImageFast(image);
      if (inputImage == null) {
        _isProcessing = false;
        return;
      }

      final faces = await _faceDetector!.processImage(inputImage);

      if (_processedFrames % 30 == 0) {
        debugPrint('📊 Frame $_processedFrames - Rostros: ${faces.length}');
      }

      if (faces.isNotEmpty) {
        final face = faces.first;
        final smile = face.smilingProbability ?? 0;

        if (_processedFrames % 30 == 0) {
          debugPrint('😊 Sonrisa: ${(smile * 100).toInt()}%');
        }

        _onFaceDetected?.call(face);
      } else {
        _onFaceDetected?.call(null);
      }
    } catch (e) {
      if (_processedFrames % 30 == 0) {
        debugPrint('⚠ Error frame: $e');
      }
    } finally {
      _isProcessing = false;
    }
  }

  InputImage? _createInputImageFast(CameraImage image) {
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
        rotation = _cameraController.description.lensDirection == CameraLensDirection.front
            ? InputImageRotation.rotation270deg
            : InputImageRotation.rotation90deg;
      } else {
        format = InputImageFormat.bgra8888;
        rotation = InputImageRotation.rotation0deg;
      }

      // Concatenar los bytes de todos los planos para formar la imagen completa
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
      return null;
    }
  }

  Widget buildCameraPreview({
    double height = 120,
    Color borderColor = const Color(0xFF90CAF9),
  }) {
    if (!_isInitialized || !_cameraController.value.isInitialized) {
      return _buildCameraLoading(height: height);
    }

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            CameraPreview(_cameraController),

            // Estado del stream
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _isStreamActive ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isStreamActive ? Icons.videocam : Icons.videocam_off,
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      _isStreamActive ? 'ON' : 'OFF',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Contador
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Frames: $_processedFrames',
                  style: const TextStyle(color: Colors.white, fontSize: 8),
                ),
              ),
            ),

            // Botón de inicio
            if (!_isStreamActive)
              Positioned.fill(
                child: Material(
                  color: Colors.black54,
                  child: InkWell(
                    onTap: () async {
                      debugPrint('👆 TAP DETECTADO');
                      await startImageStreamManually();
                    },
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.play_circle_fill,
                            color: Colors.white,
                            size: 40,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'TOCA AQUÍ\npara iniciar detección',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraLoading({double height = 120}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Cargando...',
              style: TextStyle(color: Colors.white, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Future<void> dispose() async {
    debugPrint('🔴 Dispose');

    _debugTimer?.cancel();
    _isInitialized = false;
    _isProcessing = false;
    _isStreamActive = false;

    try {
      if (_cameraController.value.isInitialized) {
        if (!kIsWeb && _cameraController.value.isStreamingImages) {
          await _cameraController.stopImageStream();
        }
        await _cameraController.dispose();
      }
    } catch (e) {
      debugPrint('⚠ Error dispose cámara: $e');
    }

    try {
      if (_faceDetector != null) {
        await _faceDetector!.close();
      }
    } catch (e) {
      debugPrint('⚠ Error dispose detector: $e');
    }

    super.dispose();
  }
}
