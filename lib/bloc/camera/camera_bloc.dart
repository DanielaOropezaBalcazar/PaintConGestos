import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'camera_event.dart';
import 'camera_state.dart';
import '../../repositories/camera_repository.dart';

class CameraBloc extends Bloc<CameraEvent, CameraState> {
  final CameraRepository _cameraRepository;
  StreamSubscription? _faceDetectionSubscription;

  CameraBloc({required CameraRepository cameraRepository})
      : _cameraRepository = cameraRepository,
        super(CameraState.initial()) {
    on<InitializeCamera>(_onInitializeCamera);
    on<StartDetection>(_onStartDetection);
    on<StopDetection>(_onStopDetection);
    on<FaceDetected>(_onFaceDetected);
    on<CameraErrorOccurred>(_onCameraError);
  }

  Future<void> _onInitializeCamera(
    InitializeCamera event,
    Emitter<CameraState> emit,
  ) async {
    emit(state.copyWith(status: CameraStatus.initializing));

    try {
      await _cameraRepository.initialize(event.cameras);
      final controller = _cameraRepository.getCameraController();

      emit(state.copyWith(
        status: CameraStatus.ready,
        controller: controller,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CameraStatus.error,
        errorMessage: 'Error al inicializar: $e',
      ));
    }
  }

  Future<void> _onStartDetection(
    StartDetection event,
    Emitter<CameraState> emit,
  ) async {
    if (state.status != CameraStatus.ready) return;

    try {
      // Suscribirse al stream de rostros detectados
      _faceDetectionSubscription = _cameraRepository.faceStream.listen(
        (face) => add(FaceDetected(face)),
        onError: (error) => add(CameraErrorOccurred(error.toString())),
      );

      await _cameraRepository.startDetection();

      emit(state.copyWith(
        status: CameraStatus.detecting,
        isStreamActive: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CameraStatus.error,
        errorMessage: 'Error al iniciar detección: $e',
      ));
    }
  }

  Future<void> _onStopDetection(
    StopDetection event,
    Emitter<CameraState> emit,
  ) async {
    await _faceDetectionSubscription?.cancel();
    await _cameraRepository.stopDetection();

    emit(state.copyWith(
      status: CameraStatus.ready,
      isStreamActive: false,
      currentFace: null,
    ));
  }

  void _onFaceDetected(FaceDetected event, Emitter<CameraState> emit) {
    emit(state.copyWith(
      currentFace: event.face,
      processedFrames: state.processedFrames + 1,
    ));
  }

  void _onCameraError(CameraErrorOccurred event, Emitter<CameraState> emit) {
    emit(state.copyWith(
      status: CameraStatus.error,
      errorMessage: event.message,
    ));
  }

  @override
  Future<void> close() async {
    await _faceDetectionSubscription?.cancel();
    await _cameraRepository.dispose();
    return super.close();
  }
}