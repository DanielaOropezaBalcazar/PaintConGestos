import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'painting_event.dart';
import 'painting_state.dart';
import '../../models/paint_stroke.dart';

class PaintingBloc extends Bloc<PaintingEvent, PaintingState> {
  PaintingBloc() : super(PaintingState.initial()) {
    // Registrar manejadores de eventos
    on<AddStroke>(_onAddStroke);
    on<AddPointsToCurrentStroke>(_onAddPointsToCurrentStroke);
    on<ChangeColor>(_onChangeColor);
    on<ChangeStrokeWidth>(_onChangeStrokeWidth);
    on<ToggleEraser>(_onToggleEraser);
    on<UndoStroke>(_onUndoStroke);
    on<ClearCanvas>(_onClearCanvas);
    on<UpdateGestureMessage>(_onUpdateGestureMessage);
  }

  // Añadir trazo completo
  void _onAddStroke(AddStroke event, Emitter<PaintingState> emit) {
    final newStrokes = List<PaintStroke>.from(state.strokes)..add(event.stroke);
    emit(state.copyWith(strokes: newStrokes));
  }

  // Añadir puntos al trazo actual (para pintura continua)
  void _onAddPointsToCurrentStroke(
    AddPointsToCurrentStroke event,
    Emitter<PaintingState> emit,
  ) {
    if (event.points.length < 2) return;

    final stroke = PaintStroke(
      points: event.points,
      color: state.isErasing ? const Color(0xFFFFFFFF) : state.currentColor,
      strokeWidth: state.currentStrokeWidth,
      isErasing: state.isErasing,
      id: DateTime.now().toString(),
      timestamp: DateTime.now(),
    );

    final newStrokes = List<PaintStroke>.from(state.strokes)..add(stroke);
    emit(state.copyWith(strokes: newStrokes));
  }

  // Cambiar color
  void _onChangeColor(ChangeColor event, Emitter<PaintingState> emit) {
    emit(state.copyWith(currentColor: event.color));
  }

  // Cambiar grosor
  void _onChangeStrokeWidth(ChangeStrokeWidth event, Emitter<PaintingState> emit) {
    emit(state.copyWith(currentStrokeWidth: event.width));
  }

  // Alternar entre pincel y goma
  void _onToggleEraser(ToggleEraser event, Emitter<PaintingState> emit) {
    emit(state.copyWith(isErasing: !state.isErasing));
  }

  // Deshacer último trazo
  void _onUndoStroke(UndoStroke event, Emitter<PaintingState> emit) {
    if (state.strokes.isEmpty) return;

    final newStrokes = List<PaintStroke>.from(state.strokes)..removeLast();
    emit(state.copyWith(strokes: newStrokes));
  }

  // Limpiar lienzo
  void _onClearCanvas(ClearCanvas event, Emitter<PaintingState> emit) {
    emit(state.copyWith(strokes: []));
  }

  // Actualizar mensaje de gesto
  void _onUpdateGestureMessage(
    UpdateGestureMessage event,
    Emitter<PaintingState> emit,
  ) {
    emit(state.copyWith(gestureMessage: event.message));
  }
}