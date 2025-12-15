import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum GestureAction {
  none,
  paint,
  toggleEraser,
  changeColor,
  undo,
  clear,
  waiting,
}

class GestureState extends Equatable {
  final GestureAction action;
  final String message;
  final Color? detectedColor;
  final List<Offset>? paintPoints;
  final bool isPainting;

  const GestureState({
    this.action = GestureAction.waiting,
    this.message = 'Esperando rostro...',
    this.detectedColor,
    this.paintPoints,
    this.isPainting = false,
  });

  factory GestureState.initial() {
    return const GestureState(
      action: GestureAction.waiting,
      message: 'Esperando rostro...',
      isPainting: false,
    );
  }

  GestureState copyWith({
    GestureAction? action,
    String? message,
    Color? detectedColor,
    List<Offset>? paintPoints,
    bool? isPainting,
  }) {
    return GestureState(
      action: action ?? this.action,
      message: message ?? this.message,
      detectedColor: detectedColor ?? this.detectedColor,
      paintPoints: paintPoints ?? this.paintPoints,
      isPainting: isPainting ?? this.isPainting,
    );
  }

  @override
  List<Object?> get props => [
        action,
        message,
        detectedColor,
        paintPoints,
        isPainting,
      ];
}