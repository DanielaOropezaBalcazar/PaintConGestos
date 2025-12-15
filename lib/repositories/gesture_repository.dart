import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../bloc/gesture/gesture_state.dart';

/// Resultado de detección de gestos
class GestureResult {
  final GestureAction action;
  final String message;
  final Color? color;
  final List<Offset>? points;

  GestureResult({
    required this.action,
    required this.message,
    this.color,
    this.points,
  });
}

/// Repositorio que detecta gestos faciales
class GestureRepository {
  final List<Color> colors;
  
  Color currentColor = Colors.blue;
  bool isErasing = false;
  final List<Offset> currentStrokePoints = [];
  bool isPainting = false;
  
  DateTime? _lastActionTime;
  GestureAction? _lastAction;
  final Duration _actionCooldown = const Duration(milliseconds: 800);

  GestureRepository({required this.colors});

  bool _canPerformAction(GestureAction action) {
    if (_lastActionTime == null) return true;
    
    final now = DateTime.now();
    final timeSinceLastAction = now.difference(_lastActionTime!);
    
    if (action == GestureAction.paint) return true;
    
    if (action == _lastAction && timeSinceLastAction < _actionCooldown) {
      return false;
    }
    
    return true;
  }
  
  void _recordAction(GestureAction action) {
    _lastActionTime = DateTime.now();
    _lastAction = action;
  }

  GestureResult detectGesture(Face face, Size screenSize) {
    final smileProb = face.smilingProbability ?? 0;
    final leftEyeOpenProb = face.leftEyeOpenProbability ?? 0;
    final rightEyeOpenProb = face.rightEyeOpenProbability ?? 0;
    final headEulerAngleY = face.headEulerAngleY ?? 0;
    final headEulerAngleX = face.headEulerAngleX ?? 0;

    // Sonreír para pintar
    if (smileProb > 0.6) {
      isPainting = true;
      
      final normalizedX = ((headEulerAngleY + 30) / 60).clamp(0.0, 1.0);
      final normalizedY = ((headEulerAngleX + 20) / 40).clamp(0.0, 1.0);
      
      final paintPosition = Offset(
        (1 - normalizedX) * screenSize.width,
        normalizedY * screenSize.height,
      );

      currentStrokePoints.add(paintPosition);
      
      if (currentStrokePoints.length >= 2) {
        final strokePoints = List<Offset>.from(currentStrokePoints.getRange(
          currentStrokePoints.length - 2, 
          currentStrokePoints.length
        ));
        
        return GestureResult(
          action: GestureAction.paint,
          points: strokePoints,
          message: '🎨 Pintando (${(smileProb * 100).toInt()}%)',
        );
      }
      
      return GestureResult(
        action: GestureAction.none,
        message: '😊 Sonriendo...',
      );
    }
    
    if (isPainting && smileProb <= 0.5) {
      isPainting = false;
      currentStrokePoints.clear();
    }
    
    // Parpadear para cambiar modo
    if (leftEyeOpenProb < 0.2 && rightEyeOpenProb < 0.2) {
      if (_canPerformAction(GestureAction.toggleEraser)) {
        _recordAction(GestureAction.toggleEraser);
        currentStrokePoints.clear();
        return GestureResult(
          action: GestureAction.toggleEraser,
          message: '👁 Cambio de modo',
        );
      }
    }
    
    // Cabeza derecha para cambiar color
    if (headEulerAngleY > 20) {
      if (_canPerformAction(GestureAction.changeColor)) {
        _recordAction(GestureAction.changeColor);
        currentStrokePoints.clear();
        
        final currentIndex = colors.indexOf(currentColor);
        final nextIndex = (currentIndex + 1) % colors.length;
        currentColor = colors[nextIndex];
        
        return GestureResult(
          action: GestureAction.changeColor,
          color: currentColor,
          message: '➡ Siguiente color',
        );
      }
    }
    
    // Cabeza izquierda para deshacer
    if (headEulerAngleY < -20) {
      if (_canPerformAction(GestureAction.undo)) {
        _recordAction(GestureAction.undo);
        currentStrokePoints.clear();
        return GestureResult(
          action: GestureAction.undo,
          message: '↩ Deshacer',
        );
      }
    }
    
    // Cabeza arriba para limpiar
    if (headEulerAngleX < -15) {
      if (_canPerformAction(GestureAction.clear)) {
        _recordAction(GestureAction.clear);
        currentStrokePoints.clear();
        return GestureResult(
          action: GestureAction.clear,
          message: '🗑 Limpiar todo',
        );
      }
    }
    
    return GestureResult(
      action: GestureAction.waiting,
      message: '👀 Esperando (sonríe para pintar)',
    );
  }

  void resetStroke() {
    currentStrokePoints.clear();
    isPainting = false;
  }

  void setColor(Color color) {
    currentColor = color;
  }
  
  void setErasing(bool erasing) {
    isErasing = erasing;
  }
}