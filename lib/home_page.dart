import 'dart:async';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'painting_state.dart';
import 'widgets/painting_canvas.dart';
import 'services/platform_camera_service.dart';
import 'services/gesture_detector_service.dart';

class HomePage extends StatefulWidget {
  final List<CameraDescription> cameras;
  
  const HomePage({super.key, required this.cameras});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late PlatformCameraService _cameraService;
  late GestureDetectorService _gestureDetector;
  Face? _currentFace;
  bool _cameraError = false;
  String _cameraErrorMessage = '';
  bool _isInitializing = true;
  int _faceDetectionCount = 0;

  final List<Color> _colors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
    Colors.pink,
    Colors.teal,
    Colors.black,
  ];

  @override
  void initState() {
    super.initState();
    print('🏠 HomePage iniciado');
    _gestureDetector = GestureDetectorService(colors: _colors);
    _cameraService = PlatformCameraService();
    
    _initializeCameraAsync();
  }

  void _initializeCameraAsync() {
    setState(() {
      _isInitializing = true;
      _cameraError = false;
    });

    print('🚀 Iniciando inicialización de cámara...');
    
    _cameraService.initialize(
      widget.cameras,
      onFaceDetected: _handleFaceDetected,
      onError: _handleCameraError,
    ).then((_) {
      if (mounted) {
        print('✅ Cámara lista en HomePage');
        setState(() {
          _isInitializing = false;
        });
      }
    }).catchError((e) {
      if (mounted) {
        print('❌ Error en HomePage: $e');
        setState(() {
          _isInitializing = false;
          _cameraError = true;
          _cameraErrorMessage = 'Error: ${e.toString()}';
        });
      }
    });
  }

  void _handleFaceDetected(Face? face) {
    if (!mounted) return;
    
    if (face != null) {
      _faceDetectionCount++;
      if (_faceDetectionCount % 30 == 0) {
        print('📊 Detecciones de rostro: $_faceDetectionCount');
      }
    }
    
    setState(() {
      _currentFace = face;
    });

    if (face != null) {
      final smile = face.smilingProbability ?? 0;
      final leftEye = face.leftEyeOpenProbability ?? 0;
      final rightEye = face.rightEyeOpenProbability ?? 0;
      final yaw = face.headEulerAngleY ?? 0;
      final pitch = face.headEulerAngleX ?? 0;
      print('🔎 Rostro detectado - Sonrisa:${(smile*100).toInt()}% Ojos L:${(leftEye*100).toInt()}% R:${(rightEye*100).toInt()}% Yaw:${yaw.toStringAsFixed(1)} Pitch:${pitch.toStringAsFixed(1)}');
    }

    if (face != null) {
      _processFaceGesture(face);
    } else {
      final paintingState = Provider.of<PaintingState>(context, listen: false);
      paintingState.setGesture('Buscando rostro...');
    }
  }

  void _processFaceGesture(Face face) {
    final paintingState = Provider.of<PaintingState>(context, listen: false);
    final screenSize = MediaQuery.of(context).size;
    
    final paintingStateInterface = PaintingStateInterface(
      isErasing: paintingState.isErasing,
      currentColor: paintingState.currentColor,
      currentStrokeWidth: paintingState.currentStrokeWidth,
    );
    
    final gestureResult = _gestureDetector.detectGesture(
      face, 
      paintingStateInterface,
      screenSize,
    );

    paintingState.setGesture(gestureResult.message);

    switch (gestureResult.action) {
      case GestureAction.paint:
        if (gestureResult.points != null && gestureResult.points!.isNotEmpty) {
          paintingState.addStroke(PaintStroke(
            points: gestureResult.points!,
            color: paintingState.isErasing ? Colors.white : paintingState.currentColor,
            strokeWidth: paintingState.currentStrokeWidth,
            isErasing: paintingState.isErasing,
          ));
        }
        break;
        
      case GestureAction.toggleEraser:
        paintingState.toggleEraser();
        Future.delayed(const Duration(milliseconds: 500));
        break;
        
      case GestureAction.changeColor:
        if (gestureResult.color != null) {
          paintingState.setColor(gestureResult.color!);
          _gestureDetector.setColor(gestureResult.color!);
          Future.delayed(const Duration(milliseconds: 500));
        }
        break;
        
      case GestureAction.undo:
        paintingState.undo();
        Future.delayed(const Duration(milliseconds: 500));
        break;
        
      case GestureAction.clear:
        paintingState.clearCanvas();
        Future.delayed(const Duration(milliseconds: 500));
        break;
        
      case GestureAction.waiting:
        _gestureDetector.resetStroke();
        break;
        
      default:
        break;
    }
  }

  void _handleCameraError(String error) {
    print('❌ Error de cámara: $error');
    if (mounted) {
      setState(() {
        _cameraError = true;
        _cameraErrorMessage = error;
      });
    }
  }

  Widget _buildCameraPreview() {
    if (_cameraError) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red),
                const SizedBox(height: 4),
                Text(
                  _cameraErrorMessage,
                  style: const TextStyle(color: Colors.red, fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _cameraService,
      builder: (context, child) {
        return _cameraService.buildCameraPreview();
      },
    );
  }

  Widget _buildFaceInfo() {
    return Consumer<PaintingState>(
      builder: (context, paintingState, child) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade700),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _currentFace != null 
                      ? Colors.green.withOpacity(0.2)
                      : Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _currentFace != null ? Icons.check_circle : Icons.schedule,
                      color: _currentFace != null ? Colors.green : Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        paintingState.currentGesture,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              if (_currentFace != null) ...[
                _buildProgressRow(
                  'Sonrisa',
                  _currentFace!.smilingProbability ?? 0,
                  Colors.green,
                  icon: Icons.sentiment_satisfied,
                ),
                const SizedBox(height: 6),
                _buildProgressRow(
                  'Ojo izq',
                  _currentFace!.leftEyeOpenProbability ?? 0,
                  Colors.blue,
                  icon: Icons.visibility,
                ),
                const SizedBox(height: 6),
                _buildProgressRow(
                  'Ojo der',
                  _currentFace!.rightEyeOpenProbability ?? 0,
                  Colors.blue,
                  icon: Icons.visibility,
                ),
              ] else ...[
                const Center(
                  child: Column(
                    children: [
                      Icon(Icons.face, color: Colors.grey, size: 32),
                      SizedBox(height: 8),
                      Text(
                        'Mira a la cámara',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Sonríe para pintar',
                        style: TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressRow(String label, double value, Color color, {IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 12, color: Colors.white70),
                  const SizedBox(width: 4),
                ],
                Text(
                  label, 
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
            Text(
              '${(value * 100).toInt()}%',
              style: TextStyle(
                color: value > 0.7 ? Colors.green : Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorPalette() {
    return Consumer<PaintingState>(
      builder: (context, paintingState, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Colores:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _colors.length,
                itemBuilder: (context, index) {
                  final color = _colors[index];
                  final isSelected = paintingState.currentColor == color;
                  
                  return GestureDetector(
                    onTap: () {
                      paintingState.setColor(color);
                      _gestureDetector.setColor(color);
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.black : Colors.grey.shade300,
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    print('🔴 HomePage dispose');
    _cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: const Color.fromARGB(199, 46, 43,121),
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
                  Consumer<PaintingState>(
                    builder: (context, paintingState, child) {
                      return Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              paintingState.isErasing ? Icons.brush : Icons.auto_delete,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: paintingState.toggleEraser,
                            tooltip: paintingState.isErasing ? 'Pincel' : 'Goma',
                          ),
                          IconButton(
                            icon: const Icon(Icons.undo, color: Colors.white, size: 20),
                            onPressed: paintingState.undo,
                            tooltip: 'Deshacer',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.white, size: 20),
                            onPressed: paintingState.clearCanvas,
                            tooltip: 'Limpiar',
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: Container(
                color: Colors.white,
                child: Consumer<PaintingState>(
                  builder: (context, paintingState, child) {
                    return PaintingCanvas(strokes: paintingState.strokes);
                  },
                ),
              ),
            ),
            
            Container(
              height: 280,
              color: Colors.grey.shade100,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Consumer<PaintingState>(
                        builder: (context, paintingState, child) {
                          return Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: paintingState.isErasing 
                                  ? Colors.red.shade100 
                                  : Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  paintingState.isErasing ? Icons.auto_delete : Icons.brush,
                                  color: paintingState.isErasing ? const Color.fromARGB(255, 206, 134, 172) : const Color.fromARGB(199, 46, 43, 121),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  paintingState.isErasing ? 'Modo Goma' : 'Modo Pincel',
                                  style: TextStyle(
                                    color: paintingState.isErasing ? const Color.fromARGB(255, 206, 134, 172) : const Color.fromARGB(199, 46, 43, 121),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 10),
                      
                      Consumer<PaintingState>(
                        builder: (context, paintingState, child) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Grosor: ${paintingState.currentStrokeWidth.toInt()}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              Slider(
                                value: paintingState.currentStrokeWidth,
                                min: 2,
                                max: 20,
                                divisions: 18,
                                onChanged: paintingState.setStrokeWidth,
                              ),
                            ],
                          );
                        },
                      ),
                      
                      const SizedBox(height: 8),
                      
                      _buildColorPalette(),
                      
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 10),
                      
                      _buildCameraPreview(),
                      const SizedBox(height: 10),
                      _buildFaceInfo(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
