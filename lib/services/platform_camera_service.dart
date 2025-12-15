import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'face_detector_service.dart';

/// Servicio de cámara multiplataforma con detección facial
class PlatformCameraService {
  CameraController? _cameraController;
  final FaceDetectorService _faceDetectorService = FaceDetectorService();
  
  bool _isInitialized = false;
  bool _isStreamActive = false;
  int _processedFrames = 0;
  int _frameSkipCounter = 0;

  // Stream para emitir rostros detectados
  final StreamController<Face?> _faceStreamController = 
      StreamController<Face?>.broadcast();

  bool get isInitialized => _isInitialized;
  bool get isStreamActive => _isStreamActive;
  int get processedFrames => _processedFrames;
  CameraController? get cameraController => _cameraController;
  Stream<Face?> get faceStream => _faceStreamController.stream;

  /// Inicializa la cámara
  Future<void> initialize(List<CameraDescription> cameras) async {
    if (cameras.isEmpty) {
      throw Exception('No hay cámaras disponibles');
    }

    try {
      debugPrint('🎥 Inicializando cámara...');

      // Seleccionar cámara frontal
      CameraDescription selectedCamera;
      try {
        selectedCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
        );
      } catch (e) {
        selectedCamera = cameras.first;
      }

      _cameraController = CameraController(
        selectedCamera,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: _getImageFormatGroup(),
      );

      await _cameraController!.initialize();
      _isInitialized = true;
      
      debugPrint('✅ Cámara inicializada');
    } catch (e) {
      debugPrint('❌ Error inicializando cámara: $e');
      rethrow;
    }
  }

  ImageFormatGroup _getImageFormatGroup() {
    if (kIsWeb) {
      return ImageFormatGroup.jpeg;
    }

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        return ImageFormatGroup.yuv420;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        return ImageFormatGroup.bgra8888;
      }
    } catch (e) {
      debugPrint('⚠ Plataforma desconocida');
    }

    return ImageFormatGroup.yuv420;
  }

  /// Inicia el stream de detección facial
  Future<void> startImageStream() async {
    if (kIsWeb) {
      debugPrint('⚠ Web no soporta image stream');
      return;
    }

    if (_isStreamActive) {
      debugPrint('⚠ Stream ya activo');
      return;
    }

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      throw Exception('Cámara no inicializada');
    }

    try {
      debugPrint('🎬 Iniciando stream de detección...');
      
      await _cameraController!.startImageStream(_processCameraImage);
      _isStreamActive = true;
      
      debugPrint('✅ Stream activo');
    } catch (e) {
      debugPrint('❌ Error iniciando stream: $e');
      _isStreamActive = false;
      rethrow;
    }
  }

  /// Procesa cada frame de la cámara
  Future<void> _processCameraImage(CameraImage image) async {
    // Saltar frames para mejorar rendimiento
    _frameSkipCounter++;
    if (_frameSkipCounter % 2 != 0) return;

    _processedFrames++;

    try {
      final faces = await _faceDetectorService.detectFaces(image);
      
      if (faces.isNotEmpty) {
        _faceStreamController.add(faces.first);
      } else {
        _faceStreamController.add(null);
      }
    } catch (e) {
      if (_processedFrames % 30 == 0) {
        debugPrint('⚠ Error procesando frame: $e');
      }
    }
  }

  /// Detiene el stream
  Future<void> stopImageStream() async {
    if (!_isStreamActive) return;

    try {
      if (_cameraController != null && 
          _cameraController!.value.isStreamingImages) {
        await _cameraController!.stopImageStream();
      }
      _isStreamActive = false;
      debugPrint('🛑 Stream detenido');
    } catch (e) {
      debugPrint('⚠ Error deteniendo stream: $e');
    }
  }

  /// Libera recursos
  Future<void> dispose() async {
    debugPrint('🔴 Dispose PlatformCameraService');
    
    _isInitialized = false;
    _isStreamActive = false;

    try {
      if (_cameraController != null) {
        if (_cameraController!.value.isStreamingImages) {
          await _cameraController!.stopImageStream();
        }
        await _cameraController!.dispose();
      }
    } catch (e) {
      debugPrint('⚠ Error dispose cámara: $e');
    }

    try {
      await _faceDetectorService.dispose();
    } catch (e) {
      debugPrint('⚠ Error dispose detector: $e');
    }

    await _faceStreamController.close();
  }
}