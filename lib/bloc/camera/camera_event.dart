import 'package:equatable/equatable.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

abstract class CameraEvent extends Equatable {
  const CameraEvent();

  @override
  List<Object?> get props => [];
}

// Inicializar cámara
class InitializeCamera extends CameraEvent {
  final List<CameraDescription> cameras;

  const InitializeCamera(this.cameras);

  @override
  List<Object?> get props => [cameras];
}

// Iniciar detección (stream de imágenes)
class StartDetection extends CameraEvent {
  const StartDetection();
}

// Detener detección
class StopDetection extends CameraEvent {
  const StopDetection();
}

// Rostro detectado (evento interno)
class FaceDetected extends CameraEvent {
  final Face? face;

  const FaceDetected(this.face);

  @override
  List<Object?> get props => [face];
}

// Error en cámara
class CameraErrorOccurred extends CameraEvent {
  final String message;

  const CameraErrorOccurred(this.message);

  @override
  List<Object?> get props => [message];
}