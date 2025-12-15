import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import '../bloc/camera/camera_bloc.dart';
import '../bloc/camera/camera_event.dart';
import '../bloc/camera/camera_state.dart';
import '../bloc/gesture/gesture_bloc.dart';
import '../bloc/gesture/gesture_event.dart';
import '../bloc/gesture/gesture_state.dart' as gesture_state;
import '../bloc/painting/painting_bloc.dart';
import '../bloc/painting/painting_event.dart';
import '../bloc/painting/painting_state.dart';
import '../widgets/painting_canvas.dart';
import '../widgets/camera_preview_widget.dart';
import '../widgets/face_info_widget.dart';
import '../widgets/color_palette_widget.dart';

class PaintingScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  
  const PaintingScreen({super.key, required this.cameras});

  @override
  State<PaintingScreen> createState() => _PaintingScreenState();
}

class _PaintingScreenState extends State<PaintingScreen> {
  @override
  void initState() {
    super.initState();
    // Inicializar cámara al entrar
    context.read<CameraBloc>().add(InitializeCamera(widget.cameras));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildCanvas(),
            _buildControlPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: const Color.fromARGB(199, 46, 43, 121),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '🎨 Pintura con Gestos',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          BlocBuilder<PaintingBloc, PaintingState>(
            builder: (context, state) {
              return Row(
                children: [
                  IconButton(
                    icon: Icon(
                      state.isErasing ? Icons.brush : Icons.auto_delete,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () {
                      context.read<PaintingBloc>().add(const ToggleEraser());
                    },
                    tooltip: state.isErasing ? 'Pincel' : 'Goma',
                  ),
                  IconButton(
                    icon: const Icon(Icons.undo, color: Colors.white, size: 20),
                    onPressed: () {
                      context.read<PaintingBloc>().add(const UndoStroke());
                    },
                    tooltip: 'Deshacer',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.white, size: 20),
                    onPressed: () {
                      context.read<PaintingBloc>().add(const ClearCanvas());
                    },
                    tooltip: 'Limpiar',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCanvas() {
    return Expanded(
      child: Container(
        color: Colors.white,
        child: BlocBuilder<PaintingBloc, PaintingState>(
          builder: (context, state) {
            return PaintingCanvas(strokes: state.strokes);
          },
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      height: 280,
      color: Colors.grey.shade100,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _buildModeIndicator(),
              const SizedBox(height: 10),
              _buildStrokeWidthSlider(),
              const SizedBox(height: 8),
              const ColorPaletteWidget(),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              const CameraPreviewWidget(),
              const SizedBox(height: 10),
              const FaceInfoWidget(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeIndicator() {
    return BlocBuilder<PaintingBloc, PaintingState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: state.isErasing ? Colors.red.shade100 : Colors.blue.shade100,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                state.isErasing ? Icons.auto_delete : Icons.brush,
                color: state.isErasing 
                    ? const Color.fromARGB(255, 206, 134, 172) 
                    : const Color.fromARGB(199, 46, 43, 121),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                state.isErasing ? 'Modo Goma' : 'Modo Pincel',
                style: TextStyle(
                  color: state.isErasing 
                      ? const Color.fromARGB(255, 206, 134, 172) 
                      : const Color.fromARGB(199, 46, 43, 121),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStrokeWidthSlider() {
    return BlocBuilder<PaintingBloc, PaintingState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Grosor: ${state.currentStrokeWidth.toInt()}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            Slider(
              value: state.currentStrokeWidth,
              min: 2,
              max: 20,
              divisions: 18,
              onChanged: (value) {
                context.read<PaintingBloc>().add(ChangeStrokeWidth(value));
              },
            ),
          ],
        );
      },
    );
  }
}

/// 🔄 BLoC Listener: Conecta gestos detectados con acciones de pintura
class GestureToPaintingListener extends StatelessWidget {
  final Widget child;

  const GestureToPaintingListener({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocListener<GestureBloc, gesture_state.GestureState>(
      listener: (context, gestureState) {
        final paintingBloc = context.read<PaintingBloc>();

        // Actualizar mensaje
        paintingBloc.add(UpdateGestureMessage(gestureState.message));

        // Ejecutar acción según el gesto
        switch (gestureState.action) {
          case gesture_state.GestureAction.paint:
            if (gestureState.paintPoints != null) {
              paintingBloc.add(AddPointsToCurrentStroke(gestureState.paintPoints!));
            }
            break;
          case gesture_state.GestureAction.toggleEraser:
            paintingBloc.add(const ToggleEraser());
            break;
          case gesture_state.GestureAction.changeColor:
            if (gestureState.detectedColor != null) {
              paintingBloc.add(ChangeColor(gestureState.detectedColor!));
            }
            break;
          case gesture_state.GestureAction.undo:
            paintingBloc.add(const UndoStroke());
            break;
          case gesture_state.GestureAction.clear:
            paintingBloc.add(const ClearCanvas());
            break;
          default:
            break;
        }
      },
      child: child,
    );
  }
}

/// 🔄 BLoC Listener: Conecta rostros detectados con procesamiento de gestos
class FaceToGestureListener extends StatelessWidget {
  final Widget child;

  const FaceToGestureListener({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocListener<CameraBloc, CameraState>(
      listener: (context, cameraState) {
        final gestureBloc = context.read<GestureBloc>();
        
        if (cameraState.currentFace != null) {
          gestureBloc.add(ProcessFaceGesture(
            face: cameraState.currentFace!,
            screenSize: MediaQuery.of(context).size,
          ));
        } else {
          gestureBloc.add(const NoFaceDetected());
        }
      },
      child: child,
    );
  }
}