import 'package:equatable/equatable.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

enum CameraStatus {
  initial,
  initializing,
  ready,
  detecting,
  error,
}

class CameraState extends Equatable {
  final CameraStatus status;
  final CameraController? controller;
  final Face? currentFace;
  final String? errorMessage;
  final int processedFrames;
  final bool isStreamActive;

  const CameraState({
    this.status = CameraStatus.initial,
    this.controller,
    this.currentFace,
    this.errorMessage,
    this.processedFrames = 0,
    this.isStreamActive = false,
  });

  factory CameraState.initial() {
    return const CameraState(status: CameraStatus.initial);
  }

  CameraState copyWith({
    CameraStatus? status,
    CameraController? controller,
    Face? currentFace,
    String? errorMessage,
    int? processedFrames,
    bool? isStreamActive,
  }) {
    return CameraState(
      status: status ?? this.status,
      controller: controller ?? this.controller,
      currentFace: currentFace ?? this.currentFace,
      errorMessage: errorMessage ?? this.errorMessage,
      processedFrames: processedFrames ?? this.processedFrames,
      isStreamActive: isStreamActive ?? this.isStreamActive,
    );
  }

  @override
  List<Object?> get props => [
        status,
        controller,
        currentFace,
        errorMessage,
        processedFrames,
        isStreamActive,
      ];
}