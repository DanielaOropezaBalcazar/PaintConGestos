import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/camera/camera_bloc.dart';
import '../bloc/camera/camera_state.dart';
import '../bloc/painting/painting_bloc.dart';
import '../bloc/painting/painting_state.dart';

class FaceInfoWidget extends StatelessWidget {
  const FaceInfoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CameraBloc, CameraState>(
      builder: (context, cameraState) {
        return BlocBuilder<PaintingBloc, PaintingState>(
          builder: (context, paintingState) {
            final face = cameraState.currentFace;
            
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
                      color: face != null 
                          ? Colors.green.withOpacity(0.2)
                          : Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          face != null ? Icons.check_circle : Icons.schedule,
                          color: face != null ? Colors.green : Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            paintingState.gestureMessage,
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
                  
                  if (face != null) ...[
                    _buildProgressRow(
                      'Sonrisa',
                      face.smilingProbability ?? 0,
                      Colors.green,
                      icon: Icons.sentiment_satisfied,
                    ),
                    const SizedBox(height: 6),
                    _buildProgressRow(
                      'Ojo izq',
                      face.leftEyeOpenProbability ?? 0,
                      Colors.blue,
                      icon: Icons.visibility,
                    ),
                    const SizedBox(height: 6),
                    _buildProgressRow(
                      'Ojo der',
                      face.rightEyeOpenProbability ?? 0,
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
                Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
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
}