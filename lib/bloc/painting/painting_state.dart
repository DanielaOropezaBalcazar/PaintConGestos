import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../models/paint_stroke.dart';

enum SaveStatus { initial, loading, success, failure }

class PaintingState extends Equatable {
  final List<PaintStroke> strokes;
  final Color currentColor;
  final double currentStrokeWidth;
  final bool isErasing;
  final String gestureMessage;
  final PaintStroke? currentStroke;
  final SaveStatus saveStatus;

  const PaintingState({
    this.strokes = const [],
    this.currentColor = Colors.blue,
    this.currentStrokeWidth = 5.0,
    this.isErasing = false,
    this.gestureMessage = 'En espera...',
    this.currentStroke,
    this.saveStatus = SaveStatus.initial, 
  });

  factory PaintingState.initial() {
    return const PaintingState(
      strokes: [],
      currentColor: Colors.blue,
      currentStrokeWidth: 5.0,
      isErasing: false,
      gestureMessage: 'En espera...',
      saveStatus: SaveStatus.initial,
    );
  }

  PaintingState copyWith({
    List<PaintStroke>? strokes,
    Color? currentColor,
    double? currentStrokeWidth,
    bool? isErasing,
    String? gestureMessage,
    PaintStroke? currentStroke,
    SaveStatus? saveStatus,
  }) {
    return PaintingState(
      strokes: strokes ?? this.strokes,
      currentColor: currentColor ?? this.currentColor,
      currentStrokeWidth: currentStrokeWidth ?? this.currentStrokeWidth,
      isErasing: isErasing ?? this.isErasing,
      gestureMessage: gestureMessage ?? this.gestureMessage,
      currentStroke: currentStroke ?? this.currentStroke,
      saveStatus: saveStatus ?? this.saveStatus,
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
        saveStatus,
      ];
}