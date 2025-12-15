import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

abstract class GestureEvent extends Equatable {
  const GestureEvent();

  @override
  List<Object?> get props => [];
}

// Procesar rostro detectado
class ProcessFaceGesture extends GestureEvent {
  final Face face;
  final Size screenSize;

  const ProcessFaceGesture({
    required this.face,
    required this.screenSize,
  });

  @override
  List<Object?> get props => [face, screenSize];
}

// No hay rostro
class NoFaceDetected extends GestureEvent {
  const NoFaceDetected();
}

// Resetear estado de gestos
class ResetGesture extends GestureEvent {
  const ResetGesture();
}