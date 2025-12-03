import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter/material.dart';
import 'dart:async';

//Pasar datos necesarios del estado de pintura
class PaintingStateInterface {
  final bool isErasing;
  final Color currentColor;
  final double currentStrokeWidth;
  
  PaintingStateInterface({
    required this.isErasing,
    required this.currentColor,
    required this.currentStrokeWidth,
  });
}

class GestureDetectorService {
  final List<Color> colors;
  
  Color currentColor = Colors.blue;
  bool isErasing = false;
  final List<Offset> currentStrokePoints = [];
  bool isPainting = false;
  
  // Control de tiempo
  DateTime? _lastActionTime;
  GestureAction? _lastAction;
  final Duration _actionCooldown = const Duration(milliseconds: 800);

  GestureDetectorService({required this.colors});

  bool _canPerformAction(GestureAction action) {
    if (_lastActionTime == null) return true;
    
    final now = DateTime.now();
    final timeSinceLastAction = now.difference(_lastActionTime!);
    
    // Limitar otras acciones y pintar
    if (action == GestureAction.paint) return true;
    
    //Cooldown
    if (action == _lastAction && timeSinceLastAction < _actionCooldown) {
      return false;
    }
    
    return true;
  }
  
  void _recordAction(GestureAction action) {
    _lastActionTime = DateTime.now();
    _lastAction = action;
  }

  GestureResult detectGesture(
    Face face, 
    PaintingStateInterface paintingState,
    Size screenSize,
  ) {
    final smileProb = face.smilingProbability ?? 0;
    final leftEyeOpenProb = face.leftEyeOpenProbability ?? 0;
    final rightEyeOpenProb = face.rightEyeOpenProbability ?? 0;
    final headEulerAngleY = face.headEulerAngleY ?? 0;
    final headEulerAngleX = face.headEulerAngleX ?? 0;

    print('👀 Gestos - Sonrisa: ${(smileProb * 100).toInt()}%, Ojos: L${(leftEyeOpenProb * 100).toInt()}% R${(rightEyeOpenProb * 100).toInt()}%, Cabeza Y:${headEulerAngleY.toInt()}° X:${headEulerAngleX.toInt()}°');

    if (smileProb > 0.6) {
      isPainting = true;
      
      // Normalizar ángulos para coordenadas de pantalla
      // headEulerAngleY: -30 a +30 grados (izquierda a derecha)
      // headEulerAngleX: -20 a +20 grados (arriba a abajo)
      final normalizedX = ((headEulerAngleY + 30) / 60).clamp(0.0, 1.0);
      final normalizedY = ((headEulerAngleX + 20) / 40).clamp(0.0, 1.0);
      
      // Convertir a coordenadas de pantalla
      final paintPosition = Offset(
        (1 - normalizedX) * screenSize.width,
        normalizedY * screenSize.height,
      );

      // Agregar punto al trazo actual
      currentStrokePoints.add(paintPosition);
      
      print('🎨 PINTANDO en posición: (${paintPosition.dx.toInt()}, ${paintPosition.dy.toInt()})');
      
      // Si tenemos al menos 2 puntos, crear un trazo
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
    
    // Si no sonrie, limpia el trazo actual
    if (isPainting && smileProb <= 0.5) {
      isPainting = false;
      currentStrokePoints.clear();
      print('✋ Dejó de pintar');
    }
    
    // Parpadear para cambiar modo
    if (leftEyeOpenProb < 0.2 && rightEyeOpenProb < 0.2) {
      if (_canPerformAction(GestureAction.toggleEraser)) {
        _recordAction(GestureAction.toggleEraser);
        currentStrokePoints.clear();
        print('👁 PARPADEANDO - Cambiar modo');
        return GestureResult(
          action: GestureAction.toggleEraser,
          message: '👁 Cambio de modo',
        );
      }
    }
    
    //Cabeza derecha para cambiar color
    if (headEulerAngleY > 20) {
      if (_canPerformAction(GestureAction.changeColor)) {
        _recordAction(GestureAction.changeColor);
        currentStrokePoints.clear();
        
        // Encontrar siguiente color en la lista
        final currentIndex = colors.indexOf(currentColor);
        final nextIndex = (currentIndex + 1) % colors.length;
        currentColor = colors[nextIndex];
        
        print('🎨 CABEZA DERECHA - Cambiar color');
        return GestureResult(
          action: GestureAction.changeColor,
          color: currentColor,
          message: '➡ Siguiente color',
        );
      }
    }
    
    //Cabeza izquierda para deshacer
    if (headEulerAngleY < -20) {  // Aumentado de -15 a -20
      if (_canPerformAction(GestureAction.undo)) {
        _recordAction(GestureAction.undo);
        currentStrokePoints.clear();
        print('↩ CABEZA IZQUIERDA - Deshacer');
        return GestureResult(
          action: GestureAction.undo,
          message: '↩ Deshacer',
        );
      }
    }
    
    //Cabeza arriba para limpiar lienzo
    if (headEulerAngleX < -15) {  // Aumentado de -10 a -15
      if (_canPerformAction(GestureAction.clear)) {
        _recordAction(GestureAction.clear);
        currentStrokePoints.clear();
        print('🗑 CABEZA ARRIBA - Limpiar');
        return GestureResult(
          action: GestureAction.clear,
          message: '🗑 Limpiar todo',
        );
      }
    }
    
    // No hay gestos activos
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

//Acciones
enum GestureAction {
  none,          // No hacer nada
  paint,         // Pintar trazo
  toggleEraser,  // Cambiar entre pincel y goma
  changeColor,   // Cambiar color
  undo,          // Deshacer ultimo trazo
  clear,         // Limpiar lienzo
  waiting,       // Esperando gesto
}

// Resultado de la deteccion
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
