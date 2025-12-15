import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import '../bloc/camera/camera_bloc.dart';
import '../bloc/camera/camera_event.dart';
import '../bloc/camera/camera_state.dart';

class CameraPreviewWidget extends StatelessWidget {
  final double height;
  final Color borderColor;

  const CameraPreviewWidget({
    super.key,
    this.height = 120,
    this.borderColor = const Color(0xFF90CAF9),
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CameraBloc, CameraState>(
      builder: (context, state) {
        if (state.status == CameraStatus.error) {
          return _buildError(state.errorMessage ?? 'Error desconocido');
        }

        if (state.status == CameraStatus.initializing) {
          return _buildLoading();
        }

        if (state.status == CameraStatus.ready || state.status == CameraStatus.detecting) {
          return _buildPreview(context, state);
        }

        return _buildLoading();
      },
    );
  }

  Widget _buildPreview(BuildContext context, CameraState state) {
    if (state.controller == null || !state.controller!.value.isInitialized) {
      return _buildLoading();
    }

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            CameraPreview(state.controller!),
            
            // Estado del stream
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: state.isStreamActive ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      state.isStreamActive ? Icons.videocam : Icons.videocam_off,
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      state.isStreamActive ? 'ON' : 'OFF',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Contador de frames
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Frames: ${state.processedFrames}',
                  style: const TextStyle(color: Colors.white, fontSize: 8),
                ),
              ),
            ),
            
            // Botón de inicio si no está activo
            if (!state.isStreamActive)
              Positioned.fill(
                child: Material(
                  color: Colors.black54,
                  child: InkWell(
                    onTap: () {
                      context.read<CameraBloc>().add(const StartDetection());
                    },
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_circle_fill, color: Colors.white, size: 40),
                          SizedBox(height: 8),
                          Text(
                            'TOCA AQUÍ\npara iniciar detección',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            ),
            SizedBox(height: 8),
            Text('Cargando...', style: TextStyle(color: Colors.white, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Container(
      height: height,
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
                message,
                style: const TextStyle(color: Colors.red, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}