import 'package:flutter_bloc/flutter_bloc.dart';
import 'gesture_event.dart';
import 'gesture_state.dart';
import '../../repositories/gesture_repository.dart';

class GestureBloc extends Bloc<GestureEvent, GestureState> {
  final GestureRepository _gestureRepository;

  GestureBloc({required GestureRepository gestureRepository})
      : _gestureRepository = gestureRepository,
        super(GestureState.initial()) {
    on<ProcessFaceGesture>(_onProcessFaceGesture);
    on<NoFaceDetected>(_onNoFaceDetected);
    on<ResetGesture>(_onResetGesture);
  }

  void _onProcessFaceGesture(
    ProcessFaceGesture event,
    Emitter<GestureState> emit,
  ) {
    // Delegar la detección al repositorio
    final result = _gestureRepository.detectGesture(
      event.face,
      event.screenSize,
    );

    emit(GestureState(
      action: result.action,
      message: result.message,
      detectedColor: result.color,
      paintPoints: result.points,
      isPainting: result.action == GestureAction.paint,
    ));
  }

  void _onNoFaceDetected(NoFaceDetected event, Emitter<GestureState> emit) {
    _gestureRepository.resetStroke();
    emit(GestureState.initial());
  }

  void _onResetGesture(ResetGesture event, Emitter<GestureState> emit) {
    _gestureRepository.resetStroke();
    emit(GestureState.initial());
  }
}