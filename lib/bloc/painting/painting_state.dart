import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../models/paint_stroke.dart';

class PaintingState extends Equatable {
  final List<PaintStroke> strokes;
  final Color currentColor;
  final double currentStrokeWidth;
  final bool isErasing;
  final String gestureMessage;
  final PaintStroke? currentStroke;

  const PaintingState({
    this.strokes = const [],
    this.currentColor = Colors.blue,
    this.currentStrokeWidth = 5.0,
    this.isErasing = false,
    this.gestureMessage = 'En espera...',
    this.currentStroke,
  });

  factory PaintingState.initial() {
    return const PaintingState(
      strokes: [],
      currentColor: Colors.blue,
      currentStrokeWidth: 5.0,
      isErasing: false,
      gestureMessage: 'En espera...',
    );
  }

  PaintingState copyWith({
    List<PaintStroke>? strokes,
    Color? currentColor,
    double? currentStrokeWidth,
    bool? isErasing,
    String? gestureMessage,
    PaintStroke? currentStroke,
  }) {
    return PaintingState(
      strokes: strokes ?? this.strokes,
      currentColor: currentColor ?? this.currentColor,
      currentStrokeWidth: currentStrokeWidth ?? this.currentStrokeWidth,
      isErasing: isErasing ?? this.isErasing,
      gestureMessage: gestureMessage ?? this.gestureMessage,
      currentStroke: currentStroke ?? this.currentStroke,
    );
  }

  @override
  List<Object?> get props => [
        strokes,
        currentColor,
        currentStrokeWidth,
        isErasing,
        gestureMessage,
        currentStroke,
      ];
}