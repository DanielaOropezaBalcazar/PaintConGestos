import 'dart:ui' as ui; //capturar imagen
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
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
import '../bloc/theme/theme_bloc.dart';
import '../bloc/theme/theme_event.dart';
import '../bloc/theme/theme_state.dart';
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
  final GlobalKey _canvasGlobalKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Inicializar cámara al entrar
    context.read<CameraBloc>().add(InitializeCamera(widget.cameras));
  }

  Future<void> _saveCanvasImage() async {
    try {
      // Buscar el objeto de renderizado usando la key
      RenderRepaintBoundary? boundary = _canvasGlobalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      
      if (boundary == null) return;

      // Convertir a imagen (pixelRatio 3.0 para alta calidad)
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      
      // Convertir a bytes (PNG)
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();
        
        // Enviar evento al Bloc
        if (mounted) {
          context.read<PaintingBloc>().add(SaveImageToGallery(pngBytes));
        }
      }
    } catch (e) {
      debugPrint("Error capturando canvas: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocListener<PaintingBloc, PaintingState>( // AÑADIR LISTENER PARA MOSTRAR MENSAJES
          listener: (context, state) {
            if (state.saveStatus == SaveStatus.success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ ¡Dibujo guardado en la galería!'), backgroundColor: Colors.green),
              );
            } else if (state.saveStatus == SaveStatus.failure) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('❌ Error al guardar el dibujo'), backgroundColor: Colors.red),
              );
            }
          },
          child: Column(
            children: [
              _buildAppBar(),
              _buildCanvas(),
              _buildControlPanel(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        return Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          color: themeState.themeData.appBarTheme.backgroundColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '🎨 Pinta con Gestos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
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
                          context.read<PaintingBloc>().add(
                            const ToggleEraser(),
                          );
                        },
                        tooltip: state.isErasing ? 'Pincel' : 'Goma',
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.undo,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () {
                          context.read<PaintingBloc>().add(const UndoStroke());
                        },
                        tooltip: 'Deshacer',
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () {
                          context.read<PaintingBloc>().add(const ClearCanvas());
                        },
                        tooltip: 'Limpiar',
                      ),
                      if (state.saveStatus == SaveStatus.loading)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.save_alt, color: Colors.white, size: 20),
                      onPressed: _saveCanvasImage, // Llamar a la función
                      tooltip: 'Guardar Imagen',
                    ),

                      BlocBuilder<ThemeBloc, ThemeState>(
                        builder: (context, themeState) {
                          return IconButton(
                            icon: Icon(
                              themeState is LightTheme
                                  ? Icons.dark_mode
                                  : Icons.light_mode,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: () {
                              context.read<ThemeBloc>().add(ToggleTheme());
                            },
                            tooltip: themeState is LightTheme
                                ? 'Modo Oscuro'
                                : 'Modo Claro',
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCanvas() {
    return Expanded(
      child: Container(
        color: Colors.white,
        child: BlocBuilder<PaintingBloc, PaintingState>(
          builder: (context, state) {
            return RepaintBoundary(
              key: _canvasGlobalKey, // Asignar la key
              child: PaintingCanvas(strokes: state.strokes),
            );
          },
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        return Container(
          height: 280,
          color: themeState is LightTheme
              ? Colors.grey.shade100
              : themeState.themeData.appBarTheme.backgroundColor,
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
      },
    );
  }

  Widget _buildModeIndicator() {
    return BlocBuilder<PaintingBloc, PaintingState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: state.isErasing
                ? const Color.fromARGB(255, 253, 196, 217)
                : Colors.blue.shade100,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                state.isErasing ? Icons.auto_delete : Icons.brush,
                color: state.isErasing
                    ? const Color.fromARGB(255, 165, 53, 113)
                    : const Color.fromARGB(233, 46, 43, 121),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                state.isErasing ? 'Modo Goma' : 'Modo Pincel',
                style: TextStyle(
                  color: state.isErasing
                      ? const Color.fromARGB(255, 165, 53, 113)
                      : const Color.fromARGB(233, 46, 43, 121),
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
              paintingBloc.add(
                AddPointsToCurrentStroke(gestureState.paintPoints!),
              );
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
          gestureBloc.add(
            ProcessFaceGesture(
              face: cameraState.currentFace!,
              screenSize: MediaQuery.of(context).size,
            ),
          );
        } else {
          gestureBloc.add(const NoFaceDetected());
        }
      },
      child: child,
    );
  }
}
