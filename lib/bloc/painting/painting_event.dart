import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../models/paint_stroke.dart';

// Eventos que puede recibir el PaintingBloc
abstract class PaintingEvent extends Equatable {
  const PaintingEvent();

  @override
  List<Object?> get props => [];
}

// Añadir un trazo completo
class AddStroke extends PaintingEvent {
  final PaintStroke stroke;

  const AddStroke(this.stroke);

  @override
  List<Object?> get props => [stroke];
}

// Añadir puntos a un trazo en progreso
class AddPointsToCurrentStroke extends PaintingEvent {
  final List<Offset> points;

  const AddPointsToCurrentStroke(this.points);

  @override
  List<Object?> get props => [points];
}

// Cambiar color
class ChangeColor extends PaintingEvent {
  final Color color;

  const ChangeColor(this.color);

  @override
  List<Object?> get props => [color];
}

// Cambiar grosor
class ChangeStrokeWidth extends PaintingEvent {
  final double width;

  const ChangeStrokeWidth(this.width);

  @override
  List<Object?> get props => [width];
}

// Alternar modo goma/pincel
class ToggleEraser extends PaintingEvent {
  const ToggleEraser();
}

// Deshacer último trazo
class UndoStroke extends PaintingEvent {
  const UndoStroke();
}

// Limpiar todo el lienzo
class ClearCanvas extends PaintingEvent {
  const ClearCanvas();
}

// Actualizar mensaje de gesto actual
class UpdateGestureMessage extends PaintingEvent {
  final String message;

  const UpdateGestureMessage(this.message);

  @override
  List<Object?> get props => [message];
}