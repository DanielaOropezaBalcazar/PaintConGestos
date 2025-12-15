import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class PaintStroke extends Equatable {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final bool isErasing;
  final String id;
  final DateTime timestamp;

  PaintStroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
    this.isErasing = false,
    String? id,
    DateTime? timestamp,
  })  : id = id ?? DateTime.now().toString(),
        timestamp = timestamp ?? DateTime.now();

  // Constructor const separado para casos sin timestamp
  const PaintStroke.withTimestamp({
    required this.points,
    required this.color,
    required this.strokeWidth,
    required this.isErasing,
    required this.id,
    required this.timestamp,
  });

  PaintStroke copyWith({
    List<Offset>? points,
    Color? color,
    double? strokeWidth,
    bool? isErasing,
    String? id,
    DateTime? timestamp,
  }) {
    return PaintStroke(
      points: points ?? this.points,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      isErasing: isErasing ?? this.isErasing,
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  List<Object?> get props => [id, points, color, strokeWidth, isErasing, timestamp];
}